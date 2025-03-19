//
//  Sequenced.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/26/24.
//

@propertyWrapper
public final class Sequenced<Value>: Sendable where Value: Sendable {
    // Shadows the AsyncCurrentValueSequence so implementors of this API cannot call send on the underlying sequence and must set the property through the actual value being wrapped by this property wrapper.
    public var wrappedValue: Value {
        set {
            projectedValue.currentValueSequence.send(newValue)
        } get {
            projectedValue.currentValueSequence.value
        }
    }
    
    public nonisolated(unsafe) var projectedValue: AsyncReadOnlyCurrentValueSequence<Value> {
        set {
            storage = newValue
        } get {
            storage
        }
    }
    
    private nonisolated(unsafe) var storage: AsyncReadOnlyCurrentValueSequence<Value>
    
    public init(wrappedValue: Value) {
        storage = .init(wrappedValue)
    }
}
