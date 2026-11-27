//
//  AsyncKVOSequenceTests.swift
//  AsyncReactiveSequences
//

import Foundation
import AVFoundation
import Testing
@testable import AsyncReactiveSequences

final class Observed: NSObject, @unchecked Sendable {
    @objc dynamic var value = 0
}

struct AsyncKVOSequenceTests {
    // The sink's task frees the sequence off the main actor, racing the object's release on it.
    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func outlivingTheObservedObjectDoesntCrash() async throws {
        for _ in 0..<5_000 {
            var object: Observed? = Observed()
            var cancellable: TaskCancellable? = AsyncKVOSequence(object: object!, keyPath: \.value).sink { _ in }

            await Task.yield()

            cancellable = nil
            object = nil

            _ = (cancellable, object)
        }

        try await Task.sleep(for: .milliseconds(200))
    }

    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func outlivingAPlayerLayerDoesntCrash() async throws {
        for _ in 0..<5_000 {
            var layer: AVPlayerLayer? = AVPlayerLayer()
            var cancellable: TaskCancellable? = AsyncKVOSequence(object: layer!, keyPath: \.isReadyForDisplay, dispatching: .object).sink { _ in }

            await Task.yield()

            cancellable = nil
            layer = nil

            _ = (cancellable, layer)
        }

        try await Task.sleep(for: .milliseconds(200))
    }

    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func outlivingAPlayerDoesntCrash() async throws {
        for _ in 0..<2_000 {
            var player: AVPlayer? = AVPlayer()
            var cancellable: TaskCancellable? = AsyncKVOSequence(object: player!, keyPath: \.timeControlStatus, dispatching: .object).sink { _ in }

            await Task.yield()

            cancellable = nil
            player = nil

            _ = (cancellable, player)
        }

        try await Task.sleep(for: .milliseconds(200))
    }
}
