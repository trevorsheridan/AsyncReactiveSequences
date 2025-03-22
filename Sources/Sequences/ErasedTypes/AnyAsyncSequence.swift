//
//  AnyAsyncSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

public final class AnyAsyncSequence<Element>: AsyncSequence, Sendable where Element: Sendable {
    private let sequence: any AsyncSequence & Sendable
    
    public init<Sequence: AsyncSequence>(_ base: Sequence) where Sequence.Element == Element, Sequence: Sendable {
        sequence = base
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: any AsyncIteratorProtocol
        
        init(sequence: AnyAsyncSequence) {
            self.iterator = sequence.sequence.makeAsyncIterator()
        }
        
        public mutating func next() async throws -> Element? {
            try await iterator.next() as! Element?
        }
        
        public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Element? {
            try await iterator.next(isolation: actor) as! Element?
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: self)
    }
}

extension AsyncSequence {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> where Self: Sendable {
        AnyAsyncSequence(self)
    }
}
