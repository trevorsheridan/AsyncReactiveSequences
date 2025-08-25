//
//  AsyncLiftSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/25/25.
//

public final class AsyncLiftSequence<Element>: AsyncSequence, Sendable where Element: Sendable {
    private let sequence = AsyncCurrentValueSequence<Element?>(nil)
    
    public init(element: sending @escaping () async throws -> Element) {
        Task {
            sequence.send(try await element())
        }
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let iterator: AsyncCurrentValueSequence<Element?>.AsyncIterator
        var hasReturnedNext: Bool = false
        
        init(sequence: AsyncCurrentValueSequence<Element?>.AsyncIterator) {
            self.iterator = sequence.sequence.makeAsyncIterator()
        }
        
        public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async -> Element? {
            guard !hasReturnedNext, let next = await iterator.next(isolation: actor) else {
                return nil
            }
            defer { hasReturnedNext = true }
            return next
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: sequence.makeAsyncIterator())
    }
}
