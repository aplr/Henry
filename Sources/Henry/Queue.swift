//
//  Queue.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 03.08.21.
//

import Foundation

open class Queue {
    
    public static let `default` = Queue()
    
    static var jobRegistry: [String: Job.Type] = [:]
    
    static var queueRegistry: [Connection: QueueRunner] = [:]
    
    private lazy var queueRunner: QueueRunner = {
        if let queueRunner = Self.queueRegistry[connection] {
            return queueRunner
        }
        
        let queueRunner = QueueRunner(
            name: connection.name,
            mode: connection.mode,
            qos: connection.qos
        )
        
        Self.queueRegistry[connection] = queueRunner
        
        return queueRunner
    }()
        
    let connection: Connection
    
    init(_ connection: Connection = .default) {
        self.connection = connection
    }
    
    deinit {
        Self.queueRegistry.removeValue(forKey: connection)
    }
    
    public func dispatch<J: Job>(_ job: J) -> QueuedJob {
        queueRunner.dispatch(job)
    }
    
    public func run() {
        queueRunner.run()
    }
    
    public static func register(_ job: Job.Type) {
        guard jobRegistry["\(job.self)"] == nil else {
            print("Henry: Job already registered - \(job.self)")
            return
        }
        
        jobRegistry["\(job.self)"] = job
    }
    
    public static func register(_ jobs: [Job.Type]) {
        jobs.forEach({ Self.register($0) })
    }
    
    public struct Connection: Hashable, CustomStringConvertible {
        
        public static let `default` = Connection("io.aplr.henry.default")
        
        public let name: String
        public let mode: Queue.Mode
        public let qos: Queue.Qos
        
        init(_ name: String, mode: Queue.Mode = .serial, qos: Queue.Qos = .default) {
            self.name = name
            self.mode = mode
            self.qos = qos
        }
        
        public var description: String {
            "\(name), mode: \(mode), qos: \(qos)"
        }
        
        public func hash(into hasher: inout Hasher) {
            // Only hash by name, since different mode / qos
            // configurations should not result in multiple runners.
            hasher.combine(name)
        }
    }
    
    public enum Mode: Hashable {
        case serial
        case blocking
        case concurrent(max: Int = 0)
        
        var maxConcurrentOperationCount: Int {
            switch self {
            case let .concurrent(max: max): return max > 0 ? max : OperationQueue.defaultMaxConcurrentOperationCount
            case .serial, .blocking: return 1
            }
        }
    }
    
    public enum Qos: Hashable {
        case high
        case `default`
        case background
        
        var operationQos: QualityOfService {
            switch self {
            case .high: return .userInitiated
            case .`default`: return .`default`
            case .background: return .background
            }
        }
    }
}
