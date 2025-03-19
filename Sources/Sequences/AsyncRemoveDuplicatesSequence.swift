//
//  AsyncRemoveDuplicatesSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 10/28/24.
//

import Synchronization
import Semaphore

public final class AsyncRemoveDuplicatesSequence<Element, Failure, S>: AsyncSequence, Sendable
where Element: Sendable, Failure: Error, S: AsyncSequence<Element, Failure> & Sendable {
    private let base: S
    private let predicate: @Sendable (_ a: Element, _ b: Element) async -> Bool
    
    public init(base: S) where Element: Equatable {
        self.base = base
        self.predicate = { @Sendable (a, b) -> Bool in
            a == b
        }
    }
    
    public init(base: S, predicate: @escaping @Sendable (_ a: Element, _ b: Element) async -> Bool) {
        self.base = base
        self.predicate = predicate
    }
    
    public final class Iterator: AsyncIteratorProtocol {
        private var iterator: S.AsyncIterator
        private let state: Mutex<Element?>
        private let semaphore = AsyncSemaphore(value: 1)
        private let predicate: @Sendable (_ a: Element, _ b: Element) async -> Bool
        
        init(iterator: S.AsyncIterator, predicate: @escaping @Sendable (_ a: Element, _ b: Element) async -> Bool) {
            self.iterator = iterator
            self.predicate = predicate
            self.state = .init(nil)
        }
        
        public func next() async throws -> Element? {
            try await next(iterator: &iterator)
        }
        
        public func next(isolation actor: isolated (any Actor)?) async throws -> Element? {
            try await next(iterator: &iterator)
        }
        
        private func next(isolation actor: isolated (any Actor)? = #isolation, iterator: inout S.AsyncIterator) async throws -> Element? {
            try await withTaskCancellationHandler { [weak self] in
                guard let self else {
                    return nil
                }
                
                await semaphore.wait()
                defer { semaphore.signal() }
                
                let next = try await nextUniqueElement(iterator: &iterator)
                
                state.withLock { element in
                    element = next
                }
                
                return next
            } onCancel: {
                // noop
            }
        }
        
        private func nextUniqueElement(iterator: inout S.AsyncIterator) async throws -> Element? {
            while true {
                guard !Task.isCancelled else {
                    return nil
                }
                
                let next = try await iterator.next()
                let storedElement = state.withLock { element in element }
                
                guard let next, let storedElement else {
                    // Either next and/or storeElement don't exist so return next, even if it's nil.
                    return next
                }
                
                guard await !predicate(next, storedElement) else {
                    continue
                }
                
                return next
            }
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        .init(iterator: base.makeAsyncIterator(), predicate: predicate)
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable & Equatable {
    public func removeDuplicates() -> AsyncRemoveDuplicatesSequence<Element, Failure, Self> {
        .init(base: self)
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
    public func removeDuplicates(by predicate: @escaping @Sendable (_ a: Element, _ b: Element) async -> Bool) -> AsyncRemoveDuplicatesSequence<Element, Failure, Self> {
        .init(base: self, predicate: predicate)
    }
}
