//
//  AsyncPromiseTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/6/24.
//

import Testing
@testable import AsyncReactiveSequences

struct AsyncPromiseTests {
    let promise = AsyncPromiseSequence<Int>()
    
    enum Error: Swift.Error {
        case SomeFailure
    }
    
    @Test("Promise returns fulfilled element", .timeLimit(.minutes(1)))
    func promiseReturnsFulfilledElement() async throws {
        Task {
            try await Task.sleep(for: .seconds(2))
            try promise.fulfill(.success(100))
        }
        
        let value = try await promise.first()
        #expect(await value == 100)
    }
    
    @Test("Promise throws error when fulfilled with failure", .timeLimit(.minutes(1)))
    func promiseThrows() async throws {
        Task {
            try await Task.sleep(for: .seconds(2))
            try promise.fulfill(.failure(Error.SomeFailure))
        }
        
        await #expect(throws: Error.self, performing: {
            try await promise.first()
        })
    }
    
    @Test("Promise continuation finishes after returning first element", .timeLimit(.minutes(1)))
    func promiseFinishesAfterReturningFirst() async throws {
        Task {
            try await Task.sleep(for: .milliseconds(100))
            try promise.fulfill(.success(100))
        }
        
        var v: Int = 0
        
        for try await value in promise {
            v = value
        }
        
        try #require(v == 100)
    }
    
    @Test("Cancelling a waiting task while the promise is fulfilled doesn't deadlock", .timeLimit(.minutes(1)))
    func cancellingWhileFulfillingDoesNotDeadlock() async throws {
        for _ in 0..<2_000 {
            let promise = AsyncPromiseSequence<Int>()
            
            let waiting = Task.detached {
                try await promise.first()
            }
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    try? promise.fulfill(.success(1))
                }
                
                group.addTask {
                    waiting.cancel()
                }
            }
            
            _ = try? await waiting.value
        }
    }
}
