import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}

struct ContentView: View {
    let sites = [
        ("Home", "https://sites.google.com/view/icelabs/home"),
        ("Mods", "https://sites.google.com/view/icelabs/mods"),
        ("TOS", "https://sites.google.com/view/icelabs/terms-of-service"),
        ("Privacy Policy", "https://sites.google.com/view/icelabs/privacy-policy"),
        ("System Requirements", "https://sites.google.com/view/icelabs/ice-tag-system-requirements"),
        ("Submit a Mod", "https://forms.gle/aWVrD8SiwuLpYHUr8"),
        ("itch", "https://jackww51.itch.io/iceygame"),
        ("GRAB Level", "https://grabvr.quest/levels/viewer/?level=2dahfrbinl80vn8h8u754:1725132872")
    ]
    
    @State private var currentURL = URL(string: "https://sites.google.com/view/icelabs/home")!
    
    var body: some View {
        ZStack {
            // Updated Liquid Background (Red and Blue)
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .red, .blue, .red,
                .indigo, .purple, .blue,
                .black, .red, .black
            ])
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Glassy Navigation Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(sites, id: \.0) { name, urlString in
                            Button(action: {
                                if let url = URL(string: urlString) {
                                    currentURL = url
                                }
                            }) {
                                Text(name)
                                    .font(.system(size: 14, weight: .black))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                            }
                            .glassEffect(in: .capsule)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(.ultraThinMaterial)
                
                // Bigger Website: Removed padding so it hits the edges
                WebView(url: currentURL)
                    .ignoresSafeArea()
            }
        }
    }
}
