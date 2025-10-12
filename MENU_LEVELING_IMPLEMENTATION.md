# 📋 Dokumentasi Implementasi Sistem Leveling Menu

## 🎯 Tujuan

Mengimplementasikan sistem leveling menu dari **vmedis-mobile** (React Native) ke **vmedismobile** (iOS/Swift) agar tab Akun menampilkan menu yang berbeda per user berdasarkan hak akses mereka.

---

## 📊 Status Implementasi

### ✅ COMPLETED

#### 1. **Analisis Sistem Leveling React Native**

- ✅ Sistem menggunakan GraphQL `MenuGroupUser` query
- ✅ Data dari server berdasarkan:
  - `gr_id` (Group ID) - menentukan group user
  - `lvl` (Level) - level user (1=superadmin, >1=terbatas)
  - `MenuGroupUser.Items1[]` - berisi list menu dengan `mn_url`, `mn_kode`, `mn_nama`
- ✅ Menu disimpan di AsyncStorage sebagai `aksesMenu` dan `aksesMenuHead`
- ✅ Filter menu dilakukan dengan pengecekan `mn_url` dari server

#### 2. **Mapping Menu URL React Native → iOS**

```swift
// Route iOS → mn_url Server
"lappembelianobat"         → "/laporan-transaksi-pembelian-obat"
"lappenjualanobat"         → "/laporan-penjualan-obat"
"lapobatexpired"           → "/obatexpired"
"lapregistrasipasien"      → "/laporan-master-pasien"
"lapkunjunganpasien"       → "/laporan-transaksi-kunjungan"
// ... 20+ mapping lainnya
```

#### 3. **Model Data (MenuAccess.swift)**

File: `vmedismobile/Models/MenuAccess.swift`

**Structs:**

```swift
// Menu access dari server
struct MenuAccess: Codable, Identifiable {
    let mn_url: String   // URL menu (untuk matching)
    let mn_kode: String  // Kode menu
    let mn_nama: String  // Nama menu
}

// Menu header
struct MenuHeader: Codable, Identifiable {
    let mn_nama: String
    let mn_kode: String
}

// URL Mapping
struct MenuURLMapping {
    static let routeToURL: [String: String] = [...]
}

// Manager singleton
class MenuAccessManager {
    static let shared = MenuAccessManager()

    func saveMenuAccess(_ items: [MenuAccess])
    func loadMenuAccess() -> [MenuAccess]
    func getMenuAccess() -> [MenuAccess]
    func hasAccess(to route: String) -> Bool
    func clearMenuAccess()
    func printDebugInfo()
}
```

**Fitur:**

- ✅ Save/load menu access ke UserDefaults
- ✅ `hasAccess(to:)` - check akses per route
- ✅ Mapping route iOS ke URL server
- ✅ Debug utilities

#### 4. **Update UserData Model**

File: `vmedismobile/Services/LoginService.swift`

```swift
struct UserData: Codable {
    // ... existing properties ...

    // MARK: - Menu Access Properties (NEW)
    var aksesMenu: [String]?      // Array mn_url yang user punya akses
    var aksesMenuHead: [String]?  // Array mn_nama header
}
```

#### 5. **GraphQL Integration (LoginService.swift)**

File: `vmedismobile/Services/LoginService.swift`

**GraphQL Query:**

```graphql
query {
  MenuGroupUser(gr_id: <gr_id>) {
    Items1 {
      mn_url
      mn_kode
      mn_nama
    }
  }
}
```

**Flow:**

1. ✅ Login berhasil → fetch menu access dari GraphQL
2. ✅ Parse response → convert ke `MenuAccess` objects
3. ✅ Save ke `MenuAccessManager` (UserDefaults)
4. ✅ Update `userData.aksesMenu` & `userData.aksesMenuHead`

**Code:**

```swift
private func fetchMenuAccess(grId: Int, level: Int, token: String) async throws -> (aksesMenu: [String], aksesMenuHead: [String]) {
    // Superadmin (level 1) skip fetch - dapat full access
    if level == 1 {
        return ([], [])
    }

    // GraphQL query ke server
    let query = """
    query {
      MenuGroupUser(gr_id: \(grId)) {
        Items1 {
          mn_url
          mn_kode
          mn_nama
        }
      }
    }
    """

    // ... fetch & parse ...

    // Save to MenuAccessManager
    MenuAccessManager.shared.saveMenuAccess(menuAccessItems)

    return (aksesMenu, aksesMenuHead)
}
```

#### 6. **ProfileView dengan Menu Filtering**

File: `vmedismobile/Views/Pages/MainTabView.swift`

**State Management:**

```swift
struct ProfileView: View {
    // MARK: - Menu Access Properties
    @State private var userMenuAccess: [MenuAccess] = []
    @State private var filteredMenuItems: [MenuItem] = []
    @State private var isLoadingMenu: Bool = true

    // ... existing code ...
}
```

**Load & Filter Logic:**

```swift
private func loadUserMenuAccess() {
    print("🔐 Loading user menu access...")
    isLoadingMenu = true

    // Load dari MenuAccessManager
    let menuAccess = MenuAccessManager.shared.getMenuAccess()
    userMenuAccess = menuAccess

    let userLevel = userData.lvl ?? 999

    if userLevel == 1 {
        // Superadmin - full access
        print("👑 Superadmin - granting full access")
        filteredMenuItems = menuItems
    } else if menuAccess.isEmpty {
        // No menu data - NO ACCESS
        print("⚠️ No menu access - user has NO access")
        filteredMenuItems = []
    } else {
        // Regular user - filter berdasarkan akses
        print("👤 Regular user - filtering menu")
        filteredMenuItems = filterMenuItemsByAccess(menuItems)
    }

    isLoadingMenu = false
}

private func filterMenuItemsByAccess(_ menuItems: [MenuItem]) -> [MenuItem] {
    var filtered: [MenuItem] = []

    for menu in menuItems {
        // Menu tanpa submenu - check direct access
        if let route = menu.route, menu.subMenus == nil {
            if MenuAccessManager.shared.hasAccess(to: route) {
                filtered.append(menu)
            }
        }
        // Menu dengan submenu - filter submenus
        else if let subMenus = menu.subMenus {
            let filteredSubs = subMenus.filter {
                MenuAccessManager.shared.hasAccess(to: $0.route)
            }

            // Hanya tampilkan parent jika ada submenu yang accessible
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

    return filtered
}
```

**UI States:**

```swift
// Loading state
if isLoadingMenu {
    HStack {
        ProgressView()
        Text("Memuat menu...")
    }
}
// Empty state - user tidak punya akses
else if filteredMenuItems.isEmpty {
    VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
        Text("Tidak ada menu yang dapat diakses")
        Text("Hubungi administrator untuk bantuan")
    }
}
// Display accessible menus
else {
    ForEach(filteredMenuItems) { menu in
        AccordionMenuRow(menu: menu, ...)
    }
}
```

**Lifecycle:**

```swift
.onAppear {
    loadUserMenuAccess()
}
```

---

## 🔐 Sistem Access Control

### Level User:

1. **Level 1 (Superadmin)**

   - ✅ Full access ke semua menu
   - ✅ Tidak perlu fetch dari server
   - ✅ `filteredMenuItems = menuItems` (semua menu)

2. **Level >1 (Regular User)**

   - ✅ Access terbatas berdasarkan `gr_id` (group)
   - ✅ Fetch menu dari GraphQL
   - ✅ Filter menu berdasarkan `mn_url`

3. **No Menu Data**
   - ✅ User TIDAK punya akses ke menu apapun
   - ✅ Tampilkan empty state dengan pesan error
   - ✅ `filteredMenuItems = []`

---

## 📁 Files Modified/Created

### Created:

1. ✅ `vmedismobile/Models/MenuAccess.swift` (250+ lines)
   - Data models
   - URL mapping
   - MenuAccessManager singleton

### Modified:

1. ✅ `vmedismobile/Services/LoginService.swift`

   - Added `aksesMenu` & `aksesMenuHead` to UserData
   - Added `fetchMenuAccess()` function
   - GraphQL integration

2. ✅ `vmedismobile/Views/Pages/MainTabView.swift`
   - Added menu filtering state properties
   - Added `loadUserMenuAccess()` function
   - Added `filterMenuItemsByAccess()` function
   - Updated UI with loading/empty/data states

---

## 🧪 Testing Scenarios

### Test Case 1: Superadmin (lvl=1)

```
✅ Expected: Full access ke semua menu
✅ Behavior:
   - Skip GraphQL fetch
   - filteredMenuItems = all menuItems
   - Semua menu visible
```

### Test Case 2: Regular User dengan Access

```
✅ Expected: Hanya menu yang ter-grant visible
✅ Behavior:
   - Fetch menu dari GraphQL
   - Filter berdasarkan mn_url
   - Hanya menu accessible yang tampil
   - Parent menu hidden jika semua submenu tidak accessible
```

### Test Case 3: Regular User tanpa Access

```
✅ Expected: No menu visible, tampil pesan error
✅ Behavior:
   - menuAccess.isEmpty = true
   - filteredMenuItems = []
   - Empty state displayed
```

### Test Case 4: Offline Mode / Server Error

```
✅ Expected: Gunakan cached menu dari UserDefaults
✅ Behavior:
   - MenuAccessManager.getMenuAccess() load dari cache
   - Filter berdasarkan cached data
   - User tetap bisa akses menu yang pernah di-grant
```

---

## 🔄 Data Flow

```
1. User Login
   ↓
2. LoginService.login()
   ↓
3. Login Success → fetch menu access
   ↓
4. LoginService.fetchMenuAccess(gr_id, lvl, token)
   ↓
5. GraphQL Query → MenuGroupUser
   ↓
6. Parse Response → [MenuAccess]
   ↓
7. MenuAccessManager.saveMenuAccess() → UserDefaults
   ↓
8. Update userData.aksesMenu & userData.aksesMenuHead
   ↓
9. ProfileView.onAppear → loadUserMenuAccess()
   ↓
10. MenuAccessManager.getMenuAccess() → load from cache
   ↓
11. filterMenuItemsByAccess() → filter menu
   ↓
12. Update filteredMenuItems → UI refresh
```

---

## 🐛 Known Issues & Solutions

### Issue 1: ~~Invalid redeclaration of 'MenuGroupUserResponse'~~

**Status:** ✅ FIXED

**Problem:**

- Struct `MenuGroupUserResponse` dideklarasikan 2x (LoginService.swift & MenuAccess.swift)

**Solution:**

- Removed from LoginService.swift
- Created private GraphQL response structs in LoginService
- `MenuAccess` models tetap di `Models/MenuAccess.swift`

### Issue 2: ~~Duplicate `.onAppear` in ProfileView~~

**Status:** ✅ FIXED

**Problem:**

- `.onAppear` ditulis 2x di ProfileView body

**Solution:**

- Merged into single `.onAppear` block

---

## 📝 Code Snippets

### Check User Access

```swift
// Check single route
if MenuAccessManager.shared.hasAccess(to: "lappembelianobat") {
    // User has access to this route
}

// Get all accessible routes
let menuAccess = MenuAccessManager.shared.getMenuAccess()
print("User has access to \(menuAccess.count) menus")
```

### Debug Menu Access

```swift
// Print debug info
MenuAccessManager.shared.printDebugInfo()

// Output:
// 🔐 Menu Access Manager Debug Info:
// Total menu access: 5
// 1. /laporan-penjualan-obat (Laporan Penjualan)
// 2. /obatexpired (Laporan Obat Expired)
// ...
```

### Clear Menu Access (Logout)

```swift
MenuAccessManager.shared.clearMenuAccess()
```

---

## 🚀 Next Steps (Optional Enhancements)

### 1. ⏳ Refresh Menu Access

```swift
// Add pull-to-refresh untuk update menu access tanpa re-login
func refreshMenuAccess() async {
    // Re-fetch dari server
    // Update cache
    // Reload filtered menu
}
```

### 2. ⏳ Menu Access Expiry

```swift
// Add timestamp untuk menu access
// Auto-refresh setelah X hari
struct MenuAccessCache {
    let items: [MenuAccess]
    let timestamp: Date
    let expiryDays: Int = 7
}
```

### 3. ⏳ Offline Indicator

```swift
// Show indicator jika menu dari cache (offline)
if isUsingCachedMenu {
    Text("⚠️ Using cached menu data")
        .font(.caption)
        .foregroundColor(.orange)
}
```

---

## 📚 References

### React Native Implementation:

- File: `vmedis-mobile/app/prologue/config/navigator/Sidemenumap2.js`
- Lines: 183-1342

### GraphQL Schema:

```graphql
type MenuGroupUser {
  Items: [MenuHeader]
  Items1: [MenuItem]
  gak: Boolean
}

type MenuItem {
  mn_url: String
  mn_kode: String
  mn_nama: String
}
```

---

## ✅ Summary

Implementasi sistem leveling menu telah **COMPLETED** dengan fitur:

1. ✅ Fetch menu access dari GraphQL saat login
2. ✅ Save menu access ke local storage (UserDefaults)
3. ✅ Filter menu berdasarkan hak akses user
4. ✅ Support superadmin (full access)
5. ✅ Handle user tanpa akses (empty state)
6. ✅ Loading state indicator
7. ✅ Offline mode support (cached data)
8. ✅ Debug utilities

**No errors found in all files!** 🎉

---

_Last Updated: 2025-01-13_
_Version: 1.0_
