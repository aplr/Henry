//
//  Job.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 02.08.21.
//

import Foundation
import Pillarbox

public typealias JobCancellable = () -> Void

public protocol Job: Codable {
            
    var shouldContinueInBackground: Bool { get }
    
    var maxTries: Int { get }
        
    var retryUntil: Date? { get }
    
    var timeout: TimeInterval { get }
    
    var earliestBeginTime: Date? { get }
    
    var expirationTime: Date? { get }
        
    func handle(completion: (Henry.Result) -> Void) -> JobCancellable
        
    func jobDidSucceed()
    
    func jobDidFail(reason: Henry.FailReason) -> Henry.FailAction
}

extension Job {
    
    var shouldContinueInBackground: Bool {
        false
    }
    
    var maxTries: Int {
        1
    }
    
    var retryUntil: Date? {
        nil
    }
    
    var timeout: TimeInterval {
        120
    }
    
    var earliestBeginTime: Date? {
        nil
    }
    
    var expirationTime: Date? {
        nil
    }
    
    func jobDidSucceed() {
        // Do nothing per default
    }
    
    func jobDidFail(reason: Henry.FailReason) -> Henry.FailAction {
        // Drop the job per default
        .drop
    }
}
