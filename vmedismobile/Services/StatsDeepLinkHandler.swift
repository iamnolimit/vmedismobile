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
/**
 * Maps React routes to Swift native routes
 * React routes dari stats navigation akan dikonversi ke route Swift
 */
struct StatsRouteMapper {
    // Mapping React route -> Swift route identifier
    static let routeMap: [String: String] = [
        // Penjualan & Kasir
        "/mobile/laporan-penjualan-obat": "lappenjualanobat",
        "/mobile/laporan-pembayaran-kasir": "lappembayarankasir",
        
        // Customer
        "/mobile/laporan-registrasi-pasien": "lapregistrasipasien",
        "/mobile/laporan-kunjungan-pasien": "lapkunjunganpasien",
        
        // Obat
        "/mobile/laporan-obat-expired": "lapobatexpired",
        "/mobile/laporan-obat-stok-habis": "lapobatstokhabis",
        "/mobile/laporan-stok-opname": "lapstokopname",
        
        // Keuangan
        "/mobile/laporan-hutang-obat": "laphutangobat",
        "/mobile/laporan-piutang-obat": "lappiutangobat",
        "/mobile/laporan-piutang-klinik": "lappiutangklinik",
    ]
    
    static func getSwiftRoute(from reactRoute: String) -> String? {
        return routeMap[reactRoute]
    }
}

// MARK: - Stats Deep Link Handler
class StatsDeepLinkHandler: ObservableObject {
    static let shared = StatsDeepLinkHandler()
    
    // Published property untuk trigger navigation
    @Published var navigationRoute: String?
    @Published var shouldNavigate: Bool = false
    
    private init() {}
    
    /**
     * Process deep link from React stats card
     * Converts React route to Swift native route and triggers navigation
     */
    func handleStatsNavigation(message: [String: Any]) {
        guard let statsId = message["statsId"] as? String,
              let reactRoute = message["route"] as? String else {
            print("❌ Invalid deep link data")
            return
        }
        
        let filterParams = message["filterParams"] as? [String: String]
        
        print("📊 Processing stats navigation:")
        print("   Stats ID: \(statsId)")
        print("   React Route: \(reactRoute)")
        print("   Filters: \(String(describing: filterParams))")
        
        // Convert React route to Swift route
        guard let swiftRoute = StatsRouteMapper.getSwiftRoute(from: reactRoute) else {
            print("❌ Unknown route: \(reactRoute)")
            print("💡 Available routes: \(StatsRouteMapper.routeMap.keys.joined(separator: ", "))")
            return
        }
        
        print("✅ Mapped to Swift route: \(swiftRoute)")
        
        // Trigger navigation
        DispatchQueue.main.async {
            self.navigationRoute = swiftRoute
            self.shouldNavigate = true
            
            // Post notification untuk trigger tab change & navigation
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToReport"),
                object: nil,
                userInfo: [
                    "route": swiftRoute,
                    "statsId": statsId,
                    "filters": filterParams ?? [:]
                ]
            )
            
            print("🚀 Navigation triggered to: \(swiftRoute)")
        }
    }
    
    /**
     * Reset navigation state
     */
    func resetNavigation() {
        navigationRoute = nil
        shouldNavigate = false
    }
}
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
