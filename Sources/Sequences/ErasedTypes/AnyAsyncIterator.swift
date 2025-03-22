//
//  AnyAsyncIterator.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/28/24.
//

import Synchronization

//public final class AnyAsyncIterator<Element: Sendable>: AsyncIteratorProtocol, Sendable {
//    typealias Closure = (_ actor: (any Actor)?) async throws -> Element?
//    
//    private let iterator: Mutex<any AsyncIteratorProtocol>
//    
//    public init<Iterator: AsyncIteratorProtocol>(_ iterator: Iterator) where Iterator.Element == Element {
//        self.iterator = .init(iterator)
////        self.iterator = .init({ actor in
////            var iterator = iterator
////            
////            if let actor {
////                return try await iterator.next(isolation: actor)
////            } else {
////                return try await iterator.next()
////            }
////        })
//    }
//    
//    public func next() async throws -> Element? {
////        try await closure(nil)
//    }
//    
//    public func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
////        try await closure(actor)
//    }
//}
