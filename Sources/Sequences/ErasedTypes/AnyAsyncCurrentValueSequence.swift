//
//  AnyAsyncCurrentValueSubject.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/27/24.
//

public struct AnyAsyncCurrentValueSequence {
    private let base: AsyncCurrentValueSequence<(any Sendable)?>
    
    public init(_ base: AsyncCurrentValueSequence<(any Sendable)?>) {
        self.base = base
    }
    
    public func send<Value: Sendable>(value: Value) {
        base.send(value)
    }
    
    public func sequence<Value: Sendable>() -> AnyAsyncSequence<Value> {
        base.compactMap { value in
            value as? Value
        }.eraseToAnyAsyncSequence()
    }
}
