// File: Models/AccountSession.swift
import Foundation

/// Model untuk menyimpan data session akun
struct AccountSession: Codable, Identifiable {
    let id: String  // Unique identifier untuk session
    let userData: UserData
    let loginTime: Date
    var lastAccessTime: Date
    var isActive: Bool  // Menandakan session yang sedang aktif
    
    init(userData: UserData, isActive: Bool = false) {
        self.id = UUID().uuidString
        self.userData = userData
        self.loginTime = Date()
        self.lastAccessTime = Date()
        self.isActive = isActive
    }
    
    /// Display name untuk session
    var displayName: String {
        return userData.nama_lengkap ?? userData.username ?? "Unknown User"
    }
    
    /// Domain atau klinik info
    var domainInfo: String {
        return userData.kl_nama ?? userData.domain ?? "No Domain"
    }
    
    /// Update last access time
    mutating func updateAccessTime() {
        self.lastAccessTime = Date()
    }
}
