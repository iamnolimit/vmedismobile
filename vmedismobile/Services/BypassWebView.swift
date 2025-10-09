// File: Services/BypassWebView.swift
import SwiftUI
import WebKit

struct BypassWebView: UIViewRepresentable {
    let userData: UserData
    let destinationUrl: String
    
    func makeUIView(context: Context) -> WKWebView {
        // Optimize WKWebView configuration for iOS 16+
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        
        // Lightweight preferences
        let preferences = WKWebpreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = preferences
        
        // iOS 16+ optimizations
        if #available(iOS 16.0, *) {
            config.preferences.isElementFullscreenEnabled = false
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = false
        
        // Inject CSS to disable text selection (lightweight)
        let css = "* { -webkit-user-select: none; -webkit-touch-callout: none; user-select: none; }"
        let cssScript = "var s=document.createElement('style');s.innerHTML='\(css)';document.head.appendChild(s);"
        let userScript = WKUserScript(source: cssScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Add pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        context.coordinator.refreshControl = refreshControl
        
        // Store webView reference
        context.coordinator.webView = webView
        
        // Load URL
        context.coordinator.loadBypassUrl()
        
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject {
        var parent: BypassWebView
        weak var webView: WKWebView?
        weak var refreshControl: UIRefreshControl?
        var loadTask: Task<Void, Never>?
        
        init(parent: BypassWebView) {
            self.parent = parent
        }
        
        deinit {
            // Cancel any ongoing tasks
            loadTask?.cancel()
            webView?.configuration.userContentController.removeAllUserScripts()
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                refreshControl.endRefreshing()
            }
        }
        
        func loadBypassUrl() {
            // Cancel previous task
            loadTask?.cancel()
            
            loadTask = Task { @MainActor in
                do {
                    let bypassUrl = try await BypassLoginService.shared.generateTokenUrl(
                        userData: parent.userData,
                        destinationUrl: parent.destinationUrl
                    )
                    
                    guard !Task.isCancelled else { return }
                    
                    var request = URLRequest(url: bypassUrl)
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    request.timeoutInterval = 30
                    
                    webView?.load(request)
                    
                } catch {
                    guard !Task.isCancelled else { return }
                    
                    print("⚠️ Bypass error, using fallback: \(error)")
                    let domain = parent.userData.domain ?? "vmart"
                    if let fallbackUrl = URL(string: "https://v3.vmedis.com/\(domain)/\(parent.destinationUrl)") {
                        var request = URLRequest(url: fallbackUrl)
                        request.cachePolicy = .reloadIgnoringLocalCacheData
                        request.timeoutInterval = 30
                        
                        webView?.load(request)
                    }
                }
            }
        }
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only reload if URL changed
        if let currentUrl = uiView.url?.absoluteString,
           !currentUrl.contains(destinationUrl) {
            context.coordinator.loadBypassUrl()
        }
    }
}

// MARK: - Lightweight Loading WebView
struct LoadingBypassWebView: View {
    let userData: UserData
    let destinationUrl: String
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            // WebView loads immediately
            BypassWebView(userData: userData, destinationUrl: destinationUrl)
                .opacity(isLoaded ? 1 : 0)
                .onAppear {
                    // Quick fade in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeIn(duration: 0.2)) {
                            isLoaded = true
                        }
                    }
                }
            
            // Minimal loading indicator
            if !isLoaded {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
    }
}
