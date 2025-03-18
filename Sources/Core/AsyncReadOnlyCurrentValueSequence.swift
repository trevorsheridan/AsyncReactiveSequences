//
//  AsyncReadOnlyCurrentValueSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/26/24.
//

public struct AsyncReadOnlyCurrentValueSequence<Element>: Sendable, AsyncSequence where Element: Sendable {
    let currentValueSequence: AsyncCurrentValueSequence<Element>
    
    public var value: Element {
        currentValueSequence.value
    }
    
    public init(_ element: Element) {
        currentValueSequence = AsyncCurrentValueSequence(element)
    }
    
    public init(from sequence: AsyncCurrentValueSequence<Element>) {
        currentValueSequence = sequence
    }
    
    public func makeAsyncIterator() -> AsyncCurrentValueSequence<Element>.Iterator {
        currentValueSequence.makeAsyncIterator()
    }
}

extension AsyncCurrentValueSequence {
    public func readonly() -> AsyncReadOnlyCurrentValueSequence<Element> {
        .init(from: self)
    }
}
