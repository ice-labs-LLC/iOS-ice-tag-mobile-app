import SwiftUI
import AppKit
import StabilityFramework // Import the framework we just created

@main
struct StabilityHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The helper app's UI is just an NSAlert, so we use an empty, tiny view for the window.
        // The WindowGroup is a Scene, and it contains the EmptyView.
        WindowGroup {
            EmptyView()
                .frame(width: 1, height: 1) // Make the window almost invisible
                .hidden() // Hide it completely
        }
        .windowResizability(.contentSize) // This modifier is applied correctly to the WindowGroup scene
    }

    class AppDelegate: NSObject, NSApplicationDelegate {
        // !!! IMPORTANT: Change "com.yourcompany.icetag" to your main application's actual Bundle Identifier.
        // This must be a String literal for NSWorkspace.shared.urlForApplication to work correctly.
        private let mainAppBundleIdentifier = "com.icelabsLLC.icetag" // <--- UPDATE THIS TO YOUR MAIN APP'S BUNDLE ID

        func applicationDidFinishLaunching(_ notification: Notification) {
            // Check if the helper app was launched with the specific argument to show the dialog.
            let args = ProcessInfo.processInfo.arguments // Corrected 'processinfo' to 'processInfo'
            if args.contains("--show-restart-dialog") {
                showRestartDialog()
            } else {
                // If the helper app was launched without the specific argument, it means it's not needed.
                // Terminate it immediately to prevent it from lingering.
                NSApp.terminate(self)
            }
        }

        private func showRestartDialog() {
            let alert = NSAlert()
            alert.messageText = "Application Problem Detected"
            alert.informativeText = "The application 'ice tag' terminated unexpectedly during its previous run. Would you like to restart it?"
            alert.alertStyle = .critical // Use critical style for a problem alert
            alert.addButton(withTitle: "Restart Application")
            alert.addButton(withTitle: "Quit")

            // Display the alert and wait for user interaction.
            let response = alert.runModal()

            if response == .alertFirstButtonReturn { // The "Restart Application" button was clicked.
                restartMainApplication()
                // If you want the helper app to stay open after restarting the main app,
                // you would remove NSApp.terminate(self) here.
                // For a typical helper app, terminating here is usually desired as its job is done.
                NSApp.terminate(self)
            } else if response == .alertSecondButtonReturn { // The "Quit" button was clicked.
                // Only quit the helper app if the user explicitly chose to "Quit".
                NSApp.terminate(self)
            }
            // Removed the unconditional NSApp.terminate(self) that was previously here.
            // Now, if "Restart Application" is chosen, the helper app will terminate,
            // otherwise, if "Quit" is chosen, it also terminates. This restores the
            // original behavior of always terminating but makes the intent clearer.
            // If you truly want it to stay open after "Restart Application", remove the NSApp.terminate(self)
            // inside the `if response == .alertFirstButtonReturn` block.
        }

        private func restartMainApplication() {
            // Find the URL for the main application using its Bundle Identifier.
            if let mainAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppBundleIdentifier) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true // Bring the restarted main app to the front.
                
                NSWorkspace.shared.openApplication(at: mainAppURL, configuration: config) { app, error in
                    if let error = error {
                        print("Error launching main application: \(error.localizedDescription)")
                    } else if let app = app {
                        print("Main application relaunched: \(app.bundleIdentifier ?? "Unknown")")
                    }
                }
            } else {
                print("ERROR: Could not find main application with bundle identifier: \(mainAppBundleIdentifier). Unable to restart.")
                let errorAlert = NSAlert()
                errorAlert.messageText = "Restart Failed"
                errorAlert.informativeText = "Could not find the main application to restart. Please try launching it manually."
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
            }
        }
    }
} // Added the missing closing brace for StabilityHelperApp
