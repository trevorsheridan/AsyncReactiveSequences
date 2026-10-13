//
//  AsyncSwitchToLatestSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 10/13/26.
//

import Testing
@testable import AsyncReactiveSequences

struct AsyncSwitchToLatestSequenceTests {
    @Test("The inner sequence's current value is delivered to an iterator that starts after it arrived", .timeLimit(.minutes(1)))
    @MainActor
    func currentValueArrivingBeforeIterationIsDelivered() async throws {
        let outer = AsyncCurrentValueSequence(AsyncCurrentValueSequence(1))
        let sequence = outer.switchToLatest()
        
        // Let the upstream deliver the inner's current value before anything iterates.
        try await Task.sleep(for: .milliseconds(100))
        
        let value = try await sequence.first()
        
        #expect(value == 1)
    }
    
    @Test("A nil element from an optional inner sequence is delivered", .timeLimit(.minutes(1)))
    @MainActor
    func nilElementIsDelivered() async throws {
        let outer = AsyncCurrentValueSequence(AsyncCurrentValueSequence<Int?>(nil))
        let sequence = outer.switchToLatest()
        
        try await Task.sleep(for: .milliseconds(100))
        
        let value = try await sequence.first()
        
        #expect(value == .some(nil))
    }
    
    @Test("Switching to a new inner sequence stops delivering the old one", .timeLimit(.minutes(1)))
    @MainActor
    func switchingStopsTheOldInnerSequence() async throws {
        let first = AsyncCurrentValueSequence(1)
        let second = AsyncCurrentValueSequence(2)
        let outer = AsyncCurrentValueSequence(first)
        let sequence = outer.switchToLatest()
        let iterator = sequence.makeAsyncIterator()
        
        let initial = try await iterator.next()
        
        outer.send(second)
        
        let switched = try await iterator.next()
        
        first.send(99)
        second.send(3)
        
        let latest = try await iterator.next()
        
        // The iterator doesn't retain the sequence, and releasing it cancels the upstream.
        withExtendedLifetime(sequence) {}
        
        #expect(initial == 1)
        #expect(switched == 2)
        #expect(latest == 3)
    }
}
