//
//  AsyncLiftSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/25/25.
//

public final class AsyncLiftSequence<Element>: AsyncSequence, Sendable where Element: Sendable {
    private let task: Task<Element, Error>
    
    public init(element: sending @escaping () async throws -> Element) {
        task = Task {
            try await element()
        }
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let task: Task<Element, Error>
        var hasReturnedNext: Bool = false
        
        init(task: Task<Element, Error>) {
            self.task = task
        }
        
        public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Element? {
            guard !hasReturnedNext else {
                return nil
            }
            
            defer { hasReturnedNext = true }
            
            return try await task.value
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(task: task)
    }
}
