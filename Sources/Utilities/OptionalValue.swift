//
//  OptionalValue.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 1/25/25.
//


protocol OptionalValue {
    var isNil: Bool { get }
}

extension Optional: OptionalValue {
    var isNil: Bool {
        self == nil
    }
}

func isNil<E>(_ element: E) -> Bool {
    if let element = element as? OptionalValue, element.isNil {
        return true
    }
    return false
}
