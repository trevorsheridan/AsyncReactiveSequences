//
//  AnyAsyncSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

import Synchronization

public final class AnyAsyncSequence<Element: Sendable>: AsyncSequence, AsyncIteratorProtocol, Sendable {
    private let iterator: @Sendable (_ isolation: (any Actor)?) async throws -> Element?
    
    public init<Sequence: AsyncSequence>(_ base: Sequence) where Sequence.Element == Element, Sequence: Sendable {
        iterator = { @Sendable actor in
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
    
    public nonisolated func makeAsyncIterator() -> AnyAsyncSequence<Element> {
        self
    }
}

extension AsyncSequence {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> where Self: Sendable {
        AnyAsyncSequence(self)
    }
}
