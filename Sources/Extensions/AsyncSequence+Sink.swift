//
//  AsyncSequence+Sink.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 9/27/24.
//

import Synchronization

@globalActor
public actor SinkActor {
    public static let shared = SinkActor()
}

extension AsyncSequence where Self: Sendable {
    @discardableResult
    public func sink(
        cancellation: TaskCancellable.Mode,
        @_inheritActorContext work: @Sendable @escaping @isolated(any) (Element) async -> Void
    ) -> TaskCancellable
    where Element: Sendable {
        sink(cancellation: cancellation, work: work, registration: nil)
    }
    
    @discardableResult
    func sink(
        number: Int = 0,
        cancellation: TaskCancellable.Mode,
        @_inheritActorContext work: @Sendable @escaping @isolated(any) (Element) async -> Void,
        registration: (@Sendable (Int) -> Void)?
    ) -> TaskCancellable
    where Element: Sendable {
        let task = Task { @SinkActor in
            // WARNING: If this method inherits the actor isolation of the caller (e.g., by introducing
            // `isolation: isolated(any Actor)? = #isolation`), do NOT reference the `isolation` parameter
            // (e.g., using `_ = isolation`). Doing so would execute this task on the specified actor,
            // potentially causing a retain cycle if the method is called from the same actor that holds
            // a reference to this AsyncSequence.
            //
            // To prevent this, tasks are explicitly pushed onto a custom `@SinkActor`, which ensures:
            // 1. Avoiding retain cycles caused by actor references.
            // 2. Preserving task execution order, which would otherwise be lost if tasks were sent
            //    to the global concurrent executor.
            //
            // This is crucial for scenarios like video or audio processing, where frames arriving
            // out of order would lead to corruption.
            registration?(number)

            for try await element in self {
                await work(element)
            }
        }
        
        return TaskCancellable(task: task, mode: cancellation)
    }
}
