//
//  Henry+Combine.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 30.04.21.
//

#if canImport(Combine)

import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
protocol PublisherJob: Job {
        
    var pipeline: AnyPublisher<Void, Error> { get }
    
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension PublisherJob {
    
    func handle(completion: @escaping (Henry.Result) -> Void) -> JobCancellable {
        let cancellable = pipeline.sink(receiveCompletion: {
            switch $0 {
            case let .failure(error): completion(.failure(error))
            case .finished: completion(.success)
            }
        }, receiveValue: { _ in })
        
        return cancellable.cancel
    }
    
    var pipeline: AnyPublisher<Henry.Result, Henry.Error> {
        Just(.success).setFailureType(to: Henry.Error.self).eraseToAnyPublisher()
    }
}

#endif
