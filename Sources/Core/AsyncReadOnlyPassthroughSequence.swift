//
//  AsyncReadOnlyPassthroughSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/14/24.
//

public struct AsyncReadOnlyPassthroughSequence<Element>: Sendable, AsyncSequence where Element: Sendable {
    let passthroughSequence: AsyncPassthroughSequence<Element>
    
    public init(from sequence: AsyncPassthroughSequence<Element>) {
        passthroughSequence = sequence
    }
    
    public func makeAsyncIterator() -> AsyncPassthroughSequence<Element>.Iterator {
        passthroughSequence.makeAsyncIterator()
    }
}

extension AsyncPassthroughSequence {
    public func readonly() -> AsyncReadOnlyPassthroughSequence<Element> {
        .init(from: self)
    }
}
