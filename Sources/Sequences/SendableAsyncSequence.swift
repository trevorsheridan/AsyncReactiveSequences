//
//  SendableAsyncSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/24/24.
//

import os

extension AsyncSequence {
    public func transform<E: Sendable>(transform: nonisolated(nonsending) @Sendable @escaping (_ notification: Element?) async -> E?) -> SendableAsyncSequence<E, Self> {
        SendableAsyncSequence(base: self, transform: transform)
    }
}

public final class SendableAsyncSequence<Element, Base>: AsyncSequence, Sendable where Element: Sendable, Base: AsyncSequence, Base.Element: Sendable {
    private nonisolated(unsafe) let base: Base
    private let lock = OSAllocatedUnfairLock()
    private let transform: @Sendable (Base.Element?) async -> Element?
    
    public init(base: Base, transform: nonisolated(nonsending) @Sendable @escaping (Base.Element?) async -> Element?) {
        self.base = base
        self.transform = transform
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let transform: (Base.Element?) async -> Element?
        
        init(iterator: Base.AsyncIterator, transform: nonisolated(nonsending) @escaping (Base.Element?) async -> Element?) {
            self.iterator = iterator
            self.transform = transform
        }
        
        public mutating func next() async -> Element? {
            guard let element = try? await iterator.next() else {
                return nil
            }
            return await transform(element)
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        var iterator: Base.AsyncIterator
        lock.lock()
        iterator = base.makeAsyncIterator()
        lock.unlock()
        return Iterator(iterator: iterator, transform: transform)
    }
}
