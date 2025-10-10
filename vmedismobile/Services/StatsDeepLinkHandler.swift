import Foundation
import SwiftUI
import WebKit

/**
 * Stats Deep Link Handler
 * Handles navigation from React stats cards to Swift report pages
 * 
 * Usage:
 * 1. React sends message: window.webkit.messageHandlers.navigateToReport.postMessage(data)
 * 2. Swift receives via WKScriptMessageHandler
 * 3. This handler processes the route and parameters
 * 4. Navigates to appropriate report page
 */

// MARK: - Deep Link Models
struct StatsDeepLinkData: Codable {
    let statsId: String
    let route: String
    let filterParams: [String: String]?
    let fromStats: String?
}

// MARK: - Route Mapping
enum ReportRoute: String {
    case lapPenjualanObat = "/mobile/laporan-penjualan-obat"
    case lapKunjunganPasien = "/mobile/laporan-kunjungan-pasien"
    case lapStokOpname = "/mobile/laporan-stok-opname"
    case lapObatStokHabis = "/mobile/laporan-obat-stok-habis"
    case lapObatExpired = "/mobile/laporan-obat-expired"
    case lapHutangObat = "/mobile/laporan-hutang-obat"
    case lapPiutangObat = "/mobile/laporan-piutang-obat"
    
    var swiftRoute: String {
        switch self {
        case .lapPenjualanObat:
            return "/laporan-penjualan-obat"
        case .lapKunjunganPasien:
            return "/laporan-kunjungan-pasien"
        case .lapStokOpname:
            return "/laporan-stok-opname"
        case .lapObatStokHabis:
            return "/laporan-obat-stok-habis"
        case .lapObatExpired:
            return "/laporan-obat-expired"
        case .lapHutangObat:
            return "/laporan-hutang-obat"
        case .lapPiutangObat:
            return "/laporan-piutang-obat"
        }
    }
}

// MARK: - Stats Deep Link Handler
class StatsDeepLinkHandler {
    static let shared = StatsDeepLinkHandler()
    
    private init() {}
    
    /**
     * Process deep link from React stats card
     * @param message: Message from React containing route and params
     * @returns: SwiftUI URL for navigation
     */
    func processDeepLink(_ message: [String: Any]) -> URL? {
        guard let statsId = message["statsId"] as? String,
              let route = message["route"] as? String else {
            print("❌ Invalid deep link data")
            return nil
        }
        
        let filterParams = message["filterParams"] as? [String: String]
        
        print("📊 Processing stats deep link:")
        print("   Stats ID: \(statsId)")
        print("   Route: \(route)")
        print("   Filters: \(String(describing: filterParams))")
        
        // Convert React route to Swift route
        guard let reportRoute = ReportRoute(rawValue: route) else {
            print("❌ Unknown route: \(route)")
            return nil
        }
        
        // Build URL with query parameters
        var components = URLComponents()
        components.path = reportRoute.swiftRoute
        
        if let filters = filterParams {
            components.queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
            components.queryItems?.append(URLQueryItem(name: "fromStats", value: statsId))
        }
        
        let finalURL = components.url
        print("✅ Generated Swift URL: \(String(describing: finalURL))")
        
        return finalURL
    }
    
    /**
     * Get filter configuration for specific stats
     * Used to pre-configure report page based on stats context
     */
    func getFilterConfig(for statsId: String) -> [String: Any]? {
        switch statsId {
        case "penjualan-kasir":
            return [
                "title": "Laporan Penjualan Kasir",
                "defaultFilter": ["jenisPenjualan": "kasir"]
            ]
        case "penjualan-online":
            return [
                "title": "Laporan Penjualan Online",
                "defaultFilter": ["jenisPenjualan": "online"]
            ]
        case "pemeriksaan-klinik":
            return [
                "title": "Laporan Kunjungan Pasien",
                "defaultFilter": [:]
            ]
        case "pareto-a":
            return [
                "title": "Laporan Penjualan - Pareto A",
                "defaultFilter": ["kategoriPareto": "A"]
            ]
        case "pareto-b":
            return [
                "title": "Laporan Penjualan - Pareto B",
                "defaultFilter": ["kategoriPareto": "B"]
            ]
        case "pareto-c":
            return [
                "title": "Laporan Penjualan - Pareto C",
                "defaultFilter": ["kategoriPareto": "C"]
            ]
        case "over-stock":
            return [
                "title": "Laporan Over Stock",
                "defaultFilter": ["statusStok": "over"]
            ]
        case "under-stock":
            return [
                "title": "Laporan Under Stock",
                "defaultFilter": ["statusStok": "under"]
            ]
        default:
            return nil
        }
    }
}

// MARK: - Navigation Helper Extension
extension StatsDeepLinkHandler {
    /**
     * Example: Navigate to report from WebView
     * Call this from WKScriptMessageHandler
     */
    func handleStatsNavigation(message: [String: Any], webView: WKWebView) {
        guard let url = processDeepLink(message) else {
            print("❌ Failed to process deep link")
            return
        }
        
        // Get filter configuration
        if let statsId = message["statsId"] as? String,
           let config = getFilterConfig(for: statsId) {
            print("📋 Filter config: \(config)")
        }
        
        // Navigate to the route (implementation depends on your navigation setup)
        // Example: Use URL to navigate in SwiftUI
        navigateToRoute(url)
    }
    
    private func navigateToRoute(_ url: URL) {
        // TODO: Implement navigation based on your app's architecture
        // This could be:
        // 1. NotificationCenter post to trigger navigation
        // 2. Update @Published navigation state
        // 3. Use NavigationLink programmatically
        
        print("🚀 Navigating to: \(url.absoluteString)")
        
        // Example with NotificationCenter:
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToReport"),
            object: nil,
            userInfo: ["url": url]
        )
    }
}
