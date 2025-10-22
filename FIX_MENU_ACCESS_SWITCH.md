# Fix: Menu Access Tidak Update Saat Switch Akun

## 🐛 Problem

Ketika switch akun, menu access masih menggunakan data dari akun sebelumnya:

- Login dengan akun superadmin (full access)
- Tambah akun regular user (limited access)
- Menu masih menampilkan full access dari akun superadmin

## 🔍 Root Cause

`MenuAccessManager` menyimpan menu access data di `UserDefaults` dengan key yang sama untuk semua akun. Saat switch akun, data lama tidak di-clear, sehingga akun baru menggunakan menu access dari akun sebelumnya.

## ✅ Solution

### 1. Clear Menu Data Saat Switch Account

**File:** `App/AppState.swift`

```swift
func switchAccount(to session: AccountSession) {
    Task { @MainActor in
        // Clear menu access data dari akun sebelumnya
        MenuAccessManager.shared.clearMenuData()
        print("🔄 Switching account - menu data cleared")

        // Switch session
        SessionManager.shared.switchSession(session)
        self.userData = session.userData
        self.isLoggedIn = true
        saveLoginState()

        print("✅ Switched to account: \(session.userData.username ?? "unknown")")
    }
}
```

### 2. Clear Menu Data Saat Logout

**File:** `App/AppState.swift`

```swift
func logout() {
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
```

### 3. Reload Menu Access Saat UserData Changes

**File:** `Views/Pages/MainTabView.swift` - ProfileView

```swift
.onChange(of: userData.id) { _ in
    // Reload menu access when userData changes (account switch)
    print("🔄 UserData changed - reloading menu access")
    loadUserMenuAccess()
}
```

**File:** `Views/Pages/MainTabView.swift` - MainTabView

```swift
.onChange(of: userData.id) { _ in
    // Reload tab access when userData changes (account switch)
    print("🔄 UserData changed in MainTabView - rechecking tab access")
    checkTabAccess()
}
```

## 🔄 Flow Setelah Fix

### Scenario 1: Switch Account

```
1. User tap account di dropdown
2. AppState.switchAccount() dipanggil
3. MenuAccessManager.clearMenuData() → Clear menu lama
4. SessionManager.switchSession() → Switch session
5. userData di-update
6. .onChange(of: userData.id) triggered
7. loadUserMenuAccess() → Load menu baru
8. checkTabAccess() → Check tab access baru
9. UI update dengan menu & tab sesuai akun baru
```

### Scenario 2: Logout Akun

```
1. User tap "Logout Akun Ini"
2. AppState.logout() dipanggil
3. MenuAccessManager.clearMenuData() → Clear menu
4. SessionManager.removeSession() → Remove session
5. Check apakah ada session lain
6. Jika ada: Switch ke session lain (repeat scenario 1)
7. Jika tidak: Full logout ke login page
```

## 🧪 Testing

### Test Case 1: Full Access → Limited Access

```
1. Login dengan akun superadmin (lvl=1)
2. ✅ Verifikasi semua menu & tab muncul
3. Tambah akun regular user (limited access)
4. ✅ Verifikasi menu & tab sesuai akun baru
5. Switch ke akun superadmin
6. ✅ Verifikasi full access kembali
```

### Test Case 2: Limited Access → Full Access

```
1. Login dengan akun regular user
2. ✅ Verifikasi hanya menu yang allowed muncul
3. Tambah akun superadmin
4. ✅ Verifikasi semua menu & tab muncul
5. Switch ke akun regular
6. ✅ Verifikasi menu terbatas kembali
```

### Test Case 3: Multiple Limited Access Accounts

```
1. Login dengan User A (access: customers, laporan apotek)
2. ✅ Verifikasi menu sesuai User A
3. Tambah User B (access: laporan klinik, billing kasir)
4. ✅ Verifikasi menu sesuai User B
5. Switch ke User A
6. ✅ Verifikasi menu sesuai User A kembali
```

## 📊 Debugging

### Enable Menu Access Debug

```swift
// Di ProfileView.loadUserMenuAccess()
MenuAccessManager.shared.debugPrintMenuAccess()
```

**Output:**

```
=== MENU ACCESS DEBUG ===
Total items: 15
  - Customer: /customers [CUS001]
  - Laporan Pembelian: /lappembelianobat [LAP001]
  - Laporan Penjualan: /lappenjualanobat [LAP002]
  ...
========================
```

### Console Logs Saat Switch Account

```
🔄 Switching account - menu data cleared
🗑️ Menu data cleared
🔄 Switched to session: John Doe
✅ Switched to account: johndoe
🔄 UserData changed - reloading menu access
🔐 Loading user menu access...
⚠️ No menu access data found - will fetch from server
🔄 UserData changed in MainTabView - rechecking tab access
🔐 Checking tab access for user...
👤 Regular user (lvl=3) - filtering menu based on access
✅ Filtered to 5 accessible menu items:
   📂 Customer - route: customers
   📂 Laporan Apotek - 4 submenus
```

## 🎯 Key Points

1. **Menu data is global** - Disimpan di UserDefaults tanpa identifier per-account
2. **Must clear on switch** - Harus clear sebelum load menu access baru
3. **Observer userData.id** - Monitor changes untuk trigger reload
4. **Two levels of reload**:
   - Tab access (MainTabView)
   - Menu access (ProfileView)

## ⚠️ Important Notes

- Menu access data **tidak disimpan per-account** di SessionManager
- Setiap kali switch, data di-fetch ulang dari server (via login flow)
- Jika server tidak mengembalikan menu access, akan menggunakan default (all access untuk superadmin)

## 🚀 Future Improvements

### Option 1: Store Menu Access Per Account

```swift
struct AccountSession: Codable {
    let userData: UserData
    var menuAccess: [MenuAccess]?  // Store menu per account
    var tabAccess: [String]?       // Store tab per account
}
```

### Option 2: Account-Specific UserDefaults Keys

```swift
let menuKey = "aksesMenu_\(userData.username)_\(userData.domain)"
UserDefaults.standard.set(encoded, forKey: menuKey)
```

### Option 3: In-Memory Cache Only

```swift
class MenuAccessManager {
    private var menuCache: [String: [MenuAccess]] = [:]

    func setMenuAccess(for accountId: String, menu: [MenuAccess]) {
        menuCache[accountId] = menu
    }
}
```

---

**Fixed Date:** October 22, 2025  
**Status:** ✅ Resolved  
**Impact:** All account switches now correctly load menu access
