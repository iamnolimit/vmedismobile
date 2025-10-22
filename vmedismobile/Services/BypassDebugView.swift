// File: Services/BypassDebugView.swift
import SwiftUI

struct BypassDebugView: View {
    let userData: UserData
    @State private var debugInfo: String = "Starting bypass test..."
    @State private var generatedUrl: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Bypass Login Debug")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // User Data Summary                VStack(alignment: .leading, spacing: 8) {
                    Text("User Data:")
                        .font(.headline)
                    
                    Text("ID: \(userData.id ?? "N/A")")
                    Text("Username: \(userData.username ?? "N/A")")
                    Text("Domain: \(userData.domain ?? "N/A")")
                    Text("Klinik: \(userData.kl_nama ?? "N/A")")
                    Text("Level: \(userData.lvl ?? 0)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Debug Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug Log:")
                        .font(.headline)
                    
                    Text(debugInfo)
                        .font(.caption)
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Generated URL
                if !generatedUrl.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated URL:")
                            .font(.headline)
                        
                        Text(generatedUrl)
                            .font(.caption)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Test Button
                Button("Test Bypass Generation") {
                    testBypass()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func testBypass() {
        debugInfo = "Testing bypass URL generation...\n"
        generatedUrl = ""
        
        Task {
            do {
                let url = try await BypassLoginService.shared.generateTokenUrl(
                    userData: userData,
                    destinationUrl: "mobile"
                )
                
                await MainActor.run {
                    debugInfo += "✅ Success!\n"
                    debugInfo += "Generated URL successfully\n"
                    generatedUrl = url.absoluteString
                }
            } catch {
                await MainActor.run {
                    debugInfo += "❌ Error: \(error)\n"
                    debugInfo += "Failed to generate bypass URL\n"
                }
            }
        }
    }
}
