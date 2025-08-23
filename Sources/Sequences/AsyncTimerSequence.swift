//
//  AsyncTimerSequence.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 8/23/25.
//

public struct AsyncTimerSequence<C: Clock>: AsyncSequence {
    public typealias Element = C.Instant
    
    let interval: C.Duration
    let tolerance: C.Duration?
    let clock: C
    
    init(interval: C.Duration, tolerance: C.Duration? = nil, clock: C) {
        self.interval = interval
        self.tolerance = tolerance
        self.clock = clock
    }

    public struct Iterator: AsyncIteratorProtocol {
        var interval: C.Duration
        var tolerance: C.Duration?
        var clock: C
        var next: C.Instant
        
        public mutating func next(isolation actor: isolated (any Actor)?) async throws(Never) -> C.Instant? {
            guard !Task.isCancelled else {
                return nil
            }
            
            try? await clock.sleep(until: next, tolerance: tolerance)
            defer { next = next.advanced(by: interval) }
            
            return next
        }
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(interval: interval, tolerance: tolerance, clock: clock, next: clock.now)
    }
}
