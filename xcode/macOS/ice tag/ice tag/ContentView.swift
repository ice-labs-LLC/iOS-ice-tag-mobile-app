import SwiftUI
import WebKit

struct webview: NSViewRepresentable {
    let url: URL
    let isdarkmode: Bool
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let injectCSS: (WKWebView) -> Void
        
        init(injectCSS: @escaping (WKWebView) -> Void) {
            self.injectCSS = injectCSS
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            injectCSS(webView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let css = """
        @font-face {
            font-family: 'SF Pro';
            src: local('SF Pro'), local('SF Pro Display'), local('SF Pro Text');
            font-weight: 400 900;
            font-style: normal;
        }
        html {
            background-color: \(isdarkmode ? "rgba(20, 20, 20, 0.2)" : "rgba(255, 255, 255, 0.2)") !important;
        }
        body, * {
            background: transparent !important;
            background-color: transparent !important;
        }
        button, a, input, span, div, p, h1, h2, h3, h4, h5, h6, li, ul, ol, table, tr, td, th {
            font-family: 'SF Pro', -apple-system, "SF Pro Display", "SF Pro Text", sans-serif !important;
            font-weight: 700 !important;
            font-style: normal !important;
            font-variant: normal !important;
            color: \(isdarkmode ? "#FFFFFF" : "#000000") !important;
            -webkit-text-fill-color: \(isdarkmode ? "#FFFFFF" : "#000000") !important;
        }
        """
        
        let script = """
        const css = `\(css)`;
        let count = 0;
        const styleId = 'f';
        function injectSFPro() {
            let s = document.getElementById(styleId);
            if(!s){
                s=document.createElement('style');
                s.id=styleId;
                document.head.appendChild(s);
            }
            s.innerHTML = css;
        }
        const interval = setInterval(injectSFPro, 200);
        setTimeout(() => clearInterval(interval), 2000);
        injectSFPro();
        """
        
        return Coordinator { webView in
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.setValue(false, forKey: "drawsBackground")
        wv.navigationDelegate = context.coordinator
        return wv
    }
    
    func updateNSView(_ nsview: WKWebView, context: Context) {
        if nsview.url != url { nsview.load(URLRequest(url: url)) }
    }
}

struct ContentView: View {
    @AppStorage("usesystemsettings") private var usesystemsettings = true
    @AppStorage("appearancemode") private var appearancemode = "light"
    @Environment(\.colorScheme) var systemscheme
    @State private var currenturl = URL(string: "https://sites.google.com/view/icelabs/home")!

    var isdark: Bool {
        usesystemsettings ? (systemscheme == .dark) : (appearancemode == "dark")
    }

    let sites: [(String, String)] = [
        ("Home", "https://sites.google.com/view/icelabs/home"),
        ("Mods", "https://sites.google.com/view/icelabs/mods"),
        ("TOS", "https://sites.google.com/view/icelabs/terms-of-service"),
        ("Privacy Policy", "https://sites.google.com/view/icelabs/privacy-policy"),
        ("System Requirements", "https://sites.google.com/view/icelabs/ice-tag-system-requirements"),
        ("Submit A Mod", "https://forms.gle/aWVrD8SiwuLpYHUr8"),
        ("itch", "https://jackww51.itch.io/iceygame"),
        ("GRAB Level", "https://grabvr.quest/levels/viewer/?level=2dahfrbinl80vn8h8u754:1725132872"),
        ("Blog", "https://sites.google.com/view/icelabs/blog")
    ]

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [.red, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    GlassEffectContainer {
                        HStack(spacing: 12) {
                            ForEach(sites, id: \.0) { name, link in
                                Button(action: {
                                    if let ur = URL(string: link) { currenturl = ur }
                                }) {
                                    Text(name)
                                        // Using .system design ensures SwiftUI uses SF Pro
                                        .font(.system(size: 13, weight: .black, design: .default))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 18)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                        .padding(20)
                    }
                }
                
                webview(url: currenturl, isdarkmode: isdark)
                    .ignoresSafeArea()
            }
        }
    }
}
