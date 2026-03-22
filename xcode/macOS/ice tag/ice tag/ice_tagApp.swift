import SwiftUI

@main
struct IceTagApp: App {
    // 1. This "Action" lets us open the new window by its name (ID)
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // 2. This part swaps the "Boring" About button for your "Cool" one
            CommandGroup(replacing: .appInfo) {
                Button("About ice tag") {
                    openWindow(id: "about")
                }
            }
        }

        // 3. This tells Xcode that your "InfoView" is a special "About" window
        Window("About ice tag", id: "about") {
            InfoView()
        }
        .windowResizability(.contentSize) // Keeps it from being stretched
        .restorationBehavior(.disabled)   // Won't pop up again if you quit the app
    }
}
