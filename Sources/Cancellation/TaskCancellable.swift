//
//  TaskCancellable.swift
//  AsyncReactiveSequences
//
//  Created by Trevor Sheridan on 11/21/24.
//

import Foundation

public final class TaskCancellable {
    /// Describes how the cancellable should handle the act of cancelling the task.
    public enum Mode {
        /// In this mode the cancellable will take responsibility of cancelling the task when it is deallocated.
        case automatic
        /// In this mode you must take care of cancelling the task yourself, or in some instances never calling cancel and letting the task live on forever.
        case manual
    }
    
    private let id = UUID()
    private let mode: Mode
    private let cancel: () -> Void
    
    public init<V, E>(task: Task<V, E>, mode: Mode = .automatic) where E: Error {
        self.mode = mode
        self.cancel = {
            task.cancel()
        }
    }
    
    deinit {
        if mode == .automatic {
            cancel()
        }
    }
}

extension TaskCancellable: Hashable {
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

extension TaskCancellable: Equatable {
    public static func == (lhs: TaskCancellable, rhs: TaskCancellable) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension TaskCancellable {
    public func store(in set: inout Set<TaskCancellable>) {
        set.insert(self)
    }
}
