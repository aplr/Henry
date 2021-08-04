//
//  BackgroundUtils.swift
//  Henry
//
//  Created by Andreas Pfurtscheller on 04.08.21.
//

#if canImport(UIKit)
import UIKit

typealias BackgroundTaskIdentifier = UIBackgroundTaskIdentifier

extension UIApplication {
    static var safeShared: Self? {
        Self.value(forKeyPath: #keyPath(UIApplication.shared)) as? Self
    }
}
#else
typealias BackgroundTaskIdentifier = Int
#endif

func beginBackgroundTask(expirationHandler: (() -> Void)? = nil) -> BackgroundTaskIdentifier? {
    #if canImport(UIKit)
    return UIApplication.safeShared?.beginBackgroundTask(expirationHandler: expirationHandler)
    #else
    return nil
    #endif
}

func endBackgroundTask(identifier: BackgroundTaskIdentifier) {
    #if canImport(UIKit)
    UIApplication.safeShared?.endBackgroundTask(identifier)
    #endif
}
