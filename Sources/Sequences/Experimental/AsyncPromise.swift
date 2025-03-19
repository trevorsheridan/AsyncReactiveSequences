//
//  AsyncFuture.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/5/24.
//

import Foundation
import Synchronization

public final class AsyncPromiseSequence<Element: Sendable>: AsyncSequence, Sendable {
    public enum Error: Swift.Error {
        case promiseAlreadyFulfilled
    }
    
    private struct State: Sendable {
        var result: Result<Element, Swift.Error>?
        var iterators: [UUID: UnsafeContinuation<Element?, any Swift.Error>] = [:]
    }
    
    public var value: Element? {
        state.withLock { state in
            switch state.result {
            case .success(let element):
                return element
            default:
                return nil
            }
        }
    }
    
    private let state: Mutex<State>
    
    public init() {
        state = Mutex(.init())
    }
    
    public func fulfill(_ result: Result<Element, Swift.Error>) throws {
        try state.withLock { state in
            guard state.result == nil else {
                throw Error.promiseAlreadyFulfilled
            }
            
            state.result = result
            
            state.iterators = state.iterators.reduce(into: [:]) { iterators, iterator in
                let (_, continuation) = iterator
                
                switch result {
                case .success(let element):
                    continuation.resume(returning: element)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func next(iterator: UUID) async throws -> Element? {
        try await withTaskCancellationHandler {
            try await withUnsafeThrowingContinuation { continuation in
                state.withLock { state in
                    guard let _ = state.result else {
                        state.iterators[iterator] = continuation
                        return
                    }
                    continuation.resume(returning: nil)
                }
            }
        } onCancel: {
            state.withLock { state in
                if let continuation = state.iterators[iterator] {
                    continuation.resume(returning: nil)
                }
                state.iterators[iterator] = nil
            }
        }
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let identifier = UUID()
        let sequence: AsyncPromiseSequence<Element>
        
        public func next() async throws -> Element? {
            try await sequence.next(iterator: identifier)
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(sequence: self)
    }
}
