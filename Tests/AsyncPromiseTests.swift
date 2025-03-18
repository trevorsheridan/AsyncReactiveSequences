//
//  AsyncPromiseTests.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/6/24.
//

import Testing
@testable import ReactiveAsyncSequences

struct AsyncFutureTests {
    let promise = AsyncPromise<Int>()
    
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
        #expect(try await value == 100)
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
}
