//
//  AsyncCombineLatestSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/6/24.
//

import Testing
@testable import ReactiveAsyncSequences

struct AsyncCombineLatestSequenceTests {
    @Test("Initial values from both AsyncCurrentValueSequences are returned from 2 sequences")
    @MainActor
    func initialCurrentValueSequenceValuesAreReturnedFrom2Sequences() async throws {
        let a = AsyncCurrentValueSequence<Int>(1)
        let b = AsyncCurrentValueSequence<Bool>(true)
        
        let results = try await a.combineLatest(b).first()
        
        #expect(results == (1, true))
    }
    
    @Test("Initial values from both AsyncCurrentValueSequences are returned from 3 sequences")
    @MainActor
    func initialCurrentValueSequenceValuesAreReturnedFrom3Sequences() async throws {
        let a = AsyncCurrentValueSequence<Int>(1)
        let b = AsyncCurrentValueSequence<Bool>(true)
        let c = AsyncCurrentValueSequence<Bool>(false)
        
        let results = try await a.combineLatest(b, c).first()
        
        #expect(results == (1, true, false))
    }
    
    @Test("Values sent through both AsyncCurrentValueSequences are returned")
    @MainActor
    func valuesSentThroughBothCurrentValueSequencesAreReturned() async throws {
        let a = AsyncCurrentValueSequence<Int>(1)
        let b = AsyncCurrentValueSequence<Bool>(false)
        let combineLatestSequence = AsyncCombineLatestSequence(a, b)
        
        let task = Task {
            try await combineLatestSequence.collect(count: 3)
        }
        
        // Sleep to let the initial sequence values to come through.
        try await Task.sleep(for: .milliseconds(100))
        
        Task {
            a.send(2)
            
            // Sleep to let the initial sequence values to come through.
            try await Task.sleep(for: .milliseconds(100))
            
            b.send(true)
        }
        
        let results = try await task.value
        
        #expect(results[0] == (1, false))
        #expect(results[1] == (2, false))
        #expect(results[2] == (2, true))
    }
    
    @Test("First value should not be the default nil value held within AsyncCombineLatestSequence's internal AsyncCurrentValueSequence")
    @MainActor
    func firstValueReceivedIsNotNil() async throws {
        let a = AsyncCurrentValueSequence<Int>(1)
        let b = AsyncCurrentValueSequence<Bool>(false)
        let combineLatestSequence = AsyncCombineLatestSequence(a, b)
        
        let first = try await combineLatestSequence.first()
        
        #expect(first != nil)
    }
}
