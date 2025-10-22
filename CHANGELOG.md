# Changelog - Multi-Session Revisi

## 🔄 Revisi yang Dilakukan (October 22, 2025)

### 1️⃣ Fix: Akun Aktif Tetap Tersimpan Saat Tambah Akun Baru

#### Problem:

- Saat klik "Tambah Akun", user logout dan session aktif terhapus
- User harus login ulang ke akun lama jika ingin kembali

#### Solution:

**File:** `Views/Pages/MainTabView.swift` - `AddAccountSheet`

**Before:**

```swift
appState.logout()  // ❌ Menghapus current session
```

**After:**

```swift
// Set flag agar session tetap tersimpan
appState.isLoggedIn = false
appState.userData = nil
// Don't call logout() karena itu akan remove session
```

**Impact:**

- ✅ Session aktif tetap tersimpan saat tambah akun baru
- ✅ User bisa switch kembali ke akun lama tanpa login ulang
- ✅ Counter tetap akurat

---

### 2️⃣ UI Improvement: Switch Akun dengan Dropdown

#### Problem:

- Semua akun ditampilkan dalam list panjang
- Tombol "Ganti" pada setiap akun memenuhi ruang
- Tidak efisien untuk banyak akun

#### Solution:

**Files Modified:**

1. `Views/Pages/MainTabView.swift` - `AccountManagementSection`
2. Added: `AccountSwitchRow` component

**New UI Structure:**

```
┌────────────────────────────────────┐
│ Kelola Akun           [+ Tambah]   │
│ 2/5 akun tersimpan                 │
├────────────────────────────────────┤
│ 🟦 Current User   [Aktif]   [🗑️]  │  ← Active account
│    Domain Name                     │
├────────────────────────────────────┤
│ 🔄 Ganti Akun                   ▼  │  ← Dropdown button
│   ┌──────────────────────────────┐ │
│   │ 👤 Other User 1       [🗑️]  │ │  ← Tap to switch
│   │    Domain 1                  │ │
│   ├──────────────────────────────┤ │
│   │ 👤 Other User 2       [🗑️]  │ │
│   │    Domain 2                  │ │
│   └──────────────────────────────┘ │
└────────────────────────────────────┘
```

**Features:**

- ✅ Dropdown "Ganti Akun" dengan chevron indicator
- ✅ Expand/collapse dengan smooth animation
- ✅ Hanya akun aktif yang tampil di atas
- ✅ Akun lain di dalam dropdown
- ✅ Tap anywhere pada row untuk switch
- ✅ Delete icon tetap tersedia di setiap row

**Components:**

1. **AccountManagementSection** (Updated):

   - State: `showingSwitchAccountDropdown`
   - Hanya tampilkan active session di atas
   - Dropdown button dengan icon & chevron
   - Filter sessions yang tidak aktif untuk dropdown

2. **AccountSessionRow** (Updated):

   - Hanya untuk active account
   - Hapus tombol "Ganti" (tidak perlu)
   - Hanya tampilkan delete button

3. **AccountSwitchRow** (NEW):
   - Komponen untuk item di dropdown
   - Avatar lebih kecil (36x36)
   - Tap gesture untuk switch
   - Delete button

**Animation:**

```swift
withAnimation(.spring(response: 0.3)) {
    showingSwitchAccountDropdown.toggle()
}
```

---

## 🔥 Critical Fix: Menu Access Isolation Per Session (October 22, 2025)

### Problem: Menu Access Swap Between Accounts ❌

**Symptom:**

- Login akun A (Superadmin, full access)
- Tambah akun B (Regular user, limited menu)
- Switch A → B: Correct ✅
- Switch B → A: **Mendapat menu B instead of full access** ❌

**Root Cause:**
`MainTabView.loadUserMenuAccess()` menyimpan menu ke **global UserDefaults** via `MenuAccessManager`, causing cross-contamination between sessions.

### Solution: Session-Scoped Menu Access ✅

**Approach:** Hapus dependency ke UserDefaults. Menu access dibaca langsung dari `userData.aksesMenu` yang sudah di-persist per session.

#### Files Modified:

**1. MainTabView.swift - loadUserMenuAccess()**

```swift
// BEFORE: Save to global UserDefaults ❌
MenuAccessManager.shared.saveMenuAccess(menuAccessItems)
let menuAccess = MenuAccessManager.shared.getMenuAccess()

// AFTER: Use local data directly ✅
userMenuAccess = menuAccessItems
// Read directly from userData.aksesMenu
```

**2. MainTabView.swift - filterMenuItemsByAccess()**

```swift
// BEFORE: Read from global storage ❌
if MenuAccessManager.shared.hasAccess(to: route) { ... }

// AFTER: Use local userMenuAccess ✅
let accessibleUrls = Set(userMenuAccess.map { $0.mn_url })
private func hasLocalAccess(to route: String, accessibleUrls: Set<String>) -> Bool {
    guard let mnUrl = MenuURLMapping.getURL(for: route) else { return false }
    return accessibleUrls.contains(mnUrl)
}
```

**3. MainTabView.swift - checkTabAccess()**

```swift
// BEFORE: Read from MenuAccessManager ❌
let menuAccess = MenuAccessManager.shared.getMenuAccess()
accessibleTabs = MenuAccessManager.shared.getAccessibleTabs()

// AFTER: Read from userData.aksesMenu ✅
guard let aksesMenu = userData.aksesMenu, !aksesMenu.isEmpty else { ... }
accessibleTabs = allTabs.filter { tabName in
    if let mnUrl = MenuURLMapping.getURL(for: tabName) {
        return aksesMenu.contains(mnUrl)
    }
    return false
}
```

**4. AppState.swift - switchAccount()**

- Enhanced logging untuk debugging menu access

**5. SessionManager.swift - loadSessions()**

- Enhanced logging untuk verify persistence

### Impact:

- ✅ **Menu access sekarang isolated per session**
- ✅ **No cross-contamination between accounts**
- ✅ **Single source of truth: userData.aksesMenu**
- ✅ **Superadmin tetap dapat full access setelah switch**
- ✅ **Regular user tetap dapat limited access setelah switch**

### Documentation:

- Created: `FIX_MENU_ACCESS_ISOLATION.md` - Complete technical details

---

## 📝 Code Changes Summary

### File: `MainTabView.swift`

#### 1. AccountManagementSection

```swift
// Added state
@State private var showingSwitchAccountDropdown = false

// Changed from ForEach all sessions to:
if let activeSession = sessionManager.activeSession {
    AccountSessionRow(...)  // Only active
}

if sessionManager.sessions.count > 1 {
    Button("Ganti Akun") {
        withAnimation {
            showingSwitchAccountDropdown.toggle()
        }
    }

    if showingSwitchAccountDropdown {
        ForEach(non-active sessions) {
            AccountSwitchRow(...)
        }
    }
}
```

#### 2. AccountSessionRow

```swift
// Removed:
- Switch button logic
- Conditional switch button display

// Kept:
- Delete button (for active account only)
- Active badge
- Blue border
```

#### 3. AccountSwitchRow (NEW)

```swift
struct AccountSwitchRow: View {
    // Smaller avatar (36x36)
    // Tap gesture to switch
    // Delete button
    // Simplified layout
}
```

#### 4. AddAccountSheet

```swift
// Changed logout logic:
appState.isLoggedIn = false
appState.userData = nil
// Instead of appState.logout()

// Updated message:
"Akun saat ini akan tetap tersimpan..."
```

---

## 🎯 User Flow Comparison

### Before:

```
1. Open "Kelola Akun"
2. See all accounts in list
3. Scroll to find target account
4. Tap "Ganti" button
5. Switch
```

### After:

```
1. Open "Kelola Akun"
2. See current account
3. Tap "Ganti Akun" dropdown
4. Tap target account
5. Switch (dropdown auto-closes)
```

**Benefits:**

- ✅ Cleaner UI
- ✅ Less scrolling
- ✅ Faster account switching
- ✅ Better for 3-5 accounts

---

## 🧪 Testing Scenarios

### Scenario 1: Tambah Akun Baru

**Steps:**

1. Login dengan akun A
2. Klik "Tambah Akun"
3. Login dengan akun B

**Expected:**

- ✅ Akun A tetap tersimpan
- ✅ Akun B menjadi aktif
- ✅ Counter: "2/5 akun tersimpan"
- ✅ Dropdown "Ganti Akun" muncul
- ✅ Akun A ada di dalam dropdown

### Scenario 2: Switch via Dropdown

**Steps:**

1. Klik "Ganti Akun"
2. Dropdown expand dengan animasi
3. Klik akun di dropdown

**Expected:**

- ✅ Dropdown collapse otomatis
- ✅ Switch ke akun terpilih
- ✅ Badge "Aktif" berpindah
- ✅ Akun lama masuk ke dropdown

### Scenario 3: Delete dari Dropdown

**Steps:**

1. Buka dropdown
2. Klik icon trash pada akun di dropdown
3. Konfirmasi

**Expected:**

- ✅ Akun terhapus dari dropdown
- ✅ Counter berkurang
- ✅ Akun aktif tidak berubah

---

## 📱 UI/UX Improvements

### Visual Changes:

1. **Dropdown Button:**

   - Icon: `arrow.left.arrow.right.circle`
   - Text: "Ganti Akun"
   - Background: Light blue (`Color.blue.opacity(0.05)`)
   - Chevron: Down/Up based on state

2. **Dropdown Items:**

   - Smaller avatar (36x36 vs 40x40)
   - Indented (padding left)
   - Background: Very light gray
   - Border radius: 8

3. **Animations:**
   - Spring animation (response: 0.3)
   - Opacity + move transition
   - Smooth chevron rotation

### User Experience:

- ✅ Less visual clutter
- ✅ Clearer active account indication
- ✅ Faster account switching
- ✅ Intuitive dropdown interaction
- ✅ Consistent with iOS patterns

---

## 🔧 Technical Details

### State Management:

```swift
@State private var showingSwitchAccountDropdown = false
```

### Animation:

```swift
.transition(.opacity.combined(with: .move(edge: .top)))
```

### Filtering:

```swift
sessionManager.sessions.filter { !$0.isActive }
```

### Session Preservation:

```swift
// Don't call logout() - preserves session
appState.isLoggedIn = false
appState.userData = nil
```

---

## 📊 Performance Impact

**Before:**

- Render all sessions: O(n)
- Memory: All session rows loaded

**After:**

- Render 1 active + dropdown button: O(1)
- Memory: Only active session loaded initially
- Dropdown items: Lazy loaded on demand

**Benefits:**

- ✅ Faster initial render
- ✅ Lower memory footprint
- ✅ Better performance with 5 accounts

---

## 🐛 Bug Fixes

### Bug 1: Session Lost on Add Account

**Status:** ✅ Fixed
**Solution:** Don't call `logout()`, only clear state

### Bug 2: All Accounts Visible

**Status:** ✅ Fixed
**Solution:** Dropdown pattern

---

## 🚀 Future Enhancements

Potential improvements for next version:

1. **Search in Dropdown** (if >5 accounts allowed)
2. **Account Nickname** (custom labels)
3. **Recent Accounts** (show recently used first)
4. **Quick Switch** (swipe gesture)
5. **Account Color Tags** (visual distinction)

---

**Revision Date:** October 22, 2025  
**Version:** 1.1.0  
**Status:** ✅ Completed & Tested
