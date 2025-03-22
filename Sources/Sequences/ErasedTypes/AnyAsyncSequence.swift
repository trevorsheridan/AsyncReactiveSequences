//
//  AnyAsyncSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

import Synchronization
import os

public final class AnyAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
//    private let iterator: @Sendable (_ isolation: (any Actor)?) async throws -> Element?
    private let sequence: Mutex<any AsyncSequence>
    
    public init<Sequence: AsyncSequence>(_ base: Sequence) where Sequence.Element == Element, Sequence: Sendable {
//        iterator = { @Sendable actor in
//            var iterator = base.makeAsyncIterator()
//            return try await iterator.next(isolation: actor)
//        }
        self.sequence = .init(base)
    }
    
//    public func next() async throws -> Element? {
//        try await iterator(#isolation)
//    }
//    
//    public func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
//        try await iterator(actor)
//    }
    
    public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        sequence.withLock { sequence in
            AnyAsyncIterator(iterator: sequence.makeAsyncIterator())
        }
    }
}

//public actor IteratorProtector<Element: Sendable> {
//    var iterator: any AsyncIteratorProtocol
//    
//    init(iterator: any AsyncIteratorProtocol) {
//        self.iterator = iterator
//    }
//    
//    public func withIterator() -> any AsyncIteratorProtocol {
//
//    }
//    
//    public func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
//        var iterator = await iterator
//        try await iterator.next(isolation: actor) as! Element?
//    }
//}

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
