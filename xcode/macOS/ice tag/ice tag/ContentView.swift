import SwiftUI
import WebKit
import AppKit // For NSWindow, NSHostingView, NSWindowDelegate etc.

// Global function to restart the application.
// This is a workaround for persistent WKWebView cleanup issues.
func restartApplication() {
    print("Attempting to restart application...")
    let task = Process()
    task.launchPath = "/bin/bash"
    // This command finds the path to the current application bundle and relaunches it.
    let script = """
        open -a \"\(Bundle.main.bundlePath)\"
        exit 0
        """
    task.arguments = ["-c", script]

    do {
        try task.run()
        // Give the new instance a moment to launch before terminating the current one.
        Thread.sleep(forTimeInterval: 0.5)
        exit(0) // Terminate the current application process
    } catch {
        print("Failed to restart application: \(error)")
        // If relaunch fails, at least terminate to avoid a hanging app.
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main WebView Structure (for ContentView)

// Define a new NSViewRepresentable struct for WKWebView used in the main ContentView
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: createWebViewConfiguration())
        webView.navigationDelegate = context.coordinator // Set navigation delegate
        webView.uiDelegate = context.coordinator         // Set UI delegate for new window creation
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only load the URL if it has changed to avoid unnecessary reloads
        if nsView.url != url {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func createWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        // WKWebView generally respects system settings for dark mode.
        return config
    }

    // Coordinator for the MAIN WebView.
    // Its primary role is to handle requests to create new windows.
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: WebView
        // Hold strong references to the NSWindow *and* its dedicated DynamicWebView.Coordinator.
        // This ensures both the window and its delegate remain alive as long as the main app tracks them.
        var trackedWindows: [(NSWindow, DynamicWebView.Coordinator)] = []

        init(parent: WebView) {
            self.parent = parent
            super.init() // Call super.init() after setting all properties
        }
        
        deinit {
            print("Main WebView Coordinator deallocated.")
            // Explicitly close any remaining windows to ensure proper cleanup by their dedicated coordinators.
            // This will trigger windowWillClose on the sub-coordinator, potentially leading to a restart.
            for (window, _) in trackedWindows {
                if window.isVisible {
                    window.close()
                }
            }
            trackedWindows.removeAll()
        }

        // MARK: - WKUIDelegate for creating new windows

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Open in External Browser?"
                alert.informativeText = "Do you want to open this link in your default web browser?\n\n\(url.absoluteString)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(url)
                }
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

// MARK: - Dynamic WebView Structure (for popup windows)

// This NSViewRepresentable will manage a single WKWebView that is passed to it.
struct DynamicWebView: NSViewRepresentable {
    let webView: WKWebView // The WKWebView instance is passed in

    // The init now simply takes the pre-configured WKWebView
    init(webView: WKWebView) {
        self.webView = webView
    }

    func makeNSView(context: Context) -> WKWebView {
        // The webView's delegates should already be set in the main Coordinator's createWebViewWith.
        // We're just returning the pre-configured webView here.
        // Ensure its delegates are still correctly pointing to this context's coordinator,
        // which should be the *same* instance passed in via newWindow.delegate.
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No update logic needed here; the webView instance is external and handles its own loading.
    }

    func makeCoordinator() -> Coordinator {
        // This coordinator is created ONCE per DynamicWebView instance by SwiftUI.
        // It will manage the passed-in webView and will act as NSWindowDelegate for its containing window.
        // This coordinator instance should be the *same* as the one set as newWindow.delegate
        // in the main WebView.Coordinator.
        Coordinator(webView: webView)
    }

    // Coordinator for EACH DynamicWebView instance.
    // It manages the lifecycle of its OWN WKWebView and the NSWindow it's in.
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, NSWindowDelegate {
        let webView: WKWebView // The specific WKWebView this coordinator manages
        weak var myWindow: NSWindow? // Weak reference to the window this coordinator manages

        init(webView: WKWebView) {
            self.webView = webView
            super.init()
        }

        func set(window: NSWindow) {
            self.myWindow = window
        }

        deinit {
            print("Dynamic WebView Coordinator deallocated for window: \(myWindow?.title ?? "Untitled")")
        }

        // MARK: - WKUIDelegate (for nested popups within the dynamic window)
        // If the popup tries to open another popup, this coordinator will handle it.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Open in External Browser?"
                alert.informativeText = "Do you want to open this link in your default web browser?\n\n\(url.absoluteString)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(url)
                }
            }
            return nil
        }

        // MARK: - NSWindowDelegate (for closing this specific window)
        func windowWillClose(_ notification: Notification) {
            DispatchQueue.main.async {
                guard let closedWindow = notification.object as? NSWindow, closedWindow == self.myWindow else {
                    return
                }

                // --- AGGRESSIVE CLEANUP SEQUENCE FOR THIS SPECIFIC WKWEBVIEW ---
                
                // 1. Immediately navigate to a blank page to halt any active content (JS, media).
                self.webView.load(URLRequest(url: URL(string: "about:blank")!))
                
                // 2. Stop any ongoing loading.
                self.webView.stopLoading()
                
                // 3. Clear its delegates to break any potential callback paths from WebKit.
                self.webView.navigationDelegate = nil
                self.webView.uiDelegate = nil
                
                // 4. Remove the webView from its view hierarchy.
                if self.webView.superview != nil {
                    self.webView.removeFromSuperview()
                }
                
                // 5. Disconnect the window's content view to ensure the NSHostingView is released.
                closedWindow.contentView = nil
                
                // 6. Explicitly clear the window's delegate. This breaks the strong reference cycle
                //    between the NSWindow and this Coordinator, allowing both to deallocate.
                closedWindow.delegate = nil
                
                // 7. Clear weak reference to the window. The window will now be deallocated.
                self.myWindow = nil

                print("Window closed and released: \(closedWindow.title ?? "Untitled") - AGGRESSIVE CLEANUP PERFORMED by its dedicated Coordinator.")
                
                // 8. Trigger application restart as a last resort to prevent freezes.
                // Commented out to prevent the entire application from quitting when an extra window is closed.
                // restartApplication()
            }
        }
    }
}

// MARK: - ContentView and Supporting Styles

struct ContentView: View {
    @AppStorage("usesystemsettings") private var usesystemsettings = true
    @AppStorage("appearancemode") private var appearancemode = "light"
    @Environment(\.colorScheme) var systemscheme
    @State private var currenturl = URL(string: "https://ice-labs-llc.github.io/index.html")!

    var isdark: Bool {
        usesystemsettings ? (systemscheme == .dark) : (appearancemode == "dark")
    }

    let sites: [(String, String)] = [
        ("Home", "https://ice-labs-llc.github.io/index.html"),
        ("Mods", "https://ice-labs-llc.github.io/mods.html"),
        ("TOS", "https://ice-labs-llc.github.io/terms.html"),
        ("Privacy Policy", "https://ice-labs-llc.github.io/privacy.html"),
        ("System Requirements", "https://ice-labs-llc.github.io/sysreq.html"),
        ("Submit A Mod", "https://forms.gle/aWVrD8SiwuLpYHUr8"),
        ("itch", "https://jackww51.itch.io/iceygame"),
        ("GRAB Level", "https://grabvr.quest/levels/viewer/?level=2dahfrbinl80vn8h8u754:1725132872"),
        ("Blog", "https://ice-labs-llc.github.io/blog.html"),
        ("Status", "https://icetag.statuspage.io")
    ]

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [.red, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    GlassEffectContainer { // Assuming GlassEffectContainer is defined correctly elsewhere
                        HStack(spacing: 12) {
                            ForEach(sites, id: \.0) { name, link in
                                Button(action: {
                                    if let ur = URL(string: link) { currenturl = ur }
                                }) {
                                    Text(name)
                                        .font(.system(size: 13, weight: .black, design: .default))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 18)
                                }
                                // FIX: Explicitly use the GlassButtonStyle instance
                                .buttonStyle(GlassButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
                
                WebView(url: currenturl)
                    .ignoresSafeArea()
            }
        }
    }
}

// Placeholder for GlassEffectContainer if it's not defined elsewhere in your project
// If you have this defined, you can remove this placeholder.
struct GlassEffectContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .background(.thinMaterial)
                    .cornerRadius(12)
            )
    }
}

// Make sure this struct and extension are in a file included in your target.
// For example, you could put this in a file named GlassStyles.swift
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                    .background(.thinMaterial)
                    .cornerRadius(10)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// The extension that provides the static .glass accessor.
// This should be defined in the same file as GlassButtonStyle or be accessible.
extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }
}
