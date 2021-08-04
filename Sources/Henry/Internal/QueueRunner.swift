//
//  QueueRunner.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 03.08.21.
//

import Foundation
import Pillarbox
#if canImport(UIKit)
import UIKit
#endif


class QueueRunner {
    
    let name: String
    let mode: Queue.Mode
    let qos: Queue.Qos
    
    private var running: Bool = false
    
    private var lastOperation: Operation?
    
    init(name: String, mode: Queue.Mode, qos: Queue.Qos) {
        self.name = name
        self.mode = mode
        self.qos = qos
    }
    
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = name
        queue.maxConcurrentOperationCount = mode.maxConcurrentOperationCount
        queue.qualityOfService = qos.operationQos
        return queue
    }()
    
    private lazy var pillarbox: Pillarbox<QueuedJob> = {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("queuedata")
        return Pillarbox<QueuedJob>(name: "\(name)", url: url)
    }()
    
    func run() {
        for job in pillarbox.elements {
            enqueue(job)
        }
    }
    
    func dispatch<T: Job>(_ job: T) -> QueuedJob {
        // Create the persisted job, which encapsulates our job
        // together with the number of tries already made.
        let queuedJob = QueuedJob(job: job)
        
        // Enqueue the job for processing
        enqueue(queuedJob)
        
        return queuedJob
    }
    
    private func enqueue(_ job: QueuedJob) {
        let now = Date()
        
        // Don't enqueue if the job is finished or has reached its max tries
        guard job.state.isEnqueable, job.tries < job.job.maxTries else { return }
        
        // Don't enqueue if the job has reached its expiration time
        if let expirationTime = job.job.expirationTime, expirationTime <= now { return }
        
        // Don't enqueue if the job has reached its retry expiration time
        if let retryUntil = job.job.retryUntil, job.tries > 0, retryUntil <= now { return }
        
        // Persist the job in the queue
        pillarbox.put(job)
        
        // Create a operation
        let operation = QueueOperation(job: job, mode: mode, pillarbox: pillarbox)
        
        // When running on iOS, we register a background task so we
        // are granted more execution time after the app is suspended
        let backgroundTaskIdentifier = job.job.shouldContinueInBackground
            ? beginBackgroundTask(expirationHandler: { operation.cancel() })
            : nil
        
        operation.completionBlock = { [weak self] in
            self?.operationDidComplete(operation)
            
            // As soon as the operation is completed, we tell the system that
            // our background task did complete using the corresponding identifier.
            if let backgroundTaskIdentifier = backgroundTaskIdentifier {
                endBackgroundTask(identifier: backgroundTaskIdentifier)
            }
        }
        
        // If our queue is a serial, blocking queue, we enforce a total order
        // over all elements in the queue. This way, if one of the operations fails,
        // all consecutive ones should fail as well.
        if case .blocking = mode, let lastOperation = lastOperation {
            operation.addDependency(lastOperation)
        }
        
        // Add the operation to our queue
        operationQueue.addOperation(operation)
        
        // Set the new operation as our last added operation
        lastOperation = operation
    }
}


// MARK: - Operation Completion Handling

extension QueueRunner {
    
    private func operationDidComplete(_ operation: QueueOperation) {
        guard case let .finished(result) = operation.state else { return }
        
        if case .succeeded = result {
            handleSucceededJob(job: operation.job)
        } else if case let .failed(reason) = result {
            handleFailedJob(job: operation.job, reason: reason)
        }
    }
    
    private func handleSucceededJob(job: QueuedJob) {
        job.jobDidSucceed()
        removeJob(job)
    }
    
    private func handleFailedJob(job: QueuedJob, reason: Henry.FailReason) {
        switch job.jobDidFail(reason: reason) {
        case .drop: removeJob(job)
        case .release: releaseJob(job)
        }
    }
    
    private func removeJob(_ job: QueuedJob) {
        pillarbox.remove(job)
    }
    
    private func releaseJob(_ job: QueuedJob) {
        // First, remove the persisted job
        pillarbox.remove(job)
        
        // Then, reset the job
        job.reset()
        
        // Then, try to enqueue the job. This it is not
        // guaranteed to succeed, as the job might be expired.
        enqueue(job)
    }
}
