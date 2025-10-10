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
