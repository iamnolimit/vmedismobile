// File: App/AppState.swift - With Multi-Session Support
import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userData: UserData?
    @Published var showAccountPicker = false
    
    private let userDefaultsKey = "isUserLoggedIn"
    private let userDataKey = "userData"
    
    init() {
        loadLoginState()
        checkForMultipleSessions()
    }
    
    private func checkForMultipleSessions() {
        Task { @MainActor in
            let sessions = SessionManager.shared.sessions
            
            // Jika ada multiple sessions dan belum ada active session
            if sessions.count > 1 && !isLoggedIn {
                showAccountPicker = true
            }
        }
    }
    
    func login(with userData: UserData) {
        self.userData = userData
        self.isLoggedIn = true
        saveLoginState()
        
        // Add to session manager
        Task { @MainActor in
            SessionManager.shared.addOrUpdateSession(userData: userData)
        }
    }
      func logout() {
        // Only logout current session, keep other sessions
        if let currentUserData = self.userData {
            Task { @MainActor in
                // Clear menu access data
                MenuAccessManager.shared.clearMenuData()
                print("🔄 Logging out - menu data cleared")
                
                // Find and remove current session
                if let session = SessionManager.shared.sessions.first(where: { 
                    $0.userData.username == currentUserData.username && 
                    $0.userData.domain == currentUserData.domain 
                }) {
                    SessionManager.shared.removeSession(session)
                }
                
                // Check if there are other sessions
                if let nextSession = SessionManager.shared.getActiveSession() {
                    // Switch to another session
                    self.userData = nextSession.userData
                    self.isLoggedIn = true
                    saveLoginState()
                    print("✅ Switched to next available session")
                } else {
                    // No more sessions, full logout
                    self.userData = nil
                    self.isLoggedIn = false
                    clearLoginState()
                    print("✅ Full logout - no sessions remaining")
                }
            }
        } else {
            self.userData = nil
            self.isLoggedIn = false
            clearLoginState()
        }
    }      
    func switchAccount(to session: AccountSession) {
        Task { @MainActor in
            print("🔄 Switching account from \(self.userData?.username ?? "none") to \(session.userData.username ?? "unknown")")
            
            // Clear menu access data dari akun sebelumnya (legacy, sekarang tidak perlu karena menu di-load dari userData)
            MenuAccessManager.shared.clearMenuData()
            
            // Switch session
            SessionManager.shared.switchSession(session)
            self.userData = session.userData
            self.isLoggedIn = true
            saveLoginState()
              // Log detail userData yang baru
            let menuCount = session.userData.aksesMenu?.count ?? 0
            let isSuper = session.userData.lvl == 1
            let userLevel = session.userData.lvl ?? 0
            print("✅ Switched to: \(session.userData.username ?? "unknown")")
            print("   - ID: \(session.userData.id ?? "N/A")")
            print("   - Level: \(userLevel) \(isSuper ? "(Superadmin)" : "")")
            print("   - Menu Access: \(menuCount) items in userData.aksesMenu")
            if let aksesMenu = session.userData.aksesMenu {
                print("   - Menu URLs: \(aksesMenu)")
            }
        }
    }
    
    func logoutAllAccounts() {
        Task { @MainActor in
            SessionManager.shared.clearAllSessions()
        }
        self.userData = nil
        self.isLoggedIn = false
        clearLoginState()
    }
    
    // MARK: - Persistent Storage
    private func saveLoginState() {
        // Save login status
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        
        // Save user data
        if let userData = userData {
            do {
                let encoded = try JSONEncoder().encode(userData)
                UserDefaults.standard.set(encoded, forKey: userDataKey)
                
                // Save sensitive data (token) to Keychain if available
                if let token = userData.token {
                    KeychainHelper.save(token, forKey: "userToken")
                }
                
                print("✅ Login state saved to storage")
            } catch {
                print("❌ Failed to save user data: \(error)")
            }
        }
    }
    
    private func loadLoginState() {
        // Load login status
        let isLoggedIn = UserDefaults.standard.bool(forKey: userDefaultsKey)
        
        if isLoggedIn {
            // Load user data
            if let data = UserDefaults.standard.data(forKey: userDataKey) {                do {
                    let userData = try JSONDecoder().decode(UserData.self, from: data)
                    
                    // Load token from Keychain (check if exists but don't need to use)
                    _ = KeychainHelper.load(forKey: "userToken")
                    
                    self.userData = userData
                    self.isLoggedIn = true
                    print("✅ Login state loaded from storage")
                    print("User: \(userData.username ?? "Unknown")")
                } catch {
                    print("❌ Failed to load user data: \(error)")
                    clearLoginState()
                }
            } else {
                clearLoginState()
            }
        }
    }
    
    private func clearLoginState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userDataKey)
        KeychainHelper.delete(forKey: "userToken")
        print("🗑️ Login state cleared from storage")
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("✅ Saved \(key) to Keychain")
        } else {
            print("❌ Failed to save \(key) to Keychain: \(status)")
        }
    }
    
    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess,
           let data = item as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        } else {
            print("❌ Failed to load \(key) from Keychain: \(status)")
            return nil
        }
    }
    
    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("✅ Deleted \(key) from Keychain")
        }
    }
}
