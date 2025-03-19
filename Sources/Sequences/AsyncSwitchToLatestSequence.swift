//
//  AsyncSwitchToLatestSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/21/24.
//

public final class AsyncSwitchToLatestSequence<Upstream>: AsyncSequence & Sendable
where Upstream: AsyncSequence & Sendable, Upstream.Element: AsyncSequence & Sendable, Upstream.Element.Element: Sendable {
    public typealias Element = Upstream.Element.Element
    
    // @Matt: Is this okay to do since TaskCancellable is not Sendable
    // and I'm only accessing it from the isolated actor passed into the init?
    private nonisolated(unsafe) var cancellable: TaskCancellable?
    private nonisolated(unsafe) var outer: TaskCancellable!
    
    private let downstream = AsyncPassthroughSequence<Element>()
    
    public init(isolation actor: isolated (any Actor)? = #isolation, upstream: Upstream) {
        outer = upstream.sink { [weak self] value in
            // Important: Do not capture self in here!
            self?.cancellable = value.sink { [weak self] value in
                self?.downstream.send(value)
            }
        }
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let iterator: AsyncPassthroughSequence<Element>.AsyncIterator
        
        init(iterator: AsyncPassthroughSequence<Element>.AsyncIterator) {
            self.iterator = iterator
        }
        
        public func next() async throws -> Element? {
            await iterator.next()
        }
        
        public func next(isolation actor: isolated (any Actor)?) async throws(Failure) -> Element? {
            await iterator.next(isolation: actor)
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: downstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Self: Sendable, Element: AsyncSequence & Sendable, Element.Element: Sendable {
    public func switchToLatest(isolation actor: isolated (any Actor)? = #isolation) -> AsyncSwitchToLatestSequence<Self> {
        .init(upstream: self)
    }
}
