# Critical Fix: Menu Access Ter-swap Antar Akun

## 🐛 Problem

**Symptom:** Menu access ter-swap antara akun A dan akun B

- Login akun A (full access) → OK
- Tambah akun B (limited access) → OK
- Switch ke akun A → **Dapat menu B** (WRONG!)
- Switch ke akun B → **Dapat menu A** (WRONG!)

## 🔍 Root Cause Analysis

### Problem Flow:

```
1. Login Akun A (superadmin)
   ├─ Fetch menu A from server: [] (empty, karena superadmin)
   ├─ Create AccountSession dengan userData A
   └─ Save session: { userData: { lvl: 1, aksesMenu: [] } }

2. Tambah Akun B (regular user)
   ├─ Fetch menu B from server: ["customers", "laporan"]
   ├─ Create AccountSession dengan userData B
   └─ Save session: { userData: { lvl: 3, aksesMenu: ["customers", "laporan"] } }

3. Switch ke Akun A
   ├─ Load session A dari UserDefaults
   ├─ session.userData masih versi LAMA (saat pertama login)
   └─ userData.aksesMenu = undefined atau null

4. ProfileView.loadUserMenuAccess()
   ├─ Check userData.aksesMenu → Empty!
   ├─ MenuAccessManager.getMenuAccess() → Load dari UserDefaults
   └─ Dapat menu dari akun yang terakhir save → MENU B! ❌
```

### Root Cause:

1. **AccountSession.userData adalah `let` (immutable)**
   - Tidak bisa di-update dengan fresh userData setelah login
   - userData yang di-save adalah snapshot saat pertama login
2. **addOrUpdateSession tidak update userData**
   - Saat re-login akun yang sudah ada, hanya update `isActive` dan `lastAccessTime`
   - `userData` dengan menu access baru TIDAK ter-update
3. **MenuAccessManager menggunakan global UserDefaults key**
   - Semua akun share key yang sama: `"aksesMenu"`
   - Akun terakhir yang login overwrite data di UserDefaults

## ✅ Solution

### Fix 1: Make userData Mutable in AccountSession

**File:** `Models/AccountSession.swift`

```swift
struct AccountSession: Codable, Identifiable {
    let id: String
    var userData: UserData  // ← Changed from `let` to `var`
    let loginTime: Date
    var lastAccessTime: Date
    var isActive: Bool
}
```

**Impact:**

- ✅ userData bisa di-update dengan fresh data dari server
- ✅ Menu access terbaru akan tersimpan di session

### Fix 2: Update userData in addOrUpdateSession

**File:** `Services/SessionManager.swift`

```swift
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
        // Update existing session WITH NEW USERDATA
        var updatedSession = sessions[existingIndex]
        updatedSession.userData = userData  // ← UPDATE USERDATA!
        updatedSession.updateAccessTime()
        updatedSession.isActive = true
        sessions[existingIndex] = updatedSession

        setActiveSession(updatedSession)
        print("✅ Updated existing session with fresh userData")
    } else {
        // Add new session...
    }

    saveSessions()
}
```

**Impact:**

- ✅ Setiap kali login, userData di-update dengan data terbaru
- ✅ Menu access yang di-fetch dari server ter-save ke session

### Fix 3: Enhanced Debug Logging

**File:** `Services/SessionManager.swift`

```swift
print("📊 Total sessions: \(sessions.count)")
for (index, session) in sessions.enumerated() {
    let menuCount = session.userData.aksesMenu?.count ?? 0
    let isSuper = session.userData.lvl == 1
    print("   \(index + 1). \(session.displayName)")
    print("      Active: \(session.isActive)")
    print("      Menu: \(menuCount) items")
    print("      Level: \(session.userData.lvl ?? 0) \(isSuper ? "(Superadmin)" : "")")
}
```

**Impact:**

- ✅ Bisa trace menu access per session
- ✅ Debug lebih mudah

## 🔄 Correct Flow After Fix

```
1. Login Akun A (superadmin)
   ├─ Fetch menu A: [] (empty)
   ├─ Create session: { userData: { lvl: 1, aksesMenu: [] } }
   └─ Save to UserDefaults ✅

2. Tambah Akun B (regular user)
   ├─ Fetch menu B: ["customers", "laporan"]
   ├─ Create session: { userData: { lvl: 3, aksesMenu: ["customers", "laporan"] } }
   └─ Save to UserDefaults ✅

3. Switch ke Akun A
   ├─ Load session A dari UserDefaults
   ├─ session.userData = { lvl: 1, aksesMenu: [] }
   ├─ ProfileView.loadUserMenuAccess()
   ├─ userData.aksesMenu = [] (empty)
   ├─ Check lvl == 1 → Superadmin!
   └─ Full access granted ✅

4. Switch ke Akun B
   ├─ Load session B dari UserDefaults
   ├─ session.userData = { lvl: 3, aksesMenu: ["customers", "laporan"] }
   ├─ ProfileView.loadUserMenuAccess()
   ├─ userData.aksesMenu = ["customers", "laporan"]
   └─ Filter menu based on aksesMenu ✅
```

## 🧪 Testing

### Test Scenario 1: Superadmin → Regular User

```bash
1. Login akun A (superadmin, lvl=1)
2. ✅ Verifikasi full access
3. Tambah akun B (regular, lvl=3, menu: ["customers"])
4. ✅ Verifikasi limited access (only customers)
5. Switch ke akun A
6. ✅ Verifikasi full access kembali
7. Switch ke akun B
8. ✅ Verifikasi limited access kembali
```

**Expected Console Output:**

```
📊 Total sessions: 2
   1. Admin User - Active: false - Menu: 0 items - Level: 1 (Superadmin)
   2. Regular User - Active: true - Menu: 1 items - Level: 3

🔄 Switching account - menu data cleared
✅ Switched to account: adminuser
📊 Session loaded: lvl=1, menu=0 items
👑 Superadmin detected - granting full access
```

### Test Scenario 2: Regular User → Regular User (Different Access)

```bash
1. Login User A (menu: ["customers", "apotek"])
2. ✅ Verifikasi menu customers & apotek
3. Tambah User B (menu: ["klinik", "billing"])
4. ✅ Verifikasi menu klinik & billing
5. Switch ke User A
6. ✅ Verifikasi menu customers & apotek kembali
7. Switch ke User B
8. ✅ Verifikasi menu klinik & billing kembali
```

## 📊 Debug Commands

### 1. Check Session Data in Console

```swift
print("🔍 Active Session:")
if let active = SessionManager.shared.activeSession {
    print("   Username: \(active.userData.username ?? "nil")")
    print("   Level: \(active.userData.lvl ?? 0)")
    print("   Menu Count: \(active.userData.aksesMenu?.count ?? 0)")
    print("   Menu Items: \(active.userData.aksesMenu ?? [])")
}
```

### 2. Check All Sessions

```swift
print("🔍 All Sessions:")
for session in SessionManager.shared.sessions {
    print("   - \(session.displayName)")
    print("     Level: \(session.userData.lvl ?? 0)")
    print("     Menu: \(session.userData.aksesMenu?.count ?? 0) items")
}
```

### 3. Check UserDefaults (Legacy)

```swift
if let data = UserDefaults.standard.data(forKey: "aksesMenu") {
    let menu = try? JSONDecoder().decode([MenuAccess].self, from: data)
    print("UserDefaults Menu: \(menu?.count ?? 0) items")
}
```

## 🎯 Key Points

1. **userData must be mutable (`var`)**
   - Allows updating with fresh server data
2. **Update userData on every login**
   - Even if session exists, update with new data
   - Menu access might change on server
3. **Don't rely on UserDefaults for menu access**
   - Each session has its own userData with menu
   - UserDefaults only for persistence, not source of truth
4. **Clear MenuAccessManager on switch**
   - Prevents loading stale data from global storage
   - Force reload from session's userData

## ⚠️ Important Notes

- **Backward Compatibility:** Old sessions in UserDefaults will still work, but userData won't update until next login
- **Migration:** Users might need to logout/login once to get fresh userData in sessions
- **Testing:** Test with fresh install + test with existing sessions

## 🚀 Future Improvements

### Option 1: Force Refresh Menu Access

```swift
func refreshMenuAccess(for session: AccountSession) async {
    // Re-fetch menu access from server
    // Update session userData
    // Save sessions
}
```

### Option 2: Periodic Sync

```swift
// Auto-refresh menu access every 24 hours
if session.lastMenuSync.timeIntervalSinceNow > 86400 {
    await refreshMenuAccess(for: session)
}
```

### Option 3: Server Push

```swift
// Listen for menu access changes from server
// Update local session when server notifies
```

---

**Fixed Date:** October 22, 2025  
**Status:** ✅ Resolved  
**Impact:** Critical - Menu access now correctly persists per account
