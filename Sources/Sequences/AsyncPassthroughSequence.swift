//
//  AsyncPassthroughSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/13/24.
//

import Foundation
import Synchronization

public final class AsyncPassthroughSequence<Element: Sendable>: AsyncSequence, Sendable {
    private let currentValueSequence = AsyncCurrentValueSequence<Element?>(nil, skipInitialElement: true)
    
    public init() {}
    
    public func send(isolation: isolated (any Actor)? = #isolation) where Element == Void {
        send(())
    }
    
    public func send(isolation: isolated (any Actor)? = #isolation, _ element: Element) {
        currentValueSequence.send(element)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let identifier = UUID()
        let iterator: AsyncCurrentValueSequence<Element?>.AsyncIterator
        
        init(iterator: AsyncCurrentValueSequence<Element?>.AsyncIterator) {
            self.iterator = iterator
        }
        
        public func next() async -> Element? {
            await iterator.next() ?? nil
        }
        
        public func next(isolation actor: isolated (any Actor)? = #isolation) async -> Element? {
            await iterator.next(isolation: actor) ?? nil
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: currentValueSequence.makeAsyncIterator())
    }
}
