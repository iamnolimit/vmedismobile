# WebView Tab Switch Fix - Prevent Dashboard Reload

## 🐛 Problem

Ketika user tap stats card di Home tab (dashboard), tampilan dashboard **berubah/reload** sebelum switch ke tab "Akun". Ini memberikan UX yang buruk karena user melihat perubahan visual yang tidak diinginkan.

### Root Cause

1. **TabView Re-render**: Saat `selectedTab` berubah dari 0 (Home) ke 4 (Akun), SwiftUI me-trigger `updateUIView()` di semua tab
2. **WebView Reload Logic**: `BypassWebView.updateUIView()` selalu reload jika URL berubah, termasuk saat tab switch
3. **No State Preservation**: WebView tidak memiliki stable identity, sehingga bisa di-recreate saat tab change

## ✅ Solution

### 1. **Add Stable View Identity**

Tambahkan `.id()` modifier ke setiap tab WebView untuk preserve state:

```swift
// File: Views/Pages/MainTabView.swift

TabView(selection: $selectedTab) {
    // 1. Home Tab
    LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
        .id("home-tab") // ✅ Preserve WebView state
        .tabItem { ... }
        .tag(0)

    // 2. Obat Tab
    LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
        .id("obat-tab") // ✅ Preserve WebView state
        .tabItem { ... }
        .tag(1)

    // ... semua tab mendapat unique ID
}
```

**Why it works:**

- `.id()` memberikan stable identity ke view
- SwiftUI tidak akan recreate view jika ID sama
- WebView instance tetap hidup saat tab switch

### 2. **Smart Reload Prevention**

Update `BypassWebView` untuk hanya reload saat URL **benar-benar berubah**:

```swift
// File: Services/BypassWebView.swift

class Coordinator: NSObject, WKScriptMessageHandler {
    // ... existing properties
    var hasCompletedInitialLoad = false // ✅ Track initial load

    func loadBypassUrl() {
        loadTask = Task { @MainActor in
            do {
                // ... load logic
                webView?.load(request)

                // ✅ Mark initial load as complete
                hasCompletedInitialLoad = true

            } catch {
                // ... fallback logic
                webView?.load(request)

                // ✅ Also mark for fallback
                hasCompletedInitialLoad = true
            }
        }
    }
}
```

### 3. **Conditional Update Logic**

Ubah `updateUIView()` untuk prevent unnecessary reload:

```swift
// File: Services/BypassWebView.swift

func updateUIView(_ uiView: WKWebView, context: Context) {
    // ✅ Prevent reload on tab switch or view updates
    // Only reload if destinationUrl actually changed AND we've loaded before
    guard let currentUrl = uiView.url?.absoluteString else {
        return
    }

    // Check if we need to reload based on actual URL change
    let needsReload = !currentUrl.contains(destinationUrl)

    if needsReload && context.coordinator.hasCompletedInitialLoad {
        print("🔄 BypassWebView: Reloading due to URL change")
        context.coordinator.loadBypassUrl()
    }
}
```

**Why it works:**

- `hasCompletedInitialLoad` prevents reload during initial setup
- URL check ensures we only reload on actual destination change
- Tab switch tidak trigger reload karena URL masih sama

## 📊 Impact

### Before Fix:

1. User tap stats card di Home tab
2. ❌ Dashboard berubah/reload (visual glitch)
3. Tab switch ke "Akun"
4. Submenu auto-expand
5. Navigate ke report

### After Fix:

1. User tap stats card di Home tab
2. ✅ Dashboard tetap stabil (no reload)
3. Tab switch ke "Akun"
4. Submenu auto-expand
5. Navigate ke report

## 🔍 Technical Details

### State Preservation Flow

```
Tab 0 (Home) Selected
├── WebView.id("home-tab") created
├── Initial URL loaded
└── hasCompletedInitialLoad = true

Stats Card Tapped
├── selectedTab changes: 0 → 4
├── TabView re-renders
├── Tab 0 WebView preserved (due to .id())
├── updateUIView() called but skipped (URL same, has loaded)
└── Tab 4 (Akun) displayed

Result: No visual change on Home tab ✅
```

### Reload Decision Logic

```swift
// Decision tree for reload:
if currentUrl == nil {
    return // No reload
}

if !currentUrl.contains(destinationUrl) {
    // URL mismatch
    if hasCompletedInitialLoad {
        reload() // Only reload if we've loaded before
    }
} else {
    // URL matches - skip reload
}
```

## 🧪 Testing

### Test Case 1: Stats Navigation

1. ✅ Buka app di Home tab
2. ✅ Tap stats card (e.g., "Pasien Baru")
3. ✅ Verify: Dashboard tidak berubah
4. ✅ Verify: Tab switch ke "Akun"
5. ✅ Verify: Submenu "Pendaftaran Klinik" expand
6. ✅ Verify: Navigate ke report

### Test Case 2: Normal Tab Switch

1. ✅ Switch dari Home → Obat
2. ✅ Verify: Obat tab load normal
3. ✅ Switch dari Obat → Home
4. ✅ Verify: Home tab preserved (no reload)

### Test Case 3: Manual Refresh

1. ✅ Pull to refresh di Home tab
2. ✅ Verify: WebView reload correctly
3. ✅ hasCompletedInitialLoad remains true

## 📝 Files Modified

1. **MainTabView.swift**

   - Added `.id()` to all WebView tabs
   - Lines: 13, 21, 29, 37

2. **BypassWebView.swift**
   - Added `hasCompletedInitialLoad` flag in Coordinator
   - Updated `loadBypassUrl()` to set flag after load
   - Updated `updateUIView()` with smart reload logic
   - Lines: 60, 108, 129, 133-142

## 🎯 Key Takeaways

1. **SwiftUI TabView Re-render**: Saat tab berubah, semua tab views di-trigger `updateUIView()`
2. **View Identity Matters**: Gunakan `.id()` untuk preserve view state across updates
3. **Smart Reload**: Track load state untuk prevent unnecessary reloads
4. **Guard Against Tab Switch**: Jangan reload hanya karena parent view re-render

## 🚀 Next Steps

- [x] Fix WebView reload on tab switch
- [x] Preserve WebView state dengan `.id()`
- [x] Add smart reload logic
- [ ] Test dengan semua 10 stats cards
- [ ] Monitor performance impact
- [ ] Consider adding WebView caching strategy (optional)

---

**Status**: ✅ Fixed
**Date**: October 11, 2025
**Impact**: High (UX improvement)
