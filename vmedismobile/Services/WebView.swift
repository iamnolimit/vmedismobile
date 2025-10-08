//
//  WebView.swift
//  vmedismobile
//
//  Created by user283187 on 9/4/25.
//


import SwiftUI
import WebKit

// MARK: - WebView Representable
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Disable text selection
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
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: WebView
        
        init(_ parent: WebView) {
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
        // optional: bisa reload / handle state di sini
    }
}