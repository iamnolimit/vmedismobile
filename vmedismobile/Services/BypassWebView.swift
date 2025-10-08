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
                            let fallbackUrl = URL(string: "https://v3.vmedismart.com/vmart/\(destinationUrl)")!
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
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }        }
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
        isLoading = true
        errorMessage = nil
        bypassUrl = nil
        // Don't reset retry count on refresh, only on fresh load
        
        print("Loading bypass URL for: \(destinationUrl)")
        
        Task {
            do {
                let url = try await BypassLoginService.shared.generateTokenUrl(
                    userData: userData,
                    destinationUrl: destinationUrl
                )
                
                await MainActor.run {
                    self.bypassUrl = url
                    self.isLoading = false
                    print("✅ Successfully loaded bypass URL: \(url)")
                }
            } catch {
                await MainActor.run {
                    retryCount += 1
                    let errorMsg = "Authentication setup failed (\(retryCount)/\(maxRetries))"
                    self.errorMessage = errorMsg
                    self.isLoading = false
                    print("❌ Bypass login error (attempt \(retryCount)): \(error)")
                    
                    // Auto-retry for first few attempts
                    if retryCount < maxRetries {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self.errorMessage == errorMsg { // Only retry if error hasn't changed
                                loadBypassUrl()
                            }
                        }
                    } else {
                        // Final fallback
                        print("⚠️ Max retries reached, using fallback URL")
                        let fallbackUrl = URL(string: "https://v3.vmedismart.com/vmart/\(destinationUrl)")!
                        self.bypassUrl = fallbackUrl
                        self.errorMessage = nil
                    }
                }
            }
        }
    }
}
