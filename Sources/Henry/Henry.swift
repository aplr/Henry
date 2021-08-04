//
//  Henry.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 07.04.21.
//

import Pillarbox
import Foundation

public struct Henry {
    
    static var `shared` = Henry()
    
    public enum FailReason {
        case error(_ error: Swift.Error)
        case expired
        case timeout
        case cancelled
        case dependencyFailed
        case tooManyTries
    }
    
    public enum FailAction {
        case release
        case drop
    }
    
    public enum Result {
        case success
        case failed(_ error: Swift.Error? = nil)
        
        var isSuccess: Bool {
            switch self {
            case .success: return true
            case .failed(_): return false
            }
        }
    }
    
    public enum Error: Swift.Error {
        case jobNotRegistered
        case queueAlreadyActive
    }
}
