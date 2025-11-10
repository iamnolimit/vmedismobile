// File: Views/Pages/RegisterWebView.swift - WebView untuk halaman register
import SwiftUI
import WebKit

struct RegisterWebView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let registerURL = "https://bit.ly/demovmedis"
    private let accentColor = Color.blue
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header dengan progress bar
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Kembali")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(accentColor)
                        }
                        
                        Spacer()
                        
                        Text("Daftar Akun")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Placeholder untuk balance layout
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Kembali")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider()
                }
                .background(Color(UIColor.systemBackground))
                
                // WebView
                WebViewContainer(url: registerURL)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - WebView Container
struct WebViewContainer: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // Optional: Handle navigation events
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("📱 Started loading: \(webView.url?.absoluteString ?? "")")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Finished loading: \(webView.url?.absoluteString ?? "")")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Failed to load: \(error.localizedDescription)")
        }
    }
}

#Preview {
    RegisterWebView()
}
