//
//  AnyAsyncIterator.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

public struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
    private var closure: () async throws -> Element?
    
    public init<Iterator: AsyncIteratorProtocol>(_ iterator: Iterator) where Iterator.Element == Element {
        closure = {
            var iterator = iterator
            return try await iterator.next()
        }
    }
    
    public func next() async throws -> Element? {
        try await closure()
    }
}
