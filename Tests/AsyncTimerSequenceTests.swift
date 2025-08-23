//
//  AsyncTimerSequenceTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/23/25.
//

import Testing
@testable import AsyncReactiveSequences

struct AsyncTimerSequenceTests {
    let clock = ContinuousClock()
    
    @Test("Timer ticks ~every 100ms with tolerance")
    @MainActor
    func testTimerTicksOnSchedule() async throws {
        let interval = Duration.milliseconds(100)
        let tolerance = Duration.milliseconds(30)
        
        let results = try await AsyncTimerSequence(interval: interval, tolerance: tolerance, clock: clock)
        .collect(count: 3)
        .reduce(into: []) { accumulator, now in
            accumulator.append(now)
        }
        
        #expect(results.count == 3)
        
        // Check that each successive tick is roughly 100ms apart
        for (i, (a, b)) in zip(results, results.dropFirst()).enumerated() {
            let delta = a.duration(to: b)
            #expect((interval - tolerance)...(interval + tolerance) ~= delta, "delta[\(i)] was \(delta)")
        }
    }
}
