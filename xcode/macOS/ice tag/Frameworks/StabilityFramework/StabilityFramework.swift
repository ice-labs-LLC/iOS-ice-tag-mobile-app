//
//  StabilityFramework.swift
//  StabilityFramework
//
//  Created by Jackson Wentworth on 5/10/26.
//

import Foundation
import AppKit // Although StabilityMonitor doesn't directly use AppKit, it's a good practice for macOS frameworks.

// Public class within the framework to monitor application stability.
// Moved here from StabilityMonitor.swift to ensure direct inclusion in the framework's main module file.
public class StabilityMonitor {
    public static let shared = StabilityMonitor()

    // !!! IMPORTANT: Change "group.com.yourcompany.StabilityMonitor" to your actual App Group ID.
    // This App Group ID must be enabled for both your main app and the helper app in Xcode.
    private let suiteName = "group.com.icelabsLLC.StabilityMonitor"
    private var userDefaults: UserDefaults!

    // Keys for storing state in UserDefaults.
    private let appStartedKey = "appStarted"       // True if app successfully started its last run
    private let cleanShutdownKey = "cleanShutdown" // True if app exited gracefully last run

    private init() {
        // Attempt to initialize UserDefaults with the shared App Group suite.
        if let defaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = defaults
        } else {
            // Fallback for cases where App Group might not be properly configured (e.g., during initial setup).
            print("WARNING: Could not initialize UserDefaults with suiteName: \(suiteName). Stability monitoring will not work cross-process. Please configure App Groups correctly.")
            self.userDefaults = .standard // Fallback to standard defaults (not shared)
        }
    }

    /// Call this very early in your application's lifecycle (e.g., `applicationDidFinishLaunching`).
    /// It checks the status of the *previous* launch and then marks the *current* application as having started.
    ///
    /// - Returns: `true` if the previous launch was an unclean shutdown (i.e., the app crashed), `false` otherwise.
    public func checkAndMarkLaunch() -> Bool {
        // Retrieve the state from the *previous* run.
        let wasCleanlyShutdown = userDefaults.bool(forKey: cleanShutdownKey)
        let didAppStartSuccessfully = userDefaults.bool(forKey: appStartedKey)

        // Reset the flags for the *current* run:
        // Assume an unclean shutdown initially, until `markCleanShutdown()` is called.
        userDefaults.set(false, forKey: cleanShutdownKey)
        // Mark that the app has now successfully started.
        userDefaults.set(true, forKey: appStartedKey)
        // Synchronize immediately to ensure the state is saved.
        userDefaults.synchronize()

        // Determine if the previous launch was an unclean shutdown (crash).
        // A crash is detected if the app *successfully started* previously (`didAppStartSuccessfully == true`)
        // but *did not* execute `markCleanShutdown()` (`wasCleanlyShutdown == false`).
        if didAppStartSuccessfully && !wasCleanlyShutdown {
            print("StabilityMonitor: Previous launch was an unclean shutdown (crash detected).")
            return true
        } else {
            print("StabilityMonitor: Previous launch was clean or this is the very first launch.")
            return false
        }
    }

    /// Call this when your application is about to terminate gracefully (e.g., in `applicationWillTerminate`).
    /// It sets a flag indicating that the application is performing a clean exit.
    public func markCleanShutdown() {
        userDefaults.set(true, forKey: cleanShutdownKey) // Mark as cleanly shutdown
        userDefaults.set(false, forKey: appStartedKey)   // App is no longer running
        userDefaults.synchronize()                       // Synchronize immediately
        print("StabilityMonitor: Marked clean shutdown.")
    }
}
