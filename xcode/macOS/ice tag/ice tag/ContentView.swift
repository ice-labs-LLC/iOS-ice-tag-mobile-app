import SwiftUI
import WebKit

// Define a new NSViewRepresentable struct for WKWebView
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: createWebViewConfiguration())
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only load the URL if it has changed to avoid unnecessary reloads
        let request = URLRequest(url: url)
        nsView.load(request)
    }

    private func createWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        // WKWebView generally respects system settings for dark mode.
        return config
    }
}

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
        ("Blog", "https://ice-labs-llc.github.io/blog.html")
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
