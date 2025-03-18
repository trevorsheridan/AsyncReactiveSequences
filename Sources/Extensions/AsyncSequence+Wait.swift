//
//  AsyncSequence+Wait.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 2/9/25.
//

extension AsyncSequence {
    @discardableResult
    public func wait(for states: Element...) async throws -> Element  where Element: Equatable & Sendable {
        try await wait(for: states)
    }
    
    @discardableResult
    public func wait(for states: [Element]) async throws -> Element  where Element: Equatable & Sendable {
        try await drop { state in
            !states.contains(state)
        }.first()
    }
}
