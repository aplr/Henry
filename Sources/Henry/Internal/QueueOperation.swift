//
//  QueueOperation.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 02.08.21.
//

import Foundation
import Pillarbox

class QueueOperation: Operation {
    
    enum State {
        case ready
        case executing
        case finished(_ result: Result)
        
        fileprivate var keyPath: String {
            switch self {
            case .ready: return "isReady"
            case .executing: return "isExecuting"
            case .finished: return "isFinished"
            }
        }
        
        var isReady: Bool {
            switch self {
            case .ready: return true
            default: return false
            }
        }
        
        var isExecuting: Bool {
            switch self {
            case .executing: return true
            default: return false
            }
        }
        
        var isFinished: Bool {
            switch self {
            case .finished: return true
            default: return false
            }
        }
    }
    
    enum Result {
        case succeeded
        case failed(_ reason: Henry.FailReason)
        
        var state: QueuedJob.State {
            switch self {
            case .succeeded: return .succeded
            case .failed: return .failed
            }
        }
    }
    
    override var isReady: Bool {
        state.isReady && super.isReady
    }
    
    override var isExecuting: Bool {
        state.isExecuting
    }
    
    override var isFinished: Bool {
        state.isFinished
    }
    
    var state: State = .ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            willChangeValue(forKey: oldValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
    }
    
    var job: QueuedJob
    let mode: Queue.Mode
    let pillarbox: Pillarbox<QueuedJob>
    
    var currentCancel: JobCancellable?
    var isTimeout: Bool = false

    var currentTry: Int {
        job.tries
    }
    
    var maxTries: Int {
        job.maxTries
    }
    
    init(
        job: QueuedJob,
        mode: Queue.Mode,
        pillarbox: Pillarbox<QueuedJob>,
        completion: ((QueueOperation) -> Void)? = nil
    ) {
        self.job = job
        self.mode = mode
        self.pillarbox = pillarbox
        super.init()
        self.completionBlock = { [weak self] in
            guard let self = self, let completion = completion else { return }
            completion(self)
        }
    }
    
    override func start() {
        // Check if the job is allowed to start.
        // This is only if all its dependencies did succeed.
        guard dependencies.allSatisfy({ ($0 as? QueueOperation)?.job.state.isSuccess ?? true }) else {
            finish(.failed(.dependencyFailed))
            return
        }
        
        updateJobState(state: .running)
        
        setupTimeout()
        
        state = .executing
        execute()
    }
    
    private func setupTimeout() {
        guard job.timeout > 0 else { return }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(job.timeout))) {
            self.timeout()
        }
    }
    
    /// Execute the `Operation`.
    /// If `executionBlock` is set, it will be executed and also `finish()` will be called.
    private func execute() {
        let now = Date()
        
        guard !isTimeout else {
            finish(.failed(.timeout))
            return
        }
        
        guard state.isExecuting else {
            finish(.failed(.cancelled))
            return
        }
        
        guard currentTry < maxTries else {
            finish(.failed(.tooManyTries))
            return
        }
        
        if let expirationTime = job.expirationTime, expirationTime <= now {
            finish(.failed(.expired))
            return
        }
        
        if let retryUntil = job.retryUntil, job.tries > 0 && retryUntil <= now {
            finish(.failed(.expired))
            return
        }
                
        job.tries += 1
        pillarbox.update(job)
        
        currentCancel = job.handle(completion: handleJobCompletion)
    }
    
    private func handleJobCompletion(_ result: Henry.Result) {
        guard result.isSuccess else {
            execute()
            return
        }
        
        finish(.succeeded)
    }
    
    private func finish(_ result: Result) {
        state = .finished(result)
        updateJobState(state: result.state)
    }
    
    func timeout() {
        isTimeout = true
        cancel()
    }
    
    override func cancel() {
        super.cancel()
        
        currentCancel?()
    }
    
    private func updateJobState(state: QueuedJob.State) {
        job.state = state
        pillarbox.update(job)
    }
}
