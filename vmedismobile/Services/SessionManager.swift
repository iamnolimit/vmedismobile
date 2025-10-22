// File: Services/SessionManager.swift
import Foundation
import SwiftUI

/// Manager untuk mengelola multiple account sessions
@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var sessions: [AccountSession] = []
    @Published var activeSession: AccountSession?
    
    private let sessionsKey = "accountSessions"
    private let activeSessionKey = "activeSessionId"
    private let maxSessions = 5  // Maksimal 5 akun
    
    private init() {
        loadSessions()
    }
    
    // MARK: - Session Management    /// Tambah session baru atau update jika sudah ada
    func addOrUpdateSession(userData: UserData) {
        // Deactivate all sessions first
        for i in 0..<sessions.count {
            sessions[i].isActive = false
        }
        
        // Check jika user sudah punya session
        if let existingIndex = sessions.firstIndex(where: { 
            $0.userData.username == userData.username && 
            $0.userData.domain == userData.domain 
        }) {
            // Update existing session WITH NEW USERDATA (termasuk menu access!)
            var updatedSession = sessions[existingIndex]
            updatedSession.userData = userData  // ← UPDATE USERDATA!
            updatedSession.updateAccessTime()
            updatedSession.isActive = true
            sessions[existingIndex] = updatedSession
            
            // Set as active
            setActiveSession(updatedSession)
            print("✅ Updated existing session for \(userData.username ?? "") with fresh userData")
        } else {
            // Check limit
            if sessions.count >= maxSessions {
                // Remove oldest inactive session
                if let oldestIndex = sessions.enumerated()
                    .filter({ !$0.element.isActive })
                    .min(by: { $0.element.lastAccessTime < $1.element.lastAccessTime })?.offset {
                    sessions.remove(at: oldestIndex)
                    print("🗑️ Removed oldest session to make room")
                }
            }
            
            // Add new session
            let newSession = AccountSession(userData: userData, isActive: true)
            sessions.append(newSession)
            setActiveSession(newSession)
            print("✅ Added new session for \(userData.username ?? "")")
        }
          print("📊 Total sessions: \(sessions.count)")
        for (index, session) in sessions.enumerated() {
            let menuCount = session.userData.aksesMenu?.count ?? 0
            let isSuper = session.userData.lvl == 1
            print("   \(index + 1). \(session.displayName) - Active: \(session.isActive) - Menu: \(menuCount) items - Level: \(session.userData.lvl ?? 0) \(isSuper ? "(Superadmin)" : "")")
        }
        
        saveSessions()
    }
      /// Switch ke session lain    func switchSession(_ session: AccountSession) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 SWITCHING SESSION")
        print("   Target user: \(session.userData.username ?? "unknown")")
        print("   Target ID: \(session.userData.id ?? "N/A")")
        print("   Target level: \(String(describing: session.userData.lvl ?? 999))")
        print("   Target aksesMenu: \(session.userData.aksesMenu?.count ?? 0) items")
        if let aksesMenu = session.userData.aksesMenu {
            print("   Menu URLs: \(aksesMenu)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Deactivate all sessions
        for i in 0..<sessions.count {
            sessions[i].isActive = false
        }
        
        // Activate selected session
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            var updatedSession = sessions[index]
            updatedSession.isActive = true
            updatedSession.updateAccessTime()
            sessions[index] = updatedSession
            
            setActiveSession(updatedSession)
            saveSessions()
            
            print("✅ Session switched successfully")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }
    
    /// Remove session
    func removeSession(_ session: AccountSession) {
        sessions.removeAll { $0.id == session.id }
        
        // Jika yang dihapus adalah active session
        if activeSession?.id == session.id {
            // Set session pertama sebagai active (jika ada)
            if let firstSession = sessions.first {
                switchSession(firstSession)
            } else {
                activeSession = nil
                UserDefaults.standard.removeObject(forKey: activeSessionKey)
            }
        }
        
        saveSessions()
        print("🗑️ Removed session: \(session.displayName)")
    }
    
    /// Get active session
    func getActiveSession() -> AccountSession? {
        return activeSession
    }
    
    /// Check if user can add more sessions
    func canAddMoreSessions() -> Bool {
        return sessions.count < maxSessions
    }
    
    /// Get remaining slots
    func remainingSlots() -> Int {
        return max(0, maxSessions - sessions.count)
    }
    
    // MARK: - Private Methods
    
    private func setActiveSession(_ session: AccountSession) {
        activeSession = session
        UserDefaults.standard.set(session.id, forKey: activeSessionKey)
    }
    
    // MARK: - Persistence
    
    private func saveSessions() {
        do {
            let encoded = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
            print("💾 Saved \(sessions.count) sessions")
        } catch {
            print("❌ Failed to save sessions: \(error)")
        }
    }
      private func loadSessions() {
        // Load sessions
        if let data = UserDefaults.standard.data(forKey: sessionsKey) {
            do {
                sessions = try JSONDecoder().decode([AccountSession].self, from: data)
                print("✅ Loaded \(sessions.count) sessions from persistence")
                
                // Debug: Print menu access untuk setiap session
                for (index, session) in sessions.enumerated() {
                    let menuCount = session.userData.aksesMenu?.count ?? 0
                    let isSuper = session.userData.lvl == 1
                    print("   \(index + 1). \(session.displayName)")
                    print("      - ID: \(session.userData.id ?? "N/A")")
                    print("      - Level: \(session.userData.lvl ?? 0) \(isSuper ? "(Superadmin)" : "")")
                    print("      - Menu Access: \(menuCount) items")
                    if let aksesMenu = session.userData.aksesMenu, !aksesMenu.isEmpty {
                        print("      - URLs: \(aksesMenu)")
                    }
                }
                
                // Load active session
                if let activeId = UserDefaults.standard.string(forKey: activeSessionKey),
                   let active = sessions.first(where: { $0.id == activeId }) {
                    activeSession = active
                    print("✅ Active session: \(active.displayName)")
                } else if let first = sessions.first(where: { $0.isActive }) {
                    activeSession = first
                    print("✅ Active session: \(first.displayName)")
                }
            } catch {
                print("❌ Failed to load sessions: \(error)")
                sessions = []
            }
        }
    }
    
    /// Clear all sessions (untuk logout semua)
    func clearAllSessions() {
        sessions.removeAll()
        activeSession = nil
        UserDefaults.standard.removeObject(forKey: sessionsKey)
        UserDefaults.standard.removeObject(forKey: activeSessionKey)
        print("🗑️ Cleared all sessions")
    }
}
