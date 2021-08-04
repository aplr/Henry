//
//  PersistedJob.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 03.08.21.
//

import Foundation
import Pillarbox

open class QueuedJob: Job, QueueIdentifiable, Equatable {
    
    public let id: String
    
    let jobType: String
    let job: Job
    
    public internal(set) var tries: Int
    public internal(set) var state: State
    
    public static func == (lhs: QueuedJob, rhs: QueuedJob) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString, job: Job, tries: Int = 0, state: State = .created) {
        self.id = id
        self.jobType = "\(job.self)"
        self.job = job
        self.tries = tries
        self.state = state
    }
    
    func reset() {
        self.state = .created
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let jobType = try container.decode(String.self, forKey: .jobType)
        
        guard let type = Queue.jobRegistry[jobType] else {
            throw Henry.Error.jobNotRegistered
        }
        
        let jobDecoder = try container.superDecoder(forKey: .job)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.jobType = jobType
        self.job = try type.init(from: jobDecoder)
        self.tries = try container.decode(Int.self, forKey: .tries)
        self.state = try container.decode(State.self, forKey: .state)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(jobType, forKey: .jobType)
        try job.encode(to: container.superEncoder(forKey: .job))
        try container.encode(tries, forKey: .tries)
        try container.encode(state, forKey: .state)
    }
    
    public var shouldContinueInBackground: Bool {
        job.shouldContinueInBackground
    }
    
    public var maxTries: Int {
        job.maxTries
    }
    
    public var retryUntil: Date? {
        job.retryUntil
    }
    
    public var timeout: TimeInterval {
        job.timeout
    }
    
    public var earliestBeginTime: Date? {
        job.earliestBeginTime
    }
    
    public var expirationTime: Date? {
        job.expirationTime
    }
    
    public var priority: Henry.Priority {
        job.priority
    }
    
    public func handle(completion: (Henry.Result) -> Void) -> JobCancellable {
        job.handle(completion: completion)
    }
    
    public func jobDidSucceed() {
        job.jobDidSucceed()
    }
    
    public func jobDidFail(reason: Henry.FailReason) -> Henry.FailAction {
        job.jobDidFail(reason: reason)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, job, jobType, tries, state
    }
    
    public enum State: Codable {
        case created
        case queued
        case running
        case succeded
        case failed
        
        var isEnqueable: Bool {
            switch self {
            case .succeded, .failed: return false
            default: return true
            }
        }
        
        var isSuccess: Bool {
            switch self {
            case .succeded: return true
            default: return false
            }
        }
    }
}
