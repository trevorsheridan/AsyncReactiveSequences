//
//  AsyncKVOSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/17/24.
//

import Foundation

public final class AsyncKVOSequence<Object, Element>: AsyncSequence, Sendable where Object: NSObject, Element: Sendable {
    private nonisolated(unsafe) var observer: NSKeyValueObservation?
    private let sequence: AsyncCurrentValueSequence<Element>
    
    public init(object: Object, keyPath: KeyPath<Object, Element>) {
        sequence = .init(object[keyPath: keyPath])
        
        observer = object.observe(keyPath, options: [.initial, .new]) { [weak self] object, change in
            guard let self, let element = change.newValue else {
                return
            }
            sequence.send(element)
        }
    }
    
    deinit {
        observer?.invalidate()
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let sequence: AsyncKVOSequence
        let iterator: AsyncCurrentValueSequence<Element>.Iterator
        
        init(sequence: AsyncKVOSequence) {
            self.sequence = sequence
            self.iterator = sequence.sequence.makeAsyncIterator()
        }
        
        public func next() async -> Element? {
            await iterator.next()
        }
        
        public func next(isolation actor: isolated (any Actor)? = #isolation) async -> Element? {
            await iterator.next(isolation: actor)
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: self)
    }
}
