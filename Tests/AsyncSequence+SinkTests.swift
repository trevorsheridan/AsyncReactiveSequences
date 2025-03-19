//
//  AsyncSequence+SinkTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/27/24.
//

import Testing
@testable import AsyncReactiveSequences

final class SinkTests {
    let sequence = AsyncCurrentValueSequence(0)
    var cancellables = Set<TaskCancellable>()
    
    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func orderingPreserved() async throws {
        let s = AsyncCurrentValueSequence<Int?>(nil)
        
        let task = Task { @SinkActor in
            // This must be on @SinkActor to preserve ordering.
            return try await s.compactMap { $0 }.collect(count: 3)
        }
        
        sequence.sink(identifier: 1) { value in
            // noop
        } registration: { value in
            s.send(value)
        }
        .store(in: &cancellables)
        
        sequence.sink(identifier: 2) { value in
            // noop
        } registration: { value in
            s.send(value)
        }
        .store(in: &cancellables)
        
        sequence.sink(identifier: 3) { value in
            // noop
        } registration: { value in
            s.send(value)
        }
        .store(in: &cancellables)
        
        let value = try await task.value
        
        #expect(value == [1, 2, 3])
    }
}
