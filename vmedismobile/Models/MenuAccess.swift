// File: Models/MenuAccess.swift
// Model untuk menu access dari server (sama seperti React Native)
import Foundation

// MARK: - Menu Access Models

/// Representasi menu access dari server
struct MenuAccess: Codable, Identifiable {
    let id = UUID()
    let mn_url: String
    let mn_kode: String
    let mn_nama: String
    
    enum CodingKeys: String, CodingKey {
        case mn_url
        case mn_kode
        case mn_nama
    }
}

/// Representasi menu header dari server
struct MenuHeader: Codable, Identifiable {
    let id = UUID()
    let mn_nama: String
    let mn_kode: String
    
    enum CodingKeys: String, CodingKey {
        case mn_nama
        case mn_kode
    }
}

/// Response dari GraphQL MenuGroupUser
struct MenuGroupUserResponse: Codable {
    let Items: [MenuHeader]      // Header menu
    let Items1: [MenuAccess]     // Detail menu dengan akses
    let gak: Bool?               // Status flag
}

// MARK: - URL Mapping Helper

/// Helper untuk mapping route iOS ke mn_url server
struct MenuURLMapping {
    
    /// Mapping route iOS ke mn_url yang dipakai server
    /// Berdasarkan Sidemenumap2.js dari vmedis-mobile
    static let routeToURL: [String: String] = [
        // Laporan Apotek
        "lappembelianobat": "/laporan-transaksi-pembelian-obat",
        "laphutangobat": "/laporan-transaksi-bayar-hutang",
        "lappenjualanobat": "/laporan-penjualan-obat",
        "lappiutangobat": "/laporan-piutang-obat",
        "lapobatstokhabis": "/obathabis",
        "lapobatexpired": "/obatexpired",
        "lapobatterlaris": "/lap-obatlaris",
        "lapstokopname": "/laporan-stokopname",
        "lapstokobat": "/lap-stok",
        "lappergantianshift": "/laporan-gantishift",
        
        // Pendaftaran Klinik
        "lapregistrasipasien": "/laporan-master-pasien",
        "lapkunjunganpasien": "/laporan-transaksi-kunjungan",
        
        // Pelayanan Klinik
        "lapjanjidengandokter": "/janji",
        
        // Billing Kasir
        "lappiutangklinik": "/kln-piutang",
        "lappembayarankasir": "/kln-lap-bayar-kasir",
        "lappenjualanobatklinik": "/laporan-penjualan-obat-klinik",
        "laptagihanjaminan": "/laporan-tagihan-jaminan-pasien",
        "lappendapatanpetugasmedis": "/laporan-pendapatan-petugas-medis",
        
        // Laporan Keuangan
        "lapneracaumum": "/laporan-neraca-normal",
        "laplabarugi": "/laporan-laba-rugi",
        
        // Customer/VMart
        "customers": "/customer", // Placeholder - sesuaikan dengan server
        
        // Transaksi
        "pembelianobat": "/pembelian-obat",
        "penjualanobat": "/penjualan-obat",
        "gantishift": "/gantishift",
        "mutasi": "/mutasi",
        
        // Utilitas
        "stokopname": "/stokopname",
    ]
    
    /// Get mn_url dari route iOS
    static func getURL(for route: String) -> String? {
        return routeToURL[route.lowercased()]
    }
    
    /// Check apakah route memiliki mapping
    static func hasMapping(for route: String) -> Bool {
        return routeToURL[route.lowercased()] != nil
    }
}

// MARK: - Menu Access Manager

/// Manager untuk handle menu access logic
class MenuAccessManager {
    
    /// Shared instance
    static let shared = MenuAccessManager()
    
    private init() {}
    
    /// Simpan menu access ke UserDefaults
    func saveMenuAccess(_ menuAccess: [MenuAccess]) {
        if let encoded = try? JSONEncoder().encode(menuAccess) {
            UserDefaults.standard.set(encoded, forKey: "aksesMenu")
            print("✅ Menu access saved: \(menuAccess.count) items")
        }
    }
    
    /// Simpan menu header ke UserDefaults
    func saveMenuHeaders(_ menuHeaders: [MenuHeader]) {
        if let encoded = try? JSONEncoder().encode(menuHeaders) {
            UserDefaults.standard.set(encoded, forKey: "aksesMenuHead")
            print("✅ Menu headers saved: \(menuHeaders.count) items")
        }
    }
    
    /// Load menu access dari UserDefaults
    func getMenuAccess() -> [MenuAccess] {
        guard let data = UserDefaults.standard.data(forKey: "aksesMenu"),
              let decoded = try? JSONDecoder().decode([MenuAccess].self, from: data) else {
            print("⚠️ No menu access found in UserDefaults")
            return []
        }
        print("📋 Loaded menu access: \(decoded.count) items")
        return decoded
    }
    
    /// Load menu headers dari UserDefaults
    func getMenuHeaders() -> [MenuHeader] {
        guard let data = UserDefaults.standard.data(forKey: "aksesMenuHead"),
              let decoded = try? JSONDecoder().decode([MenuHeader].self, from: data) else {
            print("⚠️ No menu headers found in UserDefaults")
            return []
        }
        return decoded
    }
      /// Check apakah user punya akses ke route tertentu
    func hasAccess(to route: String) -> Bool {
        let menuAccess = getMenuAccess()
        
        // Jika tidak ada data menu access, return true (default behavior)
        guard !menuAccess.isEmpty else {
            print("⚠️ No menu access data, allowing all routes")
            return true
        }
        
        // Map route ke mn_url
        guard let mnUrl = MenuURLMapping.getURL(for: route) else {
            print("⚠️ No URL mapping for route: \(route)")
            return false
        }
        
        // Check apakah mn_url ada di list akses user
        let hasAccess = menuAccess.contains { $0.mn_url == mnUrl }
        
        if hasAccess {
            print("✅ Access granted to: \(route) (\(mnUrl))")
        } else {
            print("🚫 Access denied to: \(route) (\(mnUrl))")
        }
        
        return hasAccess
    }
    
    /// Clear all menu data
    func clearMenuData() {
        UserDefaults.standard.removeObject(forKey: "aksesMenu")
        UserDefaults.standard.removeObject(forKey: "aksesMenuHead")
        print("🗑️ Menu data cleared")
    }
    
    /// Debug: Print all menu access
    func debugPrintMenuAccess() {
        let menuAccess = getMenuAccess()
        print("=== MENU ACCESS DEBUG ===")
        print("Total items: \(menuAccess.count)")
        for item in menuAccess {
            print("  - \(item.mn_nama): \(item.mn_url) [\(item.mn_kode)]")
        }
        print("========================")
    }
}
