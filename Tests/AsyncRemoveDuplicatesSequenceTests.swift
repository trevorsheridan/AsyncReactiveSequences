//
//  AsyncRemoveDuplicatesSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 10/28/24.
//

import Testing
@testable import AsyncReactiveSequences

struct AsyncRemoveDuplicatesSequenceTests {
    // MARK: - Ordered Delivery
    
    @Test("No duplicates with built-in `equatable` predicate")
    @MainActor
    func noDuplicates() async throws {
        let sequence = AsyncCurrentValueSequence(0)
        
        let task = Task {
            try await sequence.removeDuplicates().collect(count: 3)
        }
        
        try await Task.sleep(for: .milliseconds(16))
        
        Task {
            sequence.send(1)
            sequence.send(1)
            sequence.send(2)
            sequence.send(3)
        }
        
        #expect(try await task.value == [0, 1, 2])
    }
    
    struct NonEquatable {
        var value: Int
    }
    
    @Test("No duplicates with custom predicate")
    @MainActor
    func noDuplicatesWithCustomPredicate() async throws {
        let sequence = AsyncCurrentValueSequence(NonEquatable(value: 0))
        
        let task = Task {
            try await sequence.removeDuplicates(by: { a, b in
                a.value == b.value
            }).collect(count: 3)
        }
        
        try await Task.sleep(for: .milliseconds(16))
        
        Task {
            sequence.send(.init(value: 1))
            sequence.send(.init(value: 1))
            sequence.send(.init(value: 2))
            sequence.send(.init(value: 3))
        }
        
        let values = try await task.value.compactMap { item in
            item.value
        }
        
        #expect(values == [0, 1, 2])
    }
    
    @Test("Value is immediately returned upon subscription when CurrentValueSequence is upstream")
    @MainActor
    func lateRegistration() async throws {
        let sequence = AsyncCurrentValueSequence(100)
        try await Task.sleep(for: .seconds(1))
        let value = try await sequence.removeDuplicates().first()
        #expect(value == 100)
    }
}
