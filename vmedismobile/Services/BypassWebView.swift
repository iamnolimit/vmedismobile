// File: Services/BypassWebView.swift
import SwiftUI
import WebKit

struct BypassWebView: UIViewRepresentable {
    let userData: UserData
    let destinationUrl: String
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        loadBypassUrl(webView: webView)
        return webView
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
                }
            } catch {
                print("Error generating bypass URL: \(error)")
                await MainActor.run {
                    // Fallback to original URL if bypass fails
                    let fallbackUrl = URL(string: "https://v3.vmedismart.com/vmart/\(destinationUrl)")!
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
    @State private var isLoading = true
    @State private var bypassUrl: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Preparing secure access...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            } else if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Connection Error")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Retry") {
                        loadBypassUrl()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if let url = bypassUrl {
                WebView(url: url)
            } else {
                // Fallback to original WebView
                WebView(url: URL(string: "https://v3.vmedismart.com/vmart/\(destinationUrl)")!)
            }
        }
        .onAppear {
            loadBypassUrl()
        }
    }
    
    private func loadBypassUrl() {
        isLoading = true
        errorMessage = nil
        bypassUrl = nil
        
        Task {
            do {
                let url = try await BypassLoginService.shared.generateTokenUrl(
                    userData: userData,
                    destinationUrl: destinationUrl
                )
                
                await MainActor.run {
                    self.bypassUrl = url
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate secure access token"
                    self.isLoading = false
                    print("Bypass login error: \(error)")
                }
            }
        }
    }
}
