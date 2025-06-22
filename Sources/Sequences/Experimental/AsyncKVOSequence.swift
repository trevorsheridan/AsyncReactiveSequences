//
//  AsyncKVOSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/17/24.
//

import Foundation

public final class AsyncKVOSequence<Object, Element>: AsyncSequence, Sendable where Object: NSObject, Element: Sendable {
    public enum Dispatching: Sendable {
        case change
        case object
    }
    
    private nonisolated(unsafe) var observer: NSKeyValueObservation?
    private let sequence: AsyncCurrentValueSequence<Element>
    
    /// Creates an `AsyncKVOSequence` that emits values in response to Key-Value Observing (KVO) changes.
    ///
    /// This sequence observes the specified `keyPath` on the given `object`, and emits values when changes are detected.
    /// The source of the emitted value is determined by the `dispatching` mode:
    /// - If `.change`, the value is taken directly from the KVO change dictionary.
    /// - If `.object`, the value is re-read from the object using the key path at the time of the change.
    ///
    /// - Parameters:
    ///   - object: The KVO-compliant object to observe.
    ///   - keyPath: The key path of the property on `object` to observe for changes.
    ///   - dispatching: Determines how the new value is retrieved when a change occurs. Defaults to `.change`.
    ///                  See discussion for details.
    public init(object: Object, keyPath: KeyPath<Object, Element>, dispatching: Dispatching = .change) {
        sequence = .init(object[keyPath: keyPath])
        
        observer = object.observe(keyPath, options: [.initial, .new]) { [sequence] object, change in
            switch dispatching {
            case .change:
                guard let element = change.newValue else {
                    return
                }
                sequence.send(element)
            case .object:
                let element = object[keyPath: keyPath]
                sequence.send(element)
            }
        }
    }
    
    deinit {
        observer?.invalidate()
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let sequence: AsyncKVOSequence
        let iterator: AsyncCurrentValueSequence<Element>.Iterator
        
        init(sequence: AsyncKVOSequence) {
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
