# Stats to Native Navigation - Quick Reference

## 🚀 Quick Start

### For Testing

1. Open iOS app
2. Navigate to any tab with stats (Home, Obat, Keuangan, Customer)
3. Click any stats card
4. **Expected Result**: App switches to "Akun" tab and opens the report

---

## 📊 Route Reference

### Dashboard Stats

```
penjualan-kasir          → Laporan Penjualan Obat
penjualan-online         → Laporan Penjualan Obat
pemeriksaan-klinik       → Laporan Pembayaran Kasir
```

### Obat Stats

```
obat-expired             → Laporan Obat Expired
stok-habis              → Laporan Obat Stok Habis
obat-hilang             → Laporan Stok Opname
```

### Keuangan Stats

```
hutang-jatuh-tempo              → Laporan Hutang Obat
piutang-apotek-jatuh-tempo      → Laporan Piutang Obat
piutang-klinik-jatuh-tempo      → Laporan Piutang Klinik
```

### Customer Stats

```
pasien-baru             → Laporan Registrasi Pasien
kunjungan-pasien        → Laporan Kunjungan Pasien
```

---

## 🔍 Debug Logs

### Success Flow

```
📨 Received stats navigation message
📊 Processing stats navigation
✅ Mapped to Swift route: lappenjualanobat
🚀 Navigation triggered
📱 MainTabView received navigation request
✅ Navigation state set
🎯 ProfileView triggering navigation
```

### Error Indicators

```
❌ Invalid deep link data          → Missing statsId or route
❌ Unknown route                    → Route not in mapping
❌ Failed to process deep link      → General processing error
```

---

## 🛠️ Key Files

### Swift Implementation

```
vmedismobile/Services/
  ├── StatsDeepLinkHandler.swift    (Route mapper & handler)
  └── BypassWebView.swift            (Message receiver)

vmedismobile/Views/Pages/
  └── MainTabView.swift              (Navigation coordinator)
```

### React Implementation

```
src/utils/
  └── routeConnector.js              (Route definitions)

src/sections/mobile/
  ├── config/reusableDashboardConfigs.js  (Stats IDs)
  └── components/StatsCarousel.jsx        (Click handler)

public/assets/scripts/
  └── stats-navigation.js            (iOS bridge)
```

---

## 🔧 Troubleshooting

### Navigation Not Working?

1. **Check Console Logs**

   ```
   Should see: 📨 Received stats navigation message
   If not: Message handler not registered
   ```

2. **Check Tab Switch**

   ```
   Should see: 📱 MainTabView received navigation request
   If not: Notification not posted/received
   ```

3. **Check Navigation Trigger**
   ```
   Should see: 🎯 ProfileView triggering navigation
   If not: Binding not working or state not set
   ```

### Quick Fixes

**Issue**: Stats click does nothing
**Fix**: Check WebView message handler is registered in `BypassWebView.swift`

**Issue**: Tab doesn't switch
**Fix**: Verify `selectedTab = 4` in `MainTabView.setupStatsNavigationListener()`

**Issue**: Report page doesn't open
**Fix**: Check binding in `ProfileView` and `navigateToRoute` state

---

## 📱 Manual Test Checklist

- [ ] Click "Penjualan Kasir" → Opens "Penjualan Obat"
- [ ] Click "Obat Expired" → Opens "Obat Expired"
- [ ] Click "Hutang Jatuh Tempo" → Opens "Hutang Obat"
- [ ] Click "Pasien Baru" → Opens "Registrasi Pasien"
- [ ] Back button works correctly
- [ ] Tab bar is accessible after navigation
- [ ] Can navigate multiple times
- [ ] State resets properly

---

## 💡 Key Components

### 1. StatsRouteMapper

```swift
static let routeMap: [String: String] = [
    "/mobile/laporan-penjualan-obat": "lappenjualanobat",
    // ... more mappings
]
```

### 2. Message Handler

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    if message.name == "navigateToReport" {
        StatsDeepLinkHandler.shared.handleStatsNavigation(message: message.body)
    }
}
```

### 3. Navigation Trigger

```swift
NotificationCenter.default.post(
    name: NSNotification.Name("NavigateToReport"),
    object: nil,
    userInfo: ["route": swiftRoute]
)
```

### 4. Tab Switch

```swift
NotificationCenter.default.addObserver { notification in
    self.selectedTab = 4  // Switch to Akun
    self.navigationRoute = route
    self.shouldNavigateToReport = true
}
```

### 5. Programmatic Navigation

```swift
NavigationLink(
    destination: navigateToRoute.map { route in
        ReportPageView(userData: userData, route: route)
    },
    isActive: .constant(navigateToRoute != nil),
    label: { EmptyView() }
)
```

---

## 📋 Implementation Checklist

### Code Implementation ✅

- [x] Route mapper created
- [x] Message handler registered
- [x] Notification system setup
- [x] Tab switching implemented
- [x] Programmatic navigation added
- [x] State management complete
- [x] Error handling added
- [x] Logging implemented

### Quality Assurance ✅

- [x] No compilation errors
- [x] No warnings
- [x] Type safety maintained
- [x] Memory management proper
- [x] Code documented

### Testing ⏳

- [ ] Device testing
- [ ] All routes tested
- [ ] Performance verified
- [ ] Edge cases covered

---

## 🎯 Expected Behavior

1. **User clicks stats card in WebView**
2. **App automatically switches to "Akun" tab**
3. **Report page opens in native Swift**
4. **User can navigate back to profile menu**
5. **Can repeat process for other stats**

---

## 📞 Quick Support

### Get Route Mapping

```swift
StatsRouteMapper.getSwiftRoute(from: reactRoute)
```

### Check Handler Registration

```swift
config.userContentController.add(coordinator, name: "navigateToReport")
```

### Verify Notification

```swift
NotificationCenter.default.post(
    name: NSNotification.Name("NavigateToReport"),
    object: nil,
    userInfo: ["route": route]
)
```

---

## 🔗 Related Docs

- `IMPLEMENTATION_COMPLETE_SUMMARY.md` - Full implementation details
- `STATS_TO_NATIVE_NAVIGATION.md` - Technical guide
- `STATS_NAVIGATION_GUIDE.md` - Web implementation
- `STATS_NATIVE_NAV_COMMIT.md` - Commit message

---

_Quick Reference | Last Updated: Oct 10, 2025_
