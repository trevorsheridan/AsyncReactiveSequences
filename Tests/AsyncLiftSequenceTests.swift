//
//  AsyncLiftSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/25/25.
//

import Testing
@testable import AsyncReactiveSequences

struct AsyncLiftSequenceTests {
    let sequence = AsyncLiftSequence {
        try await Task {
            try await Task.sleep(for: .seconds(1))
            return 100
        }.value
    }
    
    @Test("AsyncLiftSequence emits the value from awaited closure then ends iteration", .timeLimit(.minutes(1)))
    @MainActor
    func initialValue() async throws {
        var v: Int = 0
        for try await value in sequence {
            v = value
        }
        #expect(v == 100)
    }
}
