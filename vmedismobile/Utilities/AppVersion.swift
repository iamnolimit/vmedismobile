// File: Utilities/AppVersion.swift
import Foundation

/// Helper untuk mendapatkan versi aplikasi dari Bundle
struct AppVersion {
    /// Get app version dari Info.plist
    /// Returns: "1.9.7" (contoh)
    static var version: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0" // Default fallback
    }
    
    /// Get build number dari Info.plist
    /// Returns: "1" (contoh)
    static var build: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "1" // Default fallback
    }
    
    /// Get full version string dengan build number
    /// Returns: "1.9.7 (1)" (contoh)
    static var fullVersion: String {
        return "\(version) (\(build))"
    }
    
    /// Get display string untuk footer
    /// Returns: "Powered by Vmedis V1.9.7"
    static var poweredByText: String {
        return "Powered by Vmedis V\(version)"
    }
}
