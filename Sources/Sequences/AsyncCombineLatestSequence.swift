//
//  AsyncCombineLatestSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/17/24.
//

import Synchronization

public final class AsyncCombineLatestSequence<each Upstream>: AsyncSequence, Sendable
where repeat each Upstream: AsyncSequence & Sendable, repeat (each Upstream).Element: Sendable {
    public typealias Element = (repeat (each Upstream).Element)
    
    private let container: (repeat Container<each Upstream>)
    private let downstream = AsyncCurrentValueSequence<Element?>(nil, skipInitialElement: false, skipEmptyElements: true)
    private nonisolated(unsafe) var cancellables = Set<TaskCancellable>()
    
    public init(isolation actor: isolated (any Actor)? = #isolation, _ upstream: repeat each Upstream) {
        self.container = Self.containers(repeat each upstream)
        observe(upstream: repeat each upstream)
    }
    
    private func observe(upstream: repeat each Upstream) {
        var index = 0
        for sequence in repeat each upstream {
            obvserve(sequence: sequence, at: index).store(in: &cancellables)
            index += 1
        }
    }
    
    private func obvserve<Sequence>(sequence: Sequence, at index: Int) -> TaskCancellable where Sequence: AsyncSequence & Sendable, Sequence.Element: Sendable {
        sequence.sink { [weak self] value in
            self?.perform(with: value, index: index)
        }
    }
    
    private func perform<V>(isolation actor: isolated (any Actor)? = #isolation, with value: V, index: Int) {
        let value = (repeat (each container).replace(index: index, value: value))
        
        for value in repeat each value {
            if let value = value as? OptionalValue, value.isNil {
                return
            }
        }
        
        downstream.send(value as? Element)
    }
    
    private static func containers(_ sequence: repeat each Upstream) -> (repeat Container<each Upstream>) {
        var index = 0
        return (repeat Container(sequence: each sequence, index: &index))
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let iterator: AsyncCurrentValueSequence<Element?>.AsyncIterator
        
        init(iterator: AsyncCurrentValueSequence<Element?>.AsyncIterator) {
            self.iterator = iterator
        }
        
        public func next() async throws -> Element? {
            await iterator.next() ?? nil
        }
        
        public func next(isolation actor: isolated (any Actor)?) async throws(Failure) -> Element? {
            await iterator.next(isolation: actor) ?? nil
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: downstream.makeAsyncIterator())
    }
}

extension AsyncCombineLatestSequence {
    private final class Container<Sequence>: Sendable where Sequence: AsyncSequence & Sendable, Sequence.Element: Sendable {
        let index: Int
        let value: Mutex<Sequence.Element?> = .init(nil)
        
        init(sequence: Sequence, index: inout Int) {
            self.index = index
            index += 1
        }
        
        func replace(index: Int, value nextValue: Any) -> Sequence.Element? {
            value.withLock { value in
                guard index == self.index, let nextValue = nextValue as? Sequence.Element else {
                    return value
                }
                
                value = nextValue
                
                return value
            }
        }
    }
}

extension AsyncSequence {
    public func combineLatest<Upstream>(isolation actor: isolated (any Actor)? = #isolation, _ upstream: Upstream) -> AsyncCombineLatestSequence<Self, Upstream>
    where Self: AsyncSequence & Sendable, Element: Sendable, Upstream: AsyncSequence & Sendable, Upstream.Element: Sendable {
        AsyncCombineLatestSequence(self, upstream)
    }
    
    public func combineLatest<Upstream, each Other>(isolation actor: isolated (any Actor)? = #isolation, _ upstream: Upstream, _ other: repeat each Other) -> AsyncCombineLatestSequence<Self, Upstream, repeat each Other>
    where Self: AsyncSequence & Sendable, Element: Sendable, Upstream: AsyncSequence & Sendable, Upstream.Element: Sendable, repeat each Other: AsyncSequence & Sendable, repeat (each Other).Element: Sendable {
        AsyncCombineLatestSequence(self, upstream, repeat each other)
    }
}
