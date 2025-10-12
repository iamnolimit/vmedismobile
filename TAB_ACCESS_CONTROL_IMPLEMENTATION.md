# 🔐 Implementasi Access Control untuk Semua Tab

## 📋 Overview

Sistem access control telah diperluas untuk **semua tab**, bukan hanya tab Akun. Setiap tab (Home, Obat, Keuangan, Forecast, Akun) sekarang memiliki pengecekan hak akses berdasarkan data dari server.

---

## 🎯 Changes Made

### 1. **Update MenuAccess.swift - Tab Mapping**

**File:** `vmedismobile/Models/MenuAccess.swift`

**Tambahan Mapping untuk Tab Utama:**

```swift
static let routeToURL: [String: String] = [
    // Main Tabs - untuk check access ke tab utama
    "home": "/home",
    "products": "/produk",         // Tab Obat
    "orders": "/transaksi",        // Tab Keuangan
    "forecast": "/forecast",       // Tab Forecast
    "account": "/akun",            // Tab Akun (always accessible)

    // ... existing mappings untuk laporan-laporan ...
]
```

**Fungsi Baru:**

```swift
/// Check apakah user punya akses ke tab utama
func hasTabAccess(to tabName: String) -> Bool {
    // Tab Akun selalu accessible (untuk logout dll)
    if tabName == "account" {
        return true
    }

    // Check menggunakan hasAccess dengan mapping tab
    return hasAccess(to: tabName)
}

/// Get list tab yang accessible oleh user
func getAccessibleTabs() -> [String] {
    let allTabs = ["home", "products", "orders", "forecast", "account"]
    return allTabs.filter { hasTabAccess(to: $0) }
}
```

---

### 2. **Update MainTabView.swift - Conditional Tab Rendering**

**File:** `vmedismobile/Views/Pages/MainTabView.swift`

**State Properties Baru:**

```swift
struct MainTabView: View {
    let userData: UserData
    @State private var selectedTab = 0
    @State private var previousTab: Int? = nil
    @State private var navigationRoute: String?
    @State private var shouldNavigateToReport = false
    @State private var submenuToExpand: String?

    // NEW: Tab access control
    @State private var accessibleTabs: [String] = []
    @State private var isCheckingAccess = true

    // ...
}
```

**Loading State:**

```swift
var body: some View {
    if isCheckingAccess {
        // Loading state saat check access
        VStack {
            ProgressView()
            Text("Memeriksa akses...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkTabAccess()
        }
    } else {
        // TabView dengan conditional rendering
        TabView(selection: $selectedTab) {
            // Conditional tabs...
        }
    }
}
```

**Conditional Tab Rendering:**

```swift
TabView(selection: $selectedTab) {
    // 1. Home Tab - conditional
    if accessibleTabs.contains("home") {
        LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
            .id("home-tab")
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("Home")
            }
            .tag(0)
    }

    // 2. Obat Tab - conditional
    if accessibleTabs.contains("products") {
        LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
            .id("obat-tab")
            .tabItem {
                Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                Text("Obat")
            }
            .tag(1)
    }

    // 3. Keuangan Tab - conditional
    if accessibleTabs.contains("orders") {
        LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=orders")
            .id("keuangan-tab")
            .tabItem {
                Image(systemName: selectedTab == 2 ? "banknote.fill" : "banknote")
                Text("Keuangan")
            }
            .tag(2)
    }

    // 4. Forecast Tab - conditional
    if accessibleTabs.contains("forecast") {
        LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=forecast")
            .id("forecast-tab")
            .tabItem {
                Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                Text("Forecast")
            }
            .tag(3)
    }

    // 5. Account Tab - always accessible
    ProfileView(...)
        .tabItem {
            Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
            Text("Akun")
        }
        .tag(4)
}
```

**Function checkTabAccess():**

```swift
private func checkTabAccess() {
    print("🔐 Checking tab access for user...")

    let userLevel = userData.lvl ?? 999

    // Superadmin (lvl=1) - full access ke semua tab
    if userLevel == 1 {
        print("👑 Superadmin detected - granting full tab access")
        accessibleTabs = ["home", "products", "orders", "forecast", "account"]
        isCheckingAccess = false
        return
    }

    // Load menu access dari MenuAccessManager
    let menuAccess = MenuAccessManager.shared.getMenuAccess()

    // Jika tidak ada menu access data
    if menuAccess.isEmpty {
        print("⚠️ No menu access data - granting default tabs")
        // Default: hanya tab Akun yang accessible
        accessibleTabs = ["account"]
        isCheckingAccess = false
        return
    }

    // Regular user - check akses per tab
    accessibleTabs = MenuAccessManager.shared.getAccessibleTabs()

    print("✅ Accessible tabs for user: \(accessibleTabs)")
    print("   - Home: \(accessibleTabs.contains("home") ? "✓" : "✗")")
    print("   - Obat: \(accessibleTabs.contains("products") ? "✓" : "✗")")
    print("   - Keuangan: \(accessibleTabs.contains("orders") ? "✓" : "✗")")
    print("   - Forecast: \(accessibleTabs.contains("forecast") ? "✓" : "✗")")
    print("   - Akun: ✓ (always)")

    isCheckingAccess = false
}
```

---

## 🔐 Access Control Logic

### Level User:

1. **Level 1 (Superadmin)**

   - ✅ Full access ke **semua tab** (Home, Obat, Keuangan, Forecast, Akun)
   - ✅ Full access ke **semua menu** di tab Akun
   - ✅ Tidak perlu fetch dari server

2. **Level >1 (Regular User)**

   - ✅ Access terbatas berdasarkan `gr_id` (group)
   - ✅ Fetch menu access dari GraphQL
   - ✅ Filter tab berdasarkan mapping:
     - `home` → `/home`
     - `products` → `/produk`
     - `orders` → `/transaksi`
     - `forecast` → `/forecast`
   - ✅ Tab yang tidak accessible **tidak ditampilkan** di tab bar

3. **No Menu Data**
   - ✅ User hanya punya akses ke **Tab Akun** saja
   - ✅ Tab lainnya hidden
   - ✅ Di tab Akun, tampilkan empty state

---

## 🎬 User Experience Flow

### Scenario 1: Superadmin Login

```
1. User login (lvl=1)
   ↓
2. checkTabAccess() deteksi superadmin
   ↓
3. accessibleTabs = ["home", "products", "orders", "forecast", "account"]
   ↓
4. Semua 5 tab ditampilkan di tab bar
   ↓
5. User bisa akses semua tab dan semua menu
```

### Scenario 2: Regular User dengan Access Terbatas

```
1. User login (lvl>1)
   ↓
2. Fetch menu access dari GraphQL
   ↓
3. Parse response: user punya akses ke /home, /produk, /akun
   ↓
4. checkTabAccess() filter tabs
   ↓
5. accessibleTabs = ["home", "products", "account"]
   ↓
6. Hanya 3 tab ditampilkan: Home, Obat, Akun
   ↓
7. Tab Keuangan & Forecast hidden
```

### Scenario 3: User tanpa Access

```
1. User login (lvl>1)
   ↓
2. Fetch menu access dari GraphQL → empty
   ↓
3. checkTabAccess() deteksi no access
   ↓
4. accessibleTabs = ["account"]
   ↓
5. Hanya 1 tab ditampilkan: Akun
   ↓
6. Di tab Akun, tampil empty state
```

---

## 📊 Tab Mapping to Server URLs

| Tab Name | Route Key  | Server URL   | Description                        |
| -------- | ---------- | ------------ | ---------------------------------- |
| Home     | `home`     | `/home`      | Dashboard utama                    |
| Obat     | `products` | `/produk`    | Manajemen produk obat              |
| Keuangan | `orders`   | `/transaksi` | Transaksi keuangan                 |
| Forecast | `forecast` | `/forecast`  | Prediksi & analisis                |
| Akun     | `account`  | `/akun`      | Profile & menu (always accessible) |

---

## 🧪 Testing Scenarios

### Test Case 1: Superadmin Full Access

```swift
Input:
- lvl = 1

Expected:
- All 5 tabs visible
- All menus in Akun tab visible

Console Output:
🔐 Checking tab access for user...
👑 Superadmin detected - granting full tab access
✅ Accessible tabs for user: ["home", "products", "orders", "forecast", "account"]
   - Home: ✓
   - Obat: ✓
   - Keuangan: ✓
   - Forecast: ✓
   - Akun: ✓
```

### Test Case 2: User dengan Akses Home & Obat

```swift
Input:
- lvl = 2
- menuAccess = ["/home", "/produk"]

Expected:
- 3 tabs visible: Home, Obat, Akun
- Keuangan & Forecast hidden

Console Output:
🔐 Checking tab access for user...
✅ Accessible tabs for user: ["home", "products", "account"]
   - Home: ✓
   - Obat: ✓
   - Keuangan: ✗
   - Forecast: ✗
   - Akun: ✓
```

### Test Case 3: User tanpa Akses

```swift
Input:
- lvl = 2
- menuAccess = []

Expected:
- 1 tab visible: Akun only
- Empty state in Akun tab

Console Output:
🔐 Checking tab access for user...
⚠️ No menu access data - granting default tabs
✅ Accessible tabs for user: ["account"]
   - Home: ✗
   - Obat: ✗
   - Keuangan: ✗
   - Forecast: ✗
   - Akun: ✓
```

---

## 🎨 UI States

### 1. Loading State (isCheckingAccess = true)

```
┌─────────────────────────┐
│                         │
│      ProgressView       │
│   "Memeriksa akses..."  │
│                         │
└─────────────────────────┘
```

### 2. Full Access (Superadmin)

```
┌─────────────────────────┐
│  [Home] [Obat] [€] [📊] [👤]  │
└─────────────────────────┘
   5 tabs visible
```

### 3. Limited Access (Regular User)

```
┌─────────────────────────┐
│  [Home] [Obat]      [👤]  │
└─────────────────────────┘
   3 tabs visible (2 hidden)
```

### 4. No Access (Account Only)

```
┌─────────────────────────┐
│              [👤]       │
└─────────────────────────┘
   1 tab visible (4 hidden)
```

---

## 🔧 Configuration

### Untuk Menambah Tab Baru dengan Access Control:

1. **Tambah mapping di MenuURLMapping:**

```swift
static let routeToURL: [String: String] = [
    // ...existing...
    "newtab": "/new-tab-url",
]
```

2. **Tambah di allTabs array:**

```swift
func getAccessibleTabs() -> [String] {
    let allTabs = ["home", "products", "orders", "forecast", "newtab", "account"]
    return allTabs.filter { hasTabAccess(to: $0) }
}
```

3. **Tambah conditional rendering di TabView:**

```swift
if accessibleTabs.contains("newtab") {
    NewTabView(userData: userData)
        .id("newtab-tab")
        .tabItem {
            Image(systemName: "icon.name")
            Text("New Tab")
        }
        .tag(5) // Next available tag
}
```

---

## 📈 Performance Impact

- **Minimal**: Check access dilakukan sekali saat app launch
- **Cached**: Menu access data di-cache di UserDefaults
- **Fast**: Conditional rendering menggunakan native SwiftUI
- **Smooth**: Loading state mencegah flicker

---

## 🔄 Data Persistence

- Menu access di-cache di UserDefaults
- Persistent across app restarts
- Cleared on logout
- Updated on login

---

## ✅ Summary

### Completed:

1. ✅ Tambah tab mapping untuk Home, Obat, Keuangan, Forecast
2. ✅ Fungsi `hasTabAccess()` untuk check akses per tab
3. ✅ Fungsi `getAccessibleTabs()` untuk get list accessible tabs
4. ✅ Update MainTabView dengan conditional rendering
5. ✅ Loading state saat check access
6. ✅ Function `checkTabAccess()` dengan logic lengkap
7. ✅ Support untuk superadmin, regular user, dan no access
8. ✅ Tab Akun always accessible (untuk logout)

### Benefits:

- 🔐 **Security**: User hanya bisa akses tab yang di-grant
- 🎨 **Clean UI**: Tab yang tidak accessible tidak ditampilkan
- 🚀 **Performance**: Fast check dengan cached data
- 👤 **UX**: Loading state mencegah confusion

---

_Last Updated: 2025-01-13_
_Version: 2.0 - Full Tab Access Control_
