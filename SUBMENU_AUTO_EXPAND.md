# Submenu Auto-Expansion Feature

## ⚠️ CRITICAL FIX - WebView Reload Prevention

**Issue Fixed:** Dashboard WebView berubah/reload saat tap stats card sebelum switch ke tab "Akun"

**Solution Applied:**

1. ✅ Added `.id()` modifier to all WebView tabs untuk preserve state
2. ✅ Added `hasCompletedInitialLoad` tracking di Coordinator
3. ✅ Updated `updateUIView()` logic untuk prevent unnecessary reload

**See:** `WEBVIEW_TAB_SWITCH_FIX.md` untuk detail lengkap

---

## 🎯 Overview

Implementasi fitur auto-expand submenu ketika user klik stats card di WebView. Submenu yang sesuai akan otomatis ter-expand sebelum navigate ke report page.

## ✨ Features Added

### 1. **Submenu Mapping (Web)**

**File:** `src/utils/routeConnector.js`

Added `getStatsSubmenu()` function untuk mapping stats ID ke submenu title:

```javascript
export const getStatsSubmenu = (statsId) => {
  const submenuMap = {
    // Customer Stats → Pendaftaran Klinik submenu
    "pasien-baru": "Pendaftaran Klinik",
    "kunjungan-pasien": "Pendaftaran Klinik",

    // Dashboard Stats → Billing Kasir submenu
    "penjualan-kasir": "Billing Kasir",
    "penjualan-online": "Billing Kasir",
    "pemeriksaan-klinik": "Billing Kasir",

    // Obat Stats → Laporan Apotek submenu
    "obat-expired": "Laporan Apotek",
    "stok-habis": "Laporan Apotek",
    "obat-hilang": "Laporan Apotek",

    // Keuangan Stats → Laporan Apotek/Billing Kasir submenu
    "hutang-jatuh-tempo": "Laporan Apotek",
    "piutang-apotek-jatuh-tempo": "Laporan Apotek",
    "piutang-klinik-jatuh-tempo": "Billing Kasir",
  };

  return submenuMap[statsId] || null;
};
```

### 2. **Stats Carousel Update (Web)**

**File:** `src/sections/mobile/components/StatsCarousel.jsx`

Updated to pass submenu info:

```javascript
const submenuTitle = getStatsSubmenu(stat.id);
const handleClick = isClickable
  ? createStatsNavigationHandler(stat.id, router, { submenu: submenuTitle })
  : undefined;
```

### 3. **Navigation Handler Update (Web)**

**File:** `src/utils/routeConnector.js`

Updated to include submenu in navigation:

```javascript
const submenu = getStatsSubmenu(statsId);
// ...
window.navigateFromStats(statsId, route, { ...filterParams }, submenu);
```

### 4. **iOS Bridge Update**

**File:** `public/assets/scripts/stats-navigation.js`

Updated to accept submenu parameter:

```javascript
window.navigateFromStats = function (
  statsId,
  route,
  filterParams = {},
  submenu = null
) {
  const navigationData = {
    statsId: statsId,
    route: route,
    filterParams: filterParams,
    submenu: submenu, // ✨ New field
    fromStats: statsId,
    timestamp: new Date().toISOString(),
  };
  // ...
};
```

### 5. **Swift Handler Update**

**File:** `vmedismobile/Services/StatsDeepLinkHandler.swift`

Updated to process submenu info:

```swift
func handleStatsNavigation(message: [String: Any]) {
    // ...
    let submenuTitle = message["submenu"] as? String

    // Post notification with submenu info
    NotificationCenter.default.post(
        name: NSNotification.Name("NavigateToReport"),
        object: nil,
        userInfo: [
            "route": swiftRoute,
            "statsId": statsId,
            "submenu": submenuTitle ?? "",  // ✨ New field
            "filters": filterParams ?? [:]
        ]
    )
}
```

### 6. **MainTabView Update**

**File:** `vmedismobile/Views/Pages/MainTabView.swift`

Added submenu state and pass to ProfileView:

```swift
struct MainTabView: View {
    @State private var submenuToExpand: String?

    // Pass to ProfileView
    ProfileView(
        userData: userData,
        navigationRoute: $navigationRoute,
        shouldNavigate: $shouldNavigateToReport,
        submenuToExpand: $submenuToExpand  // ✨ New binding
    )

    // Extract submenu from notification
    private func setupStatsNavigationListener() {
        let submenu = userInfo["submenu"] as? String
        if let submenu = submenu, !submenu.isEmpty {
            self.submenuToExpand = submenu
        }
    }
}
```

### 7. **ProfileView Update**

**File:** `vmedismobile/Views/Pages/MainTabView.swift`

Added auto-expand logic:

```swift
struct ProfileView: View {
    @Binding var submenuToExpand: String?

    var body: some View {
        NavigationView {
            // ...
        }
        .onChange(of: submenuToExpand) { newSubmenu in
            if let submenu = newSubmenu {
                // Find menu dengan title yang match
                if let menuToExpand = menuItems.first(where: { $0.title == submenu }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expandedMenuIds.insert(menuToExpand.id)
                    }
                }
            }
        }
    }
}
```

## 🔄 Navigation Flow

```
User Click Stats Card
    ↓
Get Submenu Title (getStatsSubmenu)
    ↓
Pass to Navigation Handler
    ↓
Send via WebKit Bridge (with submenu)
    ↓
StatsDeepLinkHandler receives submenu
    ↓
Post Notification (with submenu)
    ↓
MainTabView extracts submenu
    ↓
Pass to ProfileView via binding
    ↓
ProfileView .onChange triggers
    ↓
Find matching menu by title
    ↓
Auto-expand submenu (animated)
    ↓
Navigate to report page
```

## 📊 Submenu Mappings

| Stats ID                     | Submenu Title      |
| ---------------------------- | ------------------ |
| **Customer**                 |                    |
| `pasien-baru`                | Pendaftaran Klinik |
| `kunjungan-pasien`           | Pendaftaran Klinik |
| **Dashboard**                |                    |
| `penjualan-kasir`            | Billing Kasir      |
| `penjualan-online`           | Billing Kasir      |
| `pemeriksaan-klinik`         | Billing Kasir      |
| **Obat**                     |                    |
| `obat-expired`               | Laporan Apotek     |
| `stok-habis`                 | Laporan Apotek     |
| `obat-hilang`                | Laporan Apotek     |
| **Keuangan**                 |                    |
| `hutang-jatuh-tempo`         | Laporan Apotek     |
| `piutang-apotek-jatuh-tempo` | Laporan Apotek     |
| `piutang-klinik-jatuh-tempo` | Billing Kasir      |

## 🧪 Testing Guide

### Test Steps:

1. Open iOS app
2. Navigate to Dashboard/Obat/Keuangan/Customer page
3. Click a stats card
4. **Verify:**
   - ✅ App switches to "Akun" tab
   - ✅ Correct submenu auto-expands with animation
   - ✅ Report page opens
   - ✅ Can navigate back

### Debug Logs:

**Web (Console):**

```
📊 Navigating from stats [penjualan-kasir] to: /mobile/laporan-penjualan-obat
📂 Will expand submenu: Billing Kasir
📱 Using iOS navigation bridge
```

**Swift (Xcode):**

```
📨 Received stats navigation message
📊 Processing stats navigation:
   Submenu: Optional("Billing Kasir")
✅ Mapped to Swift route: lappenjualanobat
🚀 Navigation triggered
📂 Should expand submenu: Billing Kasir
📱 MainTabView received navigation request
📂 Expanding submenu: Billing Kasir
✅ Submenu expanded: Billing Kasir
🎯 ProfileView triggering navigation
```

## 🐛 Troubleshooting

### Issue 1: Submenu tidak expand

**Check:**

- Submenu title di web exact match dengan Swift menu title
- `submenuToExpand` binding passed correctly
- `.onChange(of: submenuToExpand)` handler triggered

**Solution:**

```swift
// Verify menu titles match exactly
let menuItems = [
    MenuItem(title: "Billing Kasir", ...), // Must match web mapping
]
```

### Issue 2: Animation tidak smooth

**Check:**

- `withAnimation` wrapper ada
- Delay timing appropriate

**Solution:**

```swift
withAnimation(.easeInOut(duration: 0.3)) {
    expandedMenuIds.insert(menuToExpand.id)
}
```

### Issue 3: Submenu expand tapi tidak navigate

**Check:**

- Navigation delay setelah expand
- State reset timing

**Solution:**
Already handled dengan sequential `.onChange` handlers

## 📁 Files Modified

### React Web (3 files):

1. ✅ `src/utils/routeConnector.js`

   - Added `getStatsSubmenu()` function
   - Updated `createStatsNavigationHandler()` to pass submenu

2. ✅ `src/sections/mobile/components/StatsCarousel.jsx`

   - Import `getStatsSubmenu`
   - Pass submenu to navigation handler

3. ✅ `public/assets/scripts/stats-navigation.js`
   - Added `submenu` parameter
   - Updated `navigationData` structure

### Swift iOS (3 files):

1. ✅ `vmedismobile/Services/StatsDeepLinkHandler.swift`

   - Extract submenu from message
   - Pass submenu in notification

2. ✅ `vmedismobile/Views/Pages/MainTabView.swift`

   - Added `submenuToExpand` state
   - Extract submenu from notification
   - Pass to ProfileView

3. ✅ `vmedismobile/Views/Pages/ProfileView` (in MainTabView.swift)
   - Added `submenuToExpand` binding
   - Added `.onChange(of: submenuToExpand)` handler
   - Auto-expand logic with animation

## ✅ Benefits

### User Experience:

- ✅ **Context Aware**: User sees where the report is located in menu
- ✅ **Smooth Animation**: Professional expand animation
- ✅ **No Confusion**: Clear visual indication of report location
- ✅ **Better Navigation**: Easy to find related reports in same submenu

### Technical:

- ✅ **Clean Implementation**: Reuses existing menu structure
- ✅ **Type-Safe**: Swift title matching
- ✅ **Maintainable**: Single source of truth for mapping
- ✅ **Extensible**: Easy to add more submenu mappings

## 🎯 Next Steps

### Enhancements:

- [ ] Scroll to expanded submenu if off-screen
- [ ] Highlight the specific report in submenu
- [ ] Add haptic feedback on expand
- [ ] Persist expanded state on back navigation

### Testing:

- [ ] Test all 10 stats mappings
- [ ] Verify animation performance
- [ ] Test rapid navigation
- [ ] Edge case handling

---

**Status:** ✅ Implementation Complete  
**Date:** October 11, 2025  
**Coverage:** 10/10 stats with submenu mapping
