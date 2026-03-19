import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
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
    
    @State private var currentURL = URL(string: "https://www.apple.com")!
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(sites, id: \.0) { name, urlString in
                        Button(action: {
                            if let url = URL(string: urlString) {
                                currentURL = url
                            }
                        }) {
                            Text(name)
                                .font(.system(size: 20, weight: .black))
                                .padding(.vertical, 15)
                                .padding(.horizontal, 20)
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .foregroundColor(.primary)
                                .shadow(color: .black.opacity(0.2), radius: 5)
                        }
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            
            // The Browser Part
            WebView(url: currentURL)
                .ignoresSafeArea(edges: .bottom)
        }
        // Background color helps show the glass effect
        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
    }
}
