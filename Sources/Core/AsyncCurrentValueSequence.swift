//
//  AsyncCurrentValueSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

import Foundation
import Synchronization
import OrderedCollections

public final class AsyncCurrentValueSequence<Element: Sendable>: AsyncSequence, Sendable {
    typealias Subscriber = (continuation: CheckedContinuation<Element?, Never>?, lastElementIndex: Int?)
    typealias ElementBuffer = OrderedDictionary<Int, Element>
    
    private struct State: Sendable {
        var head: (element: Element, index: Int)
        var buffer: ElementBuffer = [:]
        var subscribers: [UUID: Subscriber] = [:]
    }
    
    public var value: Element {
        state.withLock { $0.head.element }
    }
    
    private let state: Mutex<State>
    private let skipInitialElement: Bool
    private let skipEmptyElements: Bool
    private let debug: Bool
    
    public convenience init(_ element: Element, debug: Bool = false) {
        self.init(element, skipInitialElement: false, skipEmptyElements: false, debug: debug)
    }
    
    internal init(_ element: Element, skipInitialElement: Bool = false, skipEmptyElements: Bool = false, debug: Bool = false) {
        self.state = Mutex(.init(head: (element: element, index: 0), buffer: [0: element]))
        self.skipInitialElement = skipInitialElement
        self.skipEmptyElements = skipEmptyElements
        self.debug = debug
    }
    
    public func send(isolation: isolated (any Actor)? = #isolation) where Element == Void {
        send(())
    }
    
    public func send(isolation: isolated (any Actor)? = #isolation, _ element: Element) {
        state.withLock { [weak self] state in
            guard let self else {
                return
            }
            
            // Set the head element and cache it for delivery to iterators.
            state.head = (element, state.head.index + 1)
            state.buffer[state.head.index] = state.head.element
            
            // Perform an iteration pass to any iterators awaiting a new value.
            state.subscribers = state.subscribers.reduce(into: [:]) { subscribers, subscriber in
                // Peel the next item off for the iterator to consume.
                subscribers[subscriber.key] = resume(from: state.buffer, sendingTo: subscriber.value, loc: "send")
            }
            
            cleanse(state: &state)
        }
    }
    
    private func next(isolation actor: isolated (any Actor)? = #isolation, iteratorIdentifier: UUID) async -> Element? {
        guard !Task.isCancelled else {
            cancel(iteratorIdentifier: iteratorIdentifier)
            return nil
        }
        
        state.withLock { state in
            // Register the subscriber before there's a continuation available. This allows this subscriber to opt into buffered elements in a synchronous, as quick as possible, way without risking a send coming in before the continuation is available to register down below.
            state.subscribers[iteratorIdentifier] = state.subscribers[iteratorIdentifier] ?? (nil, nil)
        }
        
        return await withTaskCancellationHandler {
            await withCheckedContinuation { [weak self] continuation in
                guard let self else {
                    return
                }
                
                state.withLock { state in
                    // Craft a new subscriber with the newly received continuation and the previous subscriber's lastElementIndex.
                    let subscriber: Subscriber = (continuation, state.subscribers[iteratorIdentifier]?.lastElementIndex)
                    state.subscribers[iteratorIdentifier] = resume(from: state.buffer, sendingTo: subscriber, loc: "next")
                    cleanse(state: &state)
                }
            }
        } onCancel: { [weak self] in
            self?.cancel(iteratorIdentifier: iteratorIdentifier)
        }
    }
    
    private func cancel(iteratorIdentifier: UUID) {
        state.withLock { state in
            if let continuation = state.subscribers[iteratorIdentifier]?.continuation {
                continuation.resume(returning: nil)
            }
            state.subscribers[iteratorIdentifier] = nil
        }
    }
    
    private func resume(from buffer: ElementBuffer, sendingTo subscriber: Subscriber, loc: String) -> Subscriber {
        let (continuation, lastSeenElementIndex) = subscriber
        
        guard let continuation else {
            // Ensure we have a continuation to work with, otherwise simply send back the subscriber until it is capable of receiving values.
            return subscriber
        }
        
        // The index of the element to consider resuming with.
        let index = if let lastSeenElementIndex { lastSeenElementIndex + 1 } else { buffer.keys.first }
        
        // Enure the index is actually valid and there is an element at that index, otherwise return the subscriber until there is.
        guard let index = index, let element = buffer[index] else {
            return subscriber
        }
        
        // If this subscriber has never seen an index before, and we are to skip the initial element. Simply return the continuation for the next
        // iteration and set the `lastSeenElementIndex` on the subscriber to the current element's index. This will ensure that this subscriber
        // never receives this element.
        if lastSeenElementIndex == nil && skipInitialElement {
            return (continuation, index)
        }
        
        if skipEmptyElements && isNil(element) {
            // This element is nil, to skip it simply call resume() recursively with the index for this element.
            return resume(from: buffer, sendingTo: (continuation, index), loc: loc)
        }
        
        // All conditions have been satisfied in order to send the element to the continuation.
        continuation.resume(returning: element)
        
        // Finally, return a new subscriber with a nil continuation (because a continuation may only receive a value once) and the current element's
        // set as the `lastSeenElementIndex` on the subscriber.
        return (nil, index)
    }
    
    private func cleanse(state: inout State) {
        state.buffer = state.buffer.reduce(into: [:]) { [weak self]  buffers, buffer in
            guard let self else {
                return
            }
            
            let (index, element) = buffer
            let hasWaitingIterator = hasWaitingSubscriber(subscribers: state.subscribers, index: index)
            
            guard hasWaitingIterator || state.head.index == index else {
                // Returning early doesn't add the element to the new buffer, thus removing it from the state buffer.
                return
            }
            
            buffers[index] = element
        }
    }
    
    private func hasWaitingSubscriber(subscribers: [UUID: Subscriber], index: Int) -> Bool {
        var fulfilledSubscribers = 0
        
        for (_, subscriber) in subscribers {
            if let lastElementIndex = subscriber.lastElementIndex, lastElementIndex >= index {
                fulfilledSubscribers += 1
            }
        }
        
        return fulfilledSubscribers != subscribers.count
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let identifier = UUID()
        let sequence: AsyncCurrentValueSequence
        
        init(sequence: AsyncCurrentValueSequence) {
            self.sequence = sequence
        }
        
        public func next() async -> Element? {
            await sequence.next(iteratorIdentifier: identifier)
        }
        
        public func next(isolation actor: isolated (any Actor)? = #isolation) async -> Element? {
            await sequence.next(iteratorIdentifier: identifier)
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: self)
    }
}
