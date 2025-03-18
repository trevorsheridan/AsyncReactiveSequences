//
//  AsyncSequence+SinkTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/27/24.
//

import Testing
@testable import ReactiveAsyncSequences

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
        
        sequence.sink(number: 1, cancellation: .automatic) { value in
            // noop
        } registration: { value in
            s.send(value)
        }
        .store(in: &cancellables)
        
        sequence.sink(number: 2, cancellation: .automatic) { value in
            // noop
        } registration: { value in
            s.send(value)
        }
        .store(in: &cancellables)
        
        sequence.sink(number: 3, cancellation: .automatic) { value in
            // noop
        } registration: { value in
            s.send(value)
        }
        .store(in: &cancellables)
        
        let value = try await task.value
        
        #expect(value == [1, 2, 3])
    }
}
