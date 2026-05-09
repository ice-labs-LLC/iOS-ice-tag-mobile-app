import SwiftUI

// Restore the @main attribute to designate this struct as the application's entry point.
@main
struct ice_tag_app: App {
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
            // This line correctly references InfoView, assuming it's defined elsewhere.
            InfoView()
        }
        .windowResizability(.contentSize)
    }
}

// REMOVED: The redundant definition of InfoView.
// Ensure InfoView is defined in its own separate file (e.g., InfoView.swift)
// and is included in your target's build phases.

