// File: Services/BypassWebView.swift
import SwiftUI
import WebKit

struct BypassWebView: UIViewRepresentable {
    let userData: UserData
    let destinationUrl: String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Disable text selection
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Inject CSS to disable text selection
        let css = """
        * {
            -webkit-user-select: none;
            -webkit-touch-callout: none;
            user-select: none;
        }
        """
        
        let cssString = "var style = document.createElement('style'); style.innerHTML = '\(css)'; document.head.appendChild(style);"
        let userScript = WKUserScript(source: cssString, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Add pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        webView.scrollView.bounces = true
        
        loadBypassUrl(webView: webView)
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: BypassWebView
        
        init(_ parent: BypassWebView) {
            self.parent = parent
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            // Reload the current page
            if let webView = refreshControl.superview?.superview as? WKWebView {
                webView.reload()
                
                // Stop refresh animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    refreshControl.endRefreshing()
                }
            }
        }
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Handle updates if needed
    }
    
    private func loadBypassUrl(webView: WKWebView) {
        Task {
            do {
                let bypassUrl = try await BypassLoginService.shared.generateTokenUrl(
                    userData: userData,
                    destinationUrl: destinationUrl
                )
                
                await MainActor.run {
                    let request = URLRequest(url: bypassUrl)
                    webView.load(request)
                }            } catch {
                print("Error generating bypass URL: \(error)")
                await MainActor.run {
                    // Fallback to original URL with dynamic domain
                    let domain = userData.domain ?? "vmart"
                    let fallbackUrl = URL(string: "https://v3.vmedis.com/\(domain)/\(destinationUrl)")!
                    let request = URLRequest(url: fallbackUrl)
                    webView.load(request)
                }
            }
        }
    }
}

// MARK: - Loading WebView with Error Handling
struct LoadingBypassWebView: View {
    let userData: UserData
    let destinationUrl: String
    @State private var bypassUrl: URL?
    @State private var errorMessage: String?
    @State private var retryCount = 0
    
    private let maxRetries = 2
      var body: some View {
        Group {
            if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Connection Issue")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(retryCount >= maxRetries ? "Loading with standard authentication..." : error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if retryCount < maxRetries {
                        Button("Retry") {
                            loadBypassUrl()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    } else {
                        // Final fallback after max retries
                        Button("Continue with Standard Login") {
                            let domain = userData.domain ?? "vmart"
                            let fallbackUrl = URL(string: "https://v3.vmedis.com/\(domain)/\(destinationUrl)")!
                            self.bypassUrl = fallbackUrl
                            self.errorMessage = nil
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            } else if let url = bypassUrl {
                WebView(url: url)
            } else {
                // Empty placeholder while waiting for URL (web handles loading)
                Color.white
            }
        }
        .onAppear {
            print("LoadingBypassWebView appeared with URL: \(destinationUrl)")
            loadBypassUrl()
        }
        .onChange(of: userData.id) { _ in
            // Refresh WebView when userData changes (after login)
            print("UserData changed, reloading...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadBypassUrl()
            }
        }
    }
      private func loadBypassUrl() {
        errorMessage = nil
        bypassUrl = nil
        
        print("Loading bypass URL for: \(destinationUrl)")
        
        Task {
            do {
                let url = try await BypassLoginService.shared.generateTokenUrl(
                    userData: userData,
                    destinationUrl: destinationUrl
                )
                
                await MainActor.run {
                    self.bypassUrl = url
                    print("✅ Successfully loaded bypass URL: \(url)")
                }
            } catch {
                await MainActor.run {
                    retryCount += 1
                    let errorMsg = "Authentication setup failed (\(retryCount)/\(maxRetries))"
                    self.errorMessage = errorMsg
                    print("❌ Bypass login error (attempt \(retryCount)): \(error)")
                    
                    // Auto-retry for first few attempts
                    if retryCount < maxRetries {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self.errorMessage == errorMsg { // Only retry if error hasn't changed
                                loadBypassUrl()
                            }
                        }                    } else {
                        // Final fallback
                        print("⚠️ Max retries reached, using fallback URL")
                        let domain = userData.domain ?? "vmart"
                        let fallbackUrl = URL(string: "https://v3.vmedis.com/\(domain)/\(destinationUrl)")!
                        self.bypassUrl = fallbackUrl
                        self.errorMessage = nil
                    }
                }
            }
        }
    }
}
