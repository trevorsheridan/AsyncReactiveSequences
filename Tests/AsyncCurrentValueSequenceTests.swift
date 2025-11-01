//
//  AsyncCurrentValueSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/6/24.
//

import Testing
@testable import AsyncReactiveSequences

@Suite
struct AsyncCurrentValueSequenceTests {
    let sequence = AsyncCurrentValueSequence(0)
    
    // MARK: - Ordered Delivery
    
    @Test("Value sent before subscription is delivered as the only element")
    func sendValueBeforeRegistration() async throws {
        sequence.send(1)
        async let value = sequence.collect(count: 1)
        #expect(try await value == [1])
    }
    
    @Test("Value sent immediately after registration is delivered with initial element in sequence")
    @TestActor
    func sendValueAfterRegistration() async throws {
        // All tasks will be serially executed because this test is isolated to @TestActor. Without this, we can't guarantee
        // that the first task listed will occur before the second.
        
        let task = Task {
            try await sequence.collect(count: 2)
        }
        
        Task {
            sequence.send(1)
        }
        
        #expect(try await task.value == [0, 1])
    }
    
    @Test("Multiple subscribers before first send receive the same elements in order", .timeLimit(.minutes(1)))
    @TestActor
    func sendValueAfterRegistrationToMulipleSubscribersUsingUnstructuredTasks() async throws {
        try await confirmation(expectedCount: 2) { @Sendable confirmation in
            // It's critical that each task is isolated to TestActor so that each task is sequentially executed.
            
            let task = Task { @TestActor in
                try await sequence.collect(count: 3)
            }
            
            let task2 = Task { @TestActor in
                try await sequence.collect(count: 3)
            }
            
            Task { @TestActor in
                sequence.send(1)
                sequence.send(2)
            }
            
            let collection = try await task.value
            let collection2 = try await task2.value
            
            if (collection == [0, 1, 2] && collection2 == [0, 1, 2]) {
                confirmation.confirm()
            }
            
            // Ensure further sends only deliver fresh elements to new subscribers.
            
            sequence.send(3)
            
            let next = try await sequence.collect(count: 1)
            
            if next == [3] {
                confirmation.confirm()
            }
        }
    }
    
    @Test(
        "Multiple subscribers before first send receive the same elements in order",
        .timeLimit(.minutes(1)),
        .disabled("This test is expected to intermittently fail because of the way thild tasks are spawned on the global concurrent executor, rather than the way the unstructured tasks above sequentially execute before sequence.send is invoked.")
    )
    func sendValueAfterRegistrationToMulipleSubscribersUsingChildTasks() async throws {
        async let collection = sequence.collect(count: 3)
        async let collection2 = sequence.collect(count: 3)
    
        sequence.send(1)
        sequence.send(2)
        
        try #require(try await collection == [0, 1, 2])
        try #require(try await collection2 == [0, 1, 2])
    }
    
    // MARK: - Duplicates
    
    @Test("Ensure duplicate values are allowed through", .timeLimit(.minutes(1)))
    @TestActor
    func duplicateValuesAreAllowed() async throws {
        let task = Task {
            try await sequence.collect(count: 3)
        }
        
        Task {
            sequence.send(1)
            sequence.send(1)
        }
        
        #expect(try await task.value == [0, 1, 1])
    }
    
    // MARK: - Void
    
    @Test("Ensure void element is delivered", .timeLimit(.minutes(1)))
    @TestActor
    func voidElementIsDelivered() async throws {
        let sequence = AsyncCurrentValueSequence(())
        
        let task = Task {
            try await sequence.collect(count: 2)
        }
        
        Task {
            sequence.send()
        }
        
        _ = try await task.value
    }
    
    // MARK: - Cancellation
    
    @Test("Cancellation stops sending values to cancelled tasks")
    @TestActor
    func cancelledTasksStopsReceivingValues() async throws {
        var values: [Int] = []
        
        // This task will later get cancelled.
        let task = Task {
            for try await value in sequence {
                values.append(value)
            }
        }
        
        Task {
            for try await value in sequence {
                values.append(value)
            }
        }
        
        // Sleep to let the initial sequence values to come through
        try await Task.sleep(for: .milliseconds(100))

        task.cancel()
        
        // Send a value through the sequence, this should not get delivered to the cancelled task.
        sequence.send(1)
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Combine all of the expected values into a string to evaluate with.
        let valueString = values.sorted().reduce(into: "") { accumulator, value in
            accumulator += "\(value)"
        }
        
        #expect(valueString == "001")
    }
    
    // MARK: - Subscriber Management
    
    @Test("Subscriber is unregistered when for loop exists")
    func unregisterSubscriberWhenForLoopExits() async throws {
        #expect(try await sequence.subscribers.count == 0)
        
        for try await value in sequence {
            break
        }
        
        #expect(try await sequence.subscribers.count == 0)
    }
}
