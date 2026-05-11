import SwiftUI
import AppKit // For NSApplicationDelegate
import StabilityFramework // This should now resolve!

// Restore the @main attribute to designate this struct as the application's entry point.
@main
struct ice_tag_app: App {
    // Adapt an NSObject-based AppDelegate to handle application lifecycle events.
    @NSApplicationDelegateAdaptor(AppLifecycleHandler.self) var appDelegate

    @Environment(\.openWindow) private var openWindow
    @AppStorage("usesystemsettings") private var usesystemsettings = true
    @AppStorage("appearancemode") private var appearancemode = "light"
    
    @AppStorage("accentcolor") private var accentColorData: Data = try! NSKeyedArchiver.archivedData(withRootObject: NSColor.systemBlue, requiringSecureCoding: false)
    
    var accentColor: Color {
        if let nsColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(accentColorData) as? NSColor {
            return Color(nsColor)
        }
        return .blue
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .accentColor(accentColor)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(action: { openWindow(id: "info") }) {
                    Label("About ice tag", systemImage: "info.circle")
                }
            }
        }

        Window("About ice tag", id: "info") {
            InfoView() // Assuming InfoView is defined elsewhere.
        }
        .windowResizability(.contentSize)
    }
}

// Custom AppDelegate to handle application lifecycle events and integrate StabilityMonitor.
class AppLifecycleHandler: NSObject, NSApplicationDelegate {
    // !!! IMPORTANT: Change "com.yourcompany.StabilityHelperApp" to your helper application's actual Bundle Identifier.
    private let helperAppBundleIdentifier = "com.icelabsLLC.StabilityHelperApp"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Step 1: Check if the previous launch was an unclean shutdown using StabilityMonitor.
        let previousLaunchCrashed = StabilityMonitor.shared.checkAndMarkLaunch()

        // Step 2: If a crash was detected, launch the helper app to show the restart dialog.
        if previousLaunchCrashed {
            launchHelperAppForDialog()
        }
        // If not crashed, the main app continues its normal startup.
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Step 3: Mark a clean shutdown when the application exits gracefully.
        StabilityMonitor.shared.markCleanShutdown()
    }

    private func launchHelperAppForDialog() {
        // Attempt to find and launch the helper application.
        if let helperAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: helperAppBundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.arguments = ["--show-restart-dialog"] // Pass argument to tell helper to show dialog.
            config.activates = true // Bring the helper app to the front so its dialog is visible.
            
            NSWorkspace.shared.openApplication(at: helperAppURL, configuration: config) { app, error in
                if let error = error {
                    print("Error launching helper application: \(error.localizedDescription)")
                } else if let app = app {
                    print("Helper application launched successfully: \(app.bundleIdentifier ?? "Unknown")")
                }
            }
        } else {
            print("ERROR: Could not find helper application with bundle identifier: \(helperAppBundleIdentifier). Cannot show restart dialog.")
            // Fallback: If the helper cannot be found, display a simple in-app alert.
            let alert = NSAlert()
            alert.messageText = "Application Problem"
            alert.informativeText = "The application 'ice tag' terminated unexpectedly during its previous run. Please restart the application manually."
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
}
