//
//  WebView.swift
//  vmedismobile
//
//  Created by user283187 on 9/4/25.
//


import SwiftUIimport WebKit// MARK: - WebView Representablestruct WebView: UIViewRepresentable {    let url: URL    func makeUIView(context: Context) -> WKWebView {        let webView = WKWebView()        let request = URLRequest(url: url)        webView.load(request)        return webView    }    func updateUIView(_ uiView: WKWebView, context: Context) {        // optional: bisa reload / handle state di sini    }}