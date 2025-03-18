//
//  AsyncPassthroughSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/13/24.
//

import Testing
@testable import ReactiveAsyncSequences

struct AsyncPassthroughSequenceTests {
    let sequence = AsyncPassthroughSequence<Int>()
    
    @Test("Initial value received is first value sent through sequence", .timeLimit(.minutes(1)))
    @MainActor
    func initialValue() async throws {
        let task = Task {
            try await sequence.first()
        }
        
        try await Task.sleep(for: .milliseconds(100))
        
        Task {
            sequence.send(1)
        }
        
        let value = try await task.value
        
        #expect(value == 1)
    }
    
    @Test("Multiple values are delivered in the order they were sent", .timeLimit(.minutes(1)))
    @MainActor
    func multipleValuesDeliveredInOrder() async throws {
        let range = 0...100
        
        let task = Task {
            try await sequence.collect(count: range.count)
        }
        
        try await Task.sleep(for: .milliseconds(100))
        
        Task {
            for value in range {
                sequence.send(value)
            }
        }
        
        let value = try await task.value
        
        #expect(value == Array(range))
    }
}
