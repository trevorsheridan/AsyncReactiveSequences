//
//  AsyncSequence+Collect.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/10/24.
//

extension AsyncSequence where Element: Sendable {
    public func collect(isolation: isolated (any Actor)? = #isolation, count: Int) async throws -> [Element] {
        var collection: [Element] = []
        
        for try await element in self {
            collection.append(element)
            if collection.count == count {
                break
            }
        }
        
        return collection
    }
}
