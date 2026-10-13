//
//  AsyncPassthroughSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/13/24.
//

import Testing
@testable import AsyncReactiveSequences

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
    
    @Test("A value sent before anyone subscribes is not delivered", .timeLimit(.minutes(1)))
    @MainActor
    func valueSentBeforeSubscribingIsNotDelivered() async throws {
        sequence.send(1)
        
        let task = Task {
            try await sequence.first()
        }
        
        try await Task.sleep(for: .milliseconds(100))
        
        sequence.send(2)
        
        let value = try await task.value
        
        #expect(value == 2)
    }
    
    @Test("A value sent before anyone subscribes is delivered when delivering unreceived values", .timeLimit(.minutes(1)))
    @MainActor
    func unreceivedValueIsDelivered() async throws {
        let sequence = AsyncPassthroughSequence<Int>(deliversUnreceived: true)
        
        sequence.send(1)
        
        let value = try await sequence.first()
        
        #expect(value == 1)
    }
    
    @Test("Only the latest unreceived value is delivered", .timeLimit(.minutes(1)))
    @MainActor
    func onlyLatestUnreceivedValueIsDelivered() async throws {
        let sequence = AsyncPassthroughSequence<Int>(deliversUnreceived: true)
        
        sequence.send(1)
        sequence.send(2)
        sequence.send(3)
        
        let task = Task {
            try await sequence.collect(count: 2)
        }
        
        try await Task.sleep(for: .milliseconds(100))
        
        sequence.send(4)
        
        let values = try await task.value
        
        #expect(values == [3, 4])
    }
    
    @Test("A value a subscriber received is not delivered to a later subscriber", .timeLimit(.minutes(1)))
    @MainActor
    func receivedValueIsNotReplayed() async throws {
        let sequence = AsyncPassthroughSequence<Int>(deliversUnreceived: true)
        
        sequence.send(1)
        
        let first = try await sequence.first()
        
        let task = Task {
            try await sequence.first()
        }
        
        try await Task.sleep(for: .milliseconds(100))
        
        sequence.send(2)
        
        let second = try await task.value
        
        #expect(first == 1)
        #expect(second == 2)
    }
    
    @Test("An unreceived nil element of an optional type is delivered", .timeLimit(.minutes(1)))
    @MainActor
    func unreceivedNilElementIsDelivered() async throws {
        let sequence = AsyncPassthroughSequence<Int?>(deliversUnreceived: true)
        
        sequence.send(nil)
        
        let value = try await sequence.first()
        
        #expect(value == .some(nil))
    }
}
