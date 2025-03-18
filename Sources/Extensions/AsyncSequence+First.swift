//
//  AsyncSequence+First.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/6/24.
//

extension AsyncSequence {
    public func first(isolation actor: isolated (any Actor)? = #isolation) async throws -> Element {
        for try await value in self {
            return value
        }
        throw ReactiveAsyncSequencesError.unxpectedEndOfSequence
    }
}
