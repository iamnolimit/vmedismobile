//
//  WebView.swift
//  vmedismobile
//
//  Created by user283187 on 9/4/25.
//

import SwiftUI
import WebKit

// MARK: - Optimized WebView for iOS 15.6+
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        // Lightweight configuration
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = false
        
        // Lightweight CSS injection
        let css = "* { -webkit-user-select: none; -webkit-touch-callout: none; user-select: none; }"
        let cssScript = "var s=document.createElement('style');s.innerHTML='\(css)';document.head.appendChild(s);"
        let userScript = WKUserScript(source: cssScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Add pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        context.coordinator.refreshControl = refreshControl
        context.coordinator.webView = webView
        
        // Load with cache policy
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
        
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var webView: WKWebView?
        weak var refreshControl: UIRefreshControl?
        
        deinit {
            webView?.configuration.userContentController.removeAllUserScripts()
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                refreshControl.endRefreshing()
            }
        }
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Avoid unnecessary reloads
    }
}