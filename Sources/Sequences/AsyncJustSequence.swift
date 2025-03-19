//
//  AsyncJustSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/25/24.
//

public final class AsyncJustSequence<Element>: AsyncSequence, Sendable where Element: Sendable {
    let sequence: AsyncCurrentValueSequence<Element>
    
    public init(element: Element) {
        sequence = .init(element)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let sequence: AsyncJustSequence
        let iterator: AsyncCurrentValueSequence<Element>.Iterator
        
        init(sequence: AsyncJustSequence) {
            self.sequence = sequence
            self.iterator = sequence.sequence.makeAsyncIterator()
        }
        
        public func next() async -> Element? {
            await iterator.next()
        }
        
        public func next(isolation actor: isolated (any Actor)? = #isolation) async -> Element? {
            await iterator.next(isolation: actor)
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: self)
    }
}
