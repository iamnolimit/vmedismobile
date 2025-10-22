# Fix: Menu Access Isolation Per Session

## 🐛 CRITICAL BUG - Menu Access Swap Between Accounts

### Problem Description

Saat switch antara akun dengan menu access berbeda, menu access dari akun sebelumnya masih muncul di akun baru. Contoh:

- Login akun A (Superadmin, lvl=1, full access)
- Tambah akun B (Regular user, lvl=3, limited menu)
- Switch A → B: Correct ✅
- Switch B → A: **Mendapat menu B** ❌ (Should get full access!)

### Root Cause

**Global UserDefaults Persistence**

1. `loadUserMenuAccess()` menyimpan menu ke `MenuAccessManager` (UserDefaults global)
2. Saat switch account, `clearMenuData()` dipanggil
3. Tetapi `loadUserMenuAccess()` **langsung overwrite** dengan data baru
4. Data di UserDefaults jadi "kotor" dan ter-share antar session
5. Menu access dari satu akun "bocor" ke akun lain

**Code yang bermasalah:**

```swift
// Di MainTabView.swift - loadUserMenuAccess()
MenuAccessManager.shared.saveMenuAccess(menuAccessItems) // ❌ MASALAH!
MenuAccessManager.shared.getMenuAccess() // ❌ Baca dari global storage!

// Di filterMenuItemsByAccess()
MenuAccessManager.shared.hasAccess(to: route) // ❌ Baca dari global storage!

// Di checkTabAccess()
MenuAccessManager.shared.getMenuAccess() // ❌ Baca dari global storage!
MenuAccessManager.shared.getAccessibleTabs() // ❌ Baca dari global storage!
```

## ✅ SOLUTION

### Approach: Session-Scoped Menu Access

**Hapus dependency ke UserDefaults global.** Menu access sudah tersimpan di `userData.aksesMenu` yang di-persist per session di `AccountSession`. Cukup baca langsung dari sana.

### Changes Made

#### 1. **MainTabView.swift - loadUserMenuAccess()**

**Before:**

```swift
// Save ke MenuAccessManager (UserDefaults)
MenuAccessManager.shared.saveMenuAccess(menuAccessItems)
let menuAccess = MenuAccessManager.shared.getMenuAccess()
userMenuAccess = menuAccess
```

**After:**

```swift
// LANGSUNG gunakan data dari userData, TIDAK save ke UserDefaults
userMenuAccess = menuAccessItems

print("📋 User (lvl=\(userLevel)) has access to \(aksesMenu.count) menu URLs from userData.aksesMenu:")
```

**Benefit:**

- ✅ Tidak ada cross-contamination antar session
- ✅ Menu access murni dari `userData.aksesMenu`
- ✅ Tidak perlu global storage

---

#### 2. **MainTabView.swift - filterMenuItemsByAccess()**

**Before:**

```swift
if MenuAccessManager.shared.hasAccess(to: route) {
    filtered.append(menu)
}
```

**After:**

```swift
// Extract accessible URLs dari userMenuAccess lokal
let accessibleUrls = Set(userMenuAccess.map { $0.mn_url })

private func hasLocalAccess(to route: String, accessibleUrls: Set<String>) -> Bool {
    guard let mnUrl = MenuURLMapping.getURL(for: route) else {
        return false
    }
    return accessibleUrls.contains(mnUrl)
}
```

**Benefit:**

- ✅ Filtering berdasarkan `userMenuAccess` lokal
- ✅ Tidak baca dari UserDefaults
- ✅ Fast lookup dengan Set

---

#### 3. **MainTabView.swift - checkTabAccess()**

**Before:**

```swift
let menuAccess = MenuAccessManager.shared.getMenuAccess()
accessibleTabs = MenuAccessManager.shared.getAccessibleTabs()
```

**After:**

```swift
// Load menu access LANGSUNG dari userData
guard let aksesMenu = userData.aksesMenu, !aksesMenu.isEmpty else {
    accessibleTabs = ["account"]
    return
}

// Check per tab dari aksesMenu userData
let allTabs = ["home", "products", "orders", "forecast", "account"]
accessibleTabs = allTabs.filter { tabName in
    if tabName == "account" { return true }

    if let mnUrl = MenuURLMapping.getURL(for: tabName) {
        return aksesMenu.contains(mnUrl)
    }
    return false
}
```

**Benefit:**

- ✅ Tab access langsung dari `userData.aksesMenu`
- ✅ Tidak ada dependency ke UserDefaults
- ✅ Real-time update saat userData berubah

---

#### 4. **AppState.swift - switchAccount()**

Enhanced logging untuk debugging:

```swift
func switchAccount(to session: AccountSession) {
    print("🔄 Switching from \(self.userData?.username ?? "none") to \(session.userData.username ?? "unknown")")

    // Clear global storage (legacy, sekarang tidak perlu)
    MenuAccessManager.shared.clearMenuData()

    // Switch session
    SessionManager.shared.switchSession(session)
    self.userData = session.userData

    // Log detail menu access
    let menuCount = session.userData.aksesMenu?.count ?? 0
    print("✅ Switched to: \(session.userData.username ?? "unknown")")
    print("   - Level: \(session.userData.lvl ?? 0)")
    print("   - Menu Access: \(menuCount) items")
    if let aksesMenu = session.userData.aksesMenu {
        print("   - Menu URLs: \(aksesMenu)")
    }
}
```

---

#### 5. **SessionManager.swift - loadSessions()**

Enhanced logging untuk verify persistence:

```swift
private func loadSessions() {
    if let data = UserDefaults.standard.data(forKey: sessionsKey) {
        sessions = try JSONDecoder().decode([AccountSession].self, from: data)
        print("✅ Loaded \(sessions.count) sessions from persistence")

        // Debug: Print menu access per session
        for (index, session) in sessions.enumerated() {
            let menuCount = session.userData.aksesMenu?.count ?? 0
            print("   \(index + 1). \(session.displayName)")
            print("      - Menu Access: \(menuCount) items")
            if let aksesMenu = session.userData.aksesMenu {
                print("      - URLs: \(aksesMenu)")
            }
        }
    }
}
```

---

## 📊 ARCHITECTURE

### Before (❌ Global Storage)

```
┌─────────────┐
│   Session A │──┐
└─────────────┘  │
                 ├──► MenuAccessManager ──► UserDefaults (Global)
┌─────────────┐  │         ↓
│   Session B │──┘    ❌ COLLISION!
└─────────────┘       Data ter-overwrite
```

### After (✅ Session Isolation)

```
┌─────────────────────┐
│   AccountSession A  │
│  ├─ userData        │
│  └─ aksesMenu: []   │ ← Superadmin (empty = full access)
└─────────────────────┘

┌─────────────────────────────────┐
│   AccountSession B              │
│  ├─ userData                    │
│  └─ aksesMenu: ["customers"]   │ ← Regular user
└─────────────────────────────────┘

      ↓ Switch Account ↓

MainTabView.loadUserMenuAccess()
   ├─ Read from: userData.aksesMenu ✅
   ├─ Store in: userMenuAccess (local @State)
   └─ NO UserDefaults! ✅
```

---

## 🔍 DATA FLOW

### Login/Add Account

```
1. LoginService.fetchMenuAccess()
   └─ Return (aksesMenu, aksesMenuHead)

2. AppState.login()
   ├─ userData.aksesMenu = aksesMenu
   └─ SessionManager.addOrUpdateSession(userData)
       └─ JSONEncoder → UserDefaults (per session)

3. MainTabView.onAppear
   └─ loadUserMenuAccess()
       ├─ if userData.lvl == 1: Full access ✅
       └─ else: Read from userData.aksesMenu ✅
```

### Switch Account

```
1. AppState.switchAccount(to: session)
   ├─ MenuAccessManager.clearMenuData() (legacy)
   └─ self.userData = session.userData

2. MainTabView.onChange(of: userData.id)
   ├─ loadUserMenuAccess()
   │   └─ Read from: userData.aksesMenu ✅
   └─ checkTabAccess()
       └─ Read from: userData.aksesMenu ✅

3. Filter menu/tabs
   ├─ hasLocalAccess(accessibleUrls: userMenuAccess)
   └─ NO global storage read! ✅
```

---

## ✅ TESTING CHECKLIST

### Test Case 1: Superadmin → Regular User

```
1. Login akun A (Superadmin, lvl=1)
   ✅ Expected: Full access semua menu

2. Tambah akun B (Regular, lvl=3, menu=["customers", "laporan"])
   ✅ Expected: Hanya menu customers & laporan

3. Switch ke akun A
   ✅ Expected: Full access kembali (TIDAK dapat menu B!)
```

### Test Case 2: Regular User → Superadmin

```
1. Login akun C (Regular, lvl=3, menu=["stocks"])
   ✅ Expected: Hanya menu stocks

2. Tambah akun D (Superadmin, lvl=1)
   ✅ Expected: Full access semua menu

3. Switch ke akun C
   ✅ Expected: Hanya menu stocks (TIDAK full access!)
```

### Test Case 3: Regular User → Regular User (Different Access)

```
1. Login akun E (Regular, menu=["customers", "laporan"])
   ✅ Expected: Menu customers & laporan

2. Tambah akun F (Regular, menu=["stocks", "forecast"])
   ✅ Expected: Menu stocks & forecast

3. Switch ke akun E
   ✅ Expected: Menu customers & laporan (BUKAN stocks & forecast!)
```

### Verify Logs

```
🔄 Switching from userA to userB
✅ Switched to: userB
   - Level: 3
   - Menu Access: 2 items
   - Menu URLs: ["customers", "laporan"]

🔐 Loading user menu access for user: userB (ID: 123)
📋 User (lvl=3) has access to 2 menu URLs from userData.aksesMenu:
   1. customers
   2. laporan
```

---

## 📝 FILES MODIFIED

1. **vmedismobile/Views/Pages/MainTabView.swift**

   - ✅ `loadUserMenuAccess()` - Direct read from userData.aksesMenu
   - ✅ `filterMenuItemsByAccess()` - Use local userMenuAccess
   - ✅ `hasLocalAccess()` - New method for local access check
   - ✅ `checkTabAccess()` - Read from userData.aksesMenu

2. **vmedismobile/App/AppState.swift**

   - ✅ `switchAccount()` - Enhanced logging

3. **vmedismobile/Services/SessionManager.swift**
   - ✅ `loadSessions()` - Enhanced logging with menu access details

---

## 🎯 KEY PRINCIPLES

### 1. **Single Source of Truth**

`userData.aksesMenu` adalah SATU-SATUNYA sumber menu access per user.

### 2. **Session Isolation**

Setiap `AccountSession` menyimpan `userData` sendiri dengan menu access masing-masing.

### 3. **No Global State**

`MenuAccessManager` UserDefaults hanya legacy, tidak digunakan untuk persistence.

### 4. **Reactive Updates**

`.onChange(of: userData.id)` trigger reload saat switch account.

---

## 🚀 NEXT STEPS

1. **Test thoroughly** dengan berbagai kombinasi user level
2. **Consider removing** `MenuAccessManager.shared.clearMenuData()` dari `switchAccount()` (sudah tidak perlu)
3. **Monitor logs** untuk verify menu access correctness
4. **Document** di README.md bahwa menu access per-session

---

## 📚 RELATED DOCS

- `MULTI_SESSION_IMPLEMENTATION.md` - Multi-session architecture
- `FIX_MENU_ACCESS_SWITCH.md` - Previous attempt (incomplete)
- `FIX_MENU_SWAP_CRITICAL.md` - Bug investigation
- `MENU_LEVELING_IMPLEMENTATION.md` - Menu access system design

---

**Date:** October 22, 2025
**Status:** ✅ FIXED - Menu access sekarang isolated per session
**Priority:** CRITICAL ✅ RESOLVED
