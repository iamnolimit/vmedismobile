# Menu Access Isolation Fix - Final Implementation

## 🔴 CRITICAL BUG FIXED

**Problem:** Menu access ter-swap antar akun saat switch account

- Akun A (superadmin, full access) → Switch ke Akun B (regular user, limited access) ✅ Correct
- Akun B → Switch ke Akun A → **Akun A mendapat menu B** ❌ WRONG!

**Root Cause Identified:**

1. `loadUserMenuAccess()` di MainTabView **masih menyimpan** menu access ke global UserDefaults via `MenuAccessManager.shared.saveMenuAccess()`
2. Ini **membatalkan** efek dari `clearMenuData()` yang dipanggil di `switchAccount()`
3. Menu access dari akun sebelumnya "mengotori" akun berikutnya

## ✅ SOLUTION IMPLEMENTED

### 1. Remove UserDefaults Persistence for Menu Access

**Before (WRONG):**

```swift
// MainTabView.swift - loadUserMenuAccess()
MenuAccessManager.shared.saveMenuAccess(menuAccessItems)  // ❌ Save ke UserDefaults
let menuAccess = MenuAccessManager.shared.getMenuAccess() // ❌ Load dari UserDefaults
userMenuAccess = menuAccess
```

**After (CORRECT):**

```swift
// MainTabView.swift - loadUserMenuAccess()
userMenuAccess = menuAccessItems  // ✅ Langsung assign, TIDAK save ke UserDefaults
```

### 2. Read Menu Access Directly from userData

**Principle:** Menu access harus **SELALU** dibaca dari `userData.aksesMenu`, bukan dari UserDefaults global.

**Files Modified:**

- `Views/Pages/MainTabView.swift` - ProfileView section
  - `loadUserMenuAccess()` - Hapus save/load via UserDefaults
  - `filterMenuItemsByAccess()` - Read dari `userMenuAccess` lokal
  - `checkTabAccess()` - Read dari `userData.aksesMenu` langsung

### 3. Force ProfileView Re-render on Account Switch

**Problem:** ProfileView memiliki state lokal yang tidak auto-update saat parent userData berubah

**Solution:** Add `.id(userData.id)` modifier untuk force re-render

```swift
ProfileView(
    userData: userData,
    navigationRoute: $navigationRoute,
    shouldNavigate: $shouldNavigateToReport,
    submenuToExpand: $submenuToExpand,
    previousTab: $previousTab,
    selectedTab: $selectedTab
)
.id(userData.id) // ✅ Force re-render when userData changes
```

### 4. Enhanced Logging for Debugging

Added extensive logging di:

- `SessionManager.switchSession()` - Log target user details
- `SessionManager.loadSessions()` - Log all sessions with menu access
- `MainTabView.loadUserMenuAccess()` - Log user ID, level, menu count
- `AppState.switchAccount()` - Log switched user details

## 📊 FLOW COMPARISON

### ❌ Before (Buggy Flow)

```
1. Login Akun A (superadmin)
   └─> userData.aksesMenu = []
   └─> loadUserMenuAccess()
       └─> menuAccessItems = [] (empty for superadmin)
       └─> MenuAccessManager.saveMenuAccess([]) ❌ Save to UserDefaults
       └─> filteredMenuItems = ALL (full access)

2. Tambah Akun B (regular user)
   └─> userData.aksesMenu = ["customers", "laporan", ...]
   └─> loadUserMenuAccess()
       └─> menuAccessItems = [customers, laporan, ...]
       └─> MenuAccessManager.saveMenuAccess([...]) ❌ OVERWRITE UserDefaults
       └─> filteredMenuItems = LIMITED

3. Switch ke Akun A
   └─> AppState.switchAccount(A)
   └─> MenuAccessManager.clearMenuData() ✅ Clear UserDefaults
   └─> userData = A.userData (lvl=1, aksesMenu=[])
   └─> onChange(of: userData.id) triggered
   └─> loadUserMenuAccess()
       └─> menuAccessItems = [] (empty for superadmin)
       └─> MenuAccessManager.saveMenuAccess([]) ❌ Save empty to UserDefaults
       └─> BUT! State masih ter-cache dari Akun B
       └─> filteredMenuItems = LIMITED ❌ WRONG! Should be ALL
```

### ✅ After (Fixed Flow)

```
1. Login Akun A (superadmin)
   └─> userData.aksesMenu = []
   └─> loadUserMenuAccess()
       └─> userLevel = 1 (superadmin)
       └─> filteredMenuItems = menuItems (ALL) ✅
       └─> userMenuAccess = [] (not used for superadmin)

2. Tambah Akun B (regular user)
   └─> userData.aksesMenu = ["customers", "laporan", ...]
   └─> loadUserMenuAccess()
       └─> userLevel = 3 (regular)
       └─> userMenuAccess = [customers, laporan, ...] ✅ Direct assign
       └─> filteredMenuItems = FILTERED based on userMenuAccess

3. Switch ke Akun A
   └─> AppState.switchAccount(A)
   └─> SessionManager.switchSession(A)
       └─> Log: Target level: 1, aksesMenu: 0 items
   └─> userData = A.userData (lvl=1, aksesMenu=[])
   └─> .id(userData.id) triggers ProfileView re-render ✅
   └─> onChange(of: userData.id) triggered
   └─> loadUserMenuAccess()
       └─> Log: User ID, Level 1, aksesMenu: 0 items
       └─> userLevel = 1 (superadmin)
       └─> filteredMenuItems = menuItems (ALL) ✅ CORRECT!
```

## 🔧 KEY CHANGES

### 1. MainTabView.swift

#### loadUserMenuAccess()

```swift
private func loadUserMenuAccess() {
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔐 LOADING MENU ACCESS FOR USER")
    print("   Username: \(userData.username ?? "unknown")")
    print("   User ID: \(userData.id ?? "N/A")")
    print("   Level: \(userData.lvl ?? 999)")
    print("   AksesMenu count: \(userData.aksesMenu?.count ?? 0)")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    isLoadingMenu = true
    let userLevel = userData.lvl ?? 999

    if userLevel == 1 {
        // Superadmin - full access
        print("👑 Superadmin detected - granting full access to ALL \(menuItems.count) menu items")
        filteredMenuItems = menuItems
        userMenuAccess = []
        isLoadingMenu = false
        return
    }

    // Regular user - read DIRECTLY from userData.aksesMenu
    if let aksesMenu = userData.aksesMenu, !aksesMenu.isEmpty {
        let menuAccessItems = aksesMenu.map { mnUrl in
            MenuAccess(mn_url: mnUrl, mn_kode: "", mn_nama: "")
        }

        // ✅ DIRECTLY use data from userData, DO NOT save to UserDefaults
        userMenuAccess = menuAccessItems

        print("📋 User (lvl=\(userLevel)) has access to \(aksesMenu.count) menu URLs")
        filteredMenuItems = filterMenuItemsByAccess(menuItems)
        print("✅ Filtered to \(filteredMenuItems.count) accessible menu items")
    } else {
        print("⚠️ No menu access in userData - user has NO access")
        filteredMenuItems = []
        userMenuAccess = []
    }

    isLoadingMenu = false
}
```

#### filterMenuItemsByAccess()

```swift
private func filterMenuItemsByAccess(_ menuItems: [MenuItem]) -> [MenuItem] {
    var filtered: [MenuItem] = []

    // Extract accessible URLs from LOCAL userMenuAccess (not UserDefaults!)
    let accessibleUrls = Set(userMenuAccess.map { $0.mn_url })
    print("🔍 Filtering with \(accessibleUrls.count) accessible URLs from userMenuAccess")

    for menu in menuItems {
        if let route = menu.route, menu.subMenus == nil {
            if hasLocalAccess(to: route, accessibleUrls: accessibleUrls) {
                filtered.append(menu)
            }
        } else if let subMenus = menu.subMenus {
            let filteredSubs = subMenus.filter {
                hasLocalAccess(to: $0.route, accessibleUrls: accessibleUrls)
            }
            if !filteredSubs.isEmpty {
                let filteredMenu = MenuItem(
                    icon: menu.icon,
                    title: menu.title,
                    route: menu.route,
                    subMenus: filteredSubs
                )
                filtered.append(filteredMenu)
            }
        }
    }

    print("📊 Filtered menu: \(filtered.count) items from \(menuItems.count) total")
    return filtered
}
```

#### checkTabAccess()

```swift
private func checkTabAccess() {
    print("🔐 Checking tab access for user (ID: \(userData.id ?? "N/A"))...")

    let userLevel = userData.lvl ?? 999

    // Superadmin - full access
    if userLevel == 1 {
        print("👑 Superadmin detected - granting full tab access")
        accessibleTabs = ["home", "products", "orders", "forecast", "account"]
        isCheckingAccess = false
        return
    }

    // Regular user - check from userData.aksesMenu (NOT UserDefaults!)
    guard let aksesMenu = userData.aksesMenu, !aksesMenu.isEmpty else {
        print("⚠️ No menu access in userData - granting only account tab")
        accessibleTabs = ["account"]
        isCheckingAccess = false
        return
    }

    print("📋 Checking tab access from userData.aksesMenu (\(aksesMenu.count) items)")

    let allTabs = ["home", "products", "orders", "forecast", "account"]
    accessibleTabs = allTabs.filter { tabName in
        if tabName == "account" { return true }

        if let mnUrl = MenuURLMapping.getURL(for: tabName) {
            return aksesMenu.contains(mnUrl)
        }
        return false
    }

    print("✅ Accessible tabs: \(accessibleTabs)")
    isCheckingAccess = false
}
```

### 2. SessionManager.swift

#### switchSession()

```swift
func switchSession(_ session: AccountSession) {
    let userLevel = session.userData.lvl ?? 999
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔄 SWITCHING SESSION")
    print("   Target user: \(session.userData.username ?? "unknown")")
    print("   Target ID: \(session.userData.id ?? "N/A")")
    print("   Target level: \(userLevel)")
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
```

#### loadSessions()

```swift
private func loadSessions() {
    if let data = UserDefaults.standard.data(forKey: sessionsKey) {
        do {
            sessions = try JSONDecoder().decode([AccountSession].self, from: data)
            print("✅ Loaded \(sessions.count) sessions from persistence")

            // Debug: Print menu access untuk setiap session
            for (index, session) in sessions.enumerated() {
                let menuCount = session.userData.aksesMenu?.count ?? 0
                let isSuper = session.userData.lvl == 1
                let userLevel = session.userData.lvl ?? 0
                print("   \(index + 1). \(session.displayName)")
                print("      - ID: \(session.userData.id ?? "N/A")")
                print("      - Level: \(userLevel) \(isSuper ? "(Superadmin)" : "")")
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
```

### 3. AppState.swift

#### switchAccount()

```swift
func switchAccount(to session: AccountSession) {
    Task { @MainActor in
        print("🔄 Switching account from \(self.userData?.username ?? "none") to \(session.userData.username ?? "unknown")")

        // Clear menu access data (legacy, tidak perlu karena menu di-load dari userData)
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
```

## 🧪 TESTING SCENARIO

### Test Case 1: Superadmin → Regular User

1. Login akun A (superadmin, lvl=1, aksesMenu=[])
2. Verify: All menu items visible ✅
3. Tambah akun B (regular user, lvl=3, aksesMenu=["customers", "laporan"])
4. Verify: Only accessible menu visible ✅
5. Check logs: Menu count correct ✅

### Test Case 2: Regular User → Superadmin (Critical)

1. Switch dari akun B ke akun A
2. Check logs:
   ```
   🔄 SWITCHING SESSION
      Target user: admin
      Target level: 1
      Target aksesMenu: 0 items
   🔐 LOADING MENU ACCESS FOR USER
      User ID: xxx
      Level: 1
      AksesMenu count: 0
   👑 Superadmin detected - granting full access to ALL 5 menu items
   ```
3. Verify: All menu items visible ✅
4. **FIXED**: No longer shows limited menu from previous user ✅

### Test Case 3: Multiple Switches

1. Switch A → B → A → B → A
2. Each switch logs correct user ID and level ✅
3. Menu access always correct for each user ✅

## 📝 VERIFICATION CHECKLIST

- [x] Remove `MenuAccessManager.saveMenuAccess()` from `loadUserMenuAccess()`
- [x] Read menu directly from `userData.aksesMenu`
- [x] Filter menu using local `userMenuAccess` state
- [x] Check tab access from `userData.aksesMenu`
- [x] Force ProfileView re-render with `.id(userData.id)`
- [x] Add extensive logging for debugging
- [x] Fix all compile errors (Int? to String? conversion)
- [x] Test superadmin → regular user switch ✅
- [x] Test regular user → superadmin switch ✅
- [x] Test multiple rapid switches ✅

## 🎯 RESULT

**Menu access isolation is now COMPLETE!** Each account maintains its own menu access without cross-contamination.

- ✅ Superadmin always gets full access
- ✅ Regular user gets filtered menu based on their `aksesMenu`
- ✅ Switch antar akun tidak lagi "bocor" menu access
- ✅ Session persistence bekerja dengan benar
- ✅ Extensive logging untuk debugging

## 📚 RELATED DOCUMENTATION

- `MULTI_SESSION_IMPLEMENTATION.md` - Original multi-session implementation
- `FIX_MENU_ACCESS_SWITCH.md` - First attempt to fix menu access
- `FIX_MENU_SWAP_CRITICAL.md` - Critical bug identification
- `FIX_MENU_ACCESS_ISOLATION.md` - Isolation strategy
- `CRITICAL_FIX_SUMMARY.md` - Summary of all fixes

---

**Date:** October 22, 2025  
**Status:** ✅ COMPLETED & TESTED  
**Files Modified:** 3 (MainTabView.swift, SessionManager.swift, AppState.swift)
