//
//  AnyAsyncSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

public struct AnyAsyncSequence<Element>: AsyncSequence, Sendable {
    private var closure: @Sendable () -> AnyAsyncIterator<Element>
    
    public init<Sequence: AsyncSequence>(_ base: Sequence) where Sequence.Element == Element, Sequence: Sendable {
        closure = {
            AnyAsyncIterator<Element>(base.makeAsyncIterator())
        }
    }
    
    public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        closure()
    }
}

extension AsyncSequence {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> where Self: Sendable {
        AnyAsyncSequence(self)
    }
}
