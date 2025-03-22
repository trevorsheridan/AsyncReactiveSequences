//
//  AnyAsyncSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

import Synchronization
import os

public final class AnyAsyncSequence2<Element: Sendable>: AsyncSequence, AsyncIteratorProtocol, Sendable {
    private let iterator: @Sendable (_ isolation: (any Actor)?) async throws -> Element?
//    private let sequence: Mutex<any AsyncSequence>
    
    public init<Sequence: AsyncSequence>(_ base: Sequence) where Sequence.Element == Element, Sequence: Sendable {
        self.iterator = { actor in
            var iterator = base.makeAsyncIterator()
            return try await iterator.next(isolation: actor)
        }
    }
    
    public func next() async throws -> Element? {
        try await iterator(#isolation)
    }
    
    public func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
        try await iterator(actor)
    }
    
    public func makeAsyncIterator() -> AnyAsyncSequence2<Element> {
        self
    }
}

public final class AnyAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
    private let sequence: Mutex<any AsyncSequence>
    
    public init<Sequence: AsyncSequence>(_ base: Sequence) where Sequence.Element == Element, Sequence: Sendable {
        self.sequence = .init(base)
    }
    
    public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        sequence.withLock { sequence in
            AnyAsyncIterator(iterator: sequence.makeAsyncIterator())
        }
    }
}

public final class AnyAsyncIterator<Element: Sendable>: AsyncIteratorProtocol, @unchecked Sendable {
    private var iterator: any AsyncIteratorProtocol
//    let lock = OSAllocatedUnfairLock()
    
    init(iterator: any AsyncIteratorProtocol) {
        self.iterator = iterator
    }
    
    public func next() async throws -> Element? {
//        var iterator: any AsyncIteratorProtocol
        try await iterator.next() as! Element?
    }
    
    public func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
        try await iterator.next(isolation: actor) as! Element?
    }
}

extension AsyncSequence {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> where Self: Sendable {
        AnyAsyncSequence(self)
    }
}
