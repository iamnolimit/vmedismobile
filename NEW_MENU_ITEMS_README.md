# New Menu Items - Swift iOS App

## 📋 Overview

Added 4 new menu items to the Swift iOS mobile app (vmedismobile) for accessing financial reports and system settings through the dropdown menu in the Account tab.

## ✅ Changes Made

### 1. Updated `MenuAccess.swift`
**File**: `d:\RESEARCH\vmedismobile\vmedismobile\Models\MenuAccess.swift`

Added route mappings for the new menu items:

```swift
// Sistem
"lapmanajemenuser": "/user",
"lappengaturanbank": "/pengaturan-bank",
```

These mappings connect the iOS routes to the server's mn_url endpoints for access control.

### 2. Updated `MainTabView.swift`
**File**: `d:\RESEARCH\vmedismobile\vmedismobile\Views\Pages\MainTabView.swift`

Added 2 new parent menu items with submenus:

#### 📊 Laporan Keuangan (Financial Reports)
```swift
MenuItem(icon: "chart.bar.doc.horizontal", title: "Laporan Keuangan", subMenus: [
    SubMenuItem(icon: "doc.text", title: "Laporan Neraca Umum", route: "lapneracaumum"),
    SubMenuItem(icon: "chart.line.uptrend.xyaxis", title: "Laporan Laba Rugi", route: "laplabarugi")
])
```

#### ⚙️ Sistem (System Settings)
```swift
MenuItem(icon: "gearshape.2", title: "Sistem", subMenus: [
    SubMenuItem(icon: "person.2.circle", title: "Manajemen User", route: "lapmanajemenuser"),
    SubMenuItem(icon: "building.columns", title: "Pengaturan Bank", route: "lappengaturanbank")
])
```

## 🎯 Menu Items Details

| Parent Menu | Submenu Item | Route | Server mn_url | Web Component |
|------------|--------------|-------|---------------|---------------|
| **Laporan Keuangan** | Laporan Neraca Umum | `lapneracaumum` | `/laporan-neraca-normal` | `LapNeracaUmumPage` |
| | Laporan Laba Rugi | `laplabarugi` | `/laporan-laba-rugi` | `LapLabaRugiPage` |
| **Sistem** | Manajemen User | `lapmanajemenuser` | `/user` | `LapManajemenUserPage` |
| | Pengaturan Bank | `lappengaturanbank` | `/pengaturan-bank` | `LapPengaturanBankPage` |

## 🔗 Integration Flow

1. **User Navigation**:
   - User taps on "Laporan Keuangan" or "Sistem" in the Account tab dropdown
   - Accordion expands to show submenus
   - User taps on specific submenu item

2. **Route Mapping**:
   - Route (e.g., `lapneracaumum`) → `MenuURLMapping` → mn_url (e.g., `/laporan-neraca-normal`)

3. **Access Control**:
   - System checks if user has access to the mn_url via `MenuAccessManager`
   - Only shows menu items user has permission to access

4. **Navigation**:
   - Uses `BypassWebView` to load the web page at `https://{domain}.vmedis.com/mobile?tab={route}`
   - Example: `https://demok99.vmedis.com/mobile?tab=lapneracaumum`

5. **Web Rendering**:
   - React app's `mobileLayout.jsx` routes to appropriate page component
   - Page loads within the iOS WebView seamlessly

## 📱 Menu Structure (Updated)

```
Account Tab
├── Customer
├── Pendaftaran Klinik
│   ├── Laporan Registrasi Pasien
│   └── Laporan Kunjungan Pasien
├── Pelayanan Klinik
│   └── Laporan Janji Dengan Dokter
├── Billing Kasir
│   ├── Laporan Piutang Klinik
│   ├── Laporan Pembayaran Kasir
│   ├── Laporan Penjualan Obat Klinik
│   ├── Laporan Tagihan Jaminan
│   └── Laporan Pendapatan Petugas Medis
├── Laporan Apotek
│   ├── Laporan Pembelian
│   ├── Laporan Hutang Obat
│   ├── Laporan Penjualan Obat
│   ├── Laporan Piutang Obat
│   ├── Laporan Obat Stok Habis
│   ├── Laporan Obat Expired
│   ├── Laporan Obat Terlaris
│   ├── Laporan Stok Opname
│   ├── Laporan Stok Obat
│   └── Laporan Pergantian Shift
├── 📊 Laporan Keuangan ✨ NEW
│   ├── Laporan Neraca Umum ✨ NEW
│   └── Laporan Laba Rugi ✨ NEW
└── ⚙️ Sistem ✨ NEW
    ├── Manajemen User ✨ NEW
    └── Pengaturan Bank ✨ NEW
```

## 🎨 Icons Used

- **Laporan Keuangan**: `chart.bar.doc.horizontal` (bar chart with document)
- **Laporan Neraca Umum**: `doc.text` (document with text)
- **Laporan Laba Rugi**: `chart.line.uptrend.xyaxis` (line chart trending up)
- **Sistem**: `gearshape.2` (two gears)
- **Manajemen User**: `person.2.circle` (two people in circle)
- **Pengaturan Bank**: `building.columns` (bank building)

All icons are SF Symbols, available natively in iOS.

## 🔐 Access Control

The menu items follow the same access control pattern as existing items:

1. **Server-Side Control**: 
   - User permissions defined in database via `mn_url`
   - GraphQL query `MenuGroupUser` returns accessible menu items

2. **Client-Side Filtering**:
   - `MenuAccessManager.hasAccess(to: route)` checks permissions
   - Only accessible menu items displayed to user
   - Non-accessible items automatically hidden

3. **Superadmin Access**:
   - Users with `lvl=1` have full access to all menu items
   - No filtering applied for superadmin

## 🧪 Testing

### Manual Testing Steps:

1. **Login to App**:
   ```
   - Open vmedismobile app
   - Login with test credentials
   - Navigate to Account tab
   ```

2. **Check Menu Visibility**:
   ```
   - Scroll down in Account tab
   - Look for "Laporan Keuangan" menu (after "Laporan Apotek")
   - Look for "Sistem" menu (after "Laporan Keuangan")
   - Verify both menus show expand arrow icon
   ```

3. **Test Accordion**:
   ```
   - Tap "Laporan Keuangan" → should expand showing 2 items
   - Tap "Sistem" → should expand showing 2 items
   - Tap again → should collapse
   - Verify smooth animation
   ```

4. **Test Navigation**:
   ```
   For each submenu item:
   - Tap menu item
   - Should navigate to ReportPageView
   - WebView should load corresponding page
   - Verify correct URL loads
   - Test back button returns to Account tab
   ```

5. **Test Access Control** (with regular user):
   ```
   - Login with user without admin permissions
   - Check if "Manajemen User" is hidden
   - Check if "Pengaturan Bank" is hidden
   - Verify only permitted items show
   ```

### Test URLs:
- Neraca Umum: `https://{domain}.vmedis.com/mobile?tab=lapneracaumum`
- Laba Rugi: `https://{domain}.vmedis.com/mobile?tab=laplabarugi`
- Manajemen User: `https://{domain}.vmedis.com/mobile?tab=lapmanajemenuser`
- Pengaturan Bank: `https://{domain}.vmedis.com/mobile?tab=lappengaturanbank`

## 🚀 Deployment

### Prerequisites:
- Xcode 15+
- iOS 15+ deployment target
- Active Apple Developer account

### Build Steps:

1. **Open Project**:
   ```bash
   cd d:\RESEARCH\vmedismobile
   open vmedismobile.xcodeproj
   ```

2. **Clean Build** (Optional but recommended):
   ```bash
   # In Xcode: Product > Clean Build Folder
   # Or via terminal:
   xcodebuild clean -project vmedismobile.xcodeproj -scheme vmedismobile
   ```

3. **Build for Simulator**:
   ```bash
   xcodebuild -scheme vmedismobile \
     -destination 'platform=iOS Simulator,name=iPhone 15' \
     build
   ```

4. **Run on Simulator**:
   - In Xcode: Select simulator and press ⌘R
   - Or use `xcodebuild` with `-run` flag

5. **Build for Device** (TestFlight/Production):
   ```bash
   # Archive for distribution
   xcodebuild -scheme vmedismobile \
     -archivePath ./build/vmedismobile.xcarchive \
     archive
   ```

## 📝 Files Modified

1. **MenuAccess.swift** - Added 2 route mappings
2. **MainTabView.swift** - Added 2 menu sections with 4 total submenu items

**No changes required** in:
- `mobileLayout.jsx` (routes already exist)
- `ReportPageView.swift` (generic, handles all routes)
- `BypassWebView.swift` (generic WebView loader)

## 🔄 Backend Requirements

### Server-side Menu Access (mn_url)

Ensure these mn_url values exist in the database `menu` table:

```sql
-- Laporan Keuangan
INSERT INTO menu (mn_url, mn_nama, mn_kode, mn_aktif, mn_devices) 
VALUES 
  ('/laporan-neraca-normal', 'Laporan Neraca Umum', '##.##', 1, '1,2'),
  ('/laporan-laba-rugi', 'Laporan Laba Rugi', '##.##', 1, '1,2');

-- Sistem  
INSERT INTO menu (mn_url, mn_nama, mn_kode, mn_aktif, mn_devices) 
VALUES 
  ('/user', 'Manajemen User', '##.##', 1, '1,2'),
  ('/pengaturan-bank', 'Pengaturan Bank', '##.##', 1, '1,2');
```

**Note**: Replace `##.##` with appropriate menu codes based on your menu hierarchy.

### User Group Permissions

Grant access to user groups via `group_menu` table:

```sql
-- Example: Grant access to admin group (gr_id=1)
INSERT INTO group_menu (gm_gr_id, gm_mn_id) 
SELECT 1, mn_id FROM menu 
WHERE mn_url IN (
  '/laporan-neraca-normal',
  '/laporan-laba-rugi',
  '/user',
  '/pengaturan-bank'
);
```

## ✨ Features

- ✅ **Access Control**: Respects user permissions from server
- ✅ **Smooth Animations**: Accordion expand/collapse with easing
- ✅ **Consistent UI**: Matches existing menu item styling
- ✅ **SF Symbols Icons**: Native iOS icons, no custom assets needed
- ✅ **WebView Integration**: Uses existing `BypassWebView` for seamless loading
- ✅ **Back Navigation**: Proper navigation stack management
- ✅ **Responsive**: Works on all iOS device sizes

## 🐛 Troubleshooting

### Menu Items Not Showing

**Cause**: User lacks access permissions

**Solution**: 
1. Check user's group permissions in database
2. Verify mn_url exists in menu table
3. Check GraphQL response includes the mn_url
4. Test with superadmin account (lvl=1)

### Menu Items Show But Can't Navigate

**Cause**: Route mapping issue

**Solution**:
1. Verify route exists in `MenuURLMapping.routeToURL`
2. Check case sensitivity (routes are lowercased)
3. Verify web route exists in `mobileLayout.jsx`

### WebView Not Loading

**Cause**: Domain or network issue

**Solution**:
1. Check userData.domain is set correctly
2. Verify network connectivity
3. Check web server is accessible
4. Review WebView console logs

## 📞 Support

For issues or questions:
1. Check console logs in Xcode for detailed error messages
2. Verify server-side menu configuration
3. Test with superadmin account first
4. Contact backend team for database/API issues

## 📄 Related Documentation

- [FORGOT_PASSWORD_REGISTER_README.md](./FORGOT_PASSWORD_REGISTER_README.md) - Previous authentication features
- [MainTabView.swift](./vmedismobile/Views/Pages/MainTabView.swift) - Main tab view implementation
- [MenuAccess.swift](./vmedismobile/Models/MenuAccess.swift) - Menu access control
- [mobileLayout.jsx](../vmedis-react-app-v3/src/sections/mobile/mobileLayout.jsx) - Web routes

## 🎉 Summary

Successfully added 4 new menu items to the Swift iOS app:
1. ✅ Laporan Neraca Umum (Balance Sheet Report)
2. ✅ Laporan Laba Rugi (Profit & Loss Report)
3. ✅ Manajemen User (User Management)
4. ✅ Pengaturan Bank (Bank Settings)

All items are properly integrated with:
- Access control system
- Navigation flow
- WebView rendering
- Existing menu structure

The implementation follows the established patterns and is ready for testing and deployment.
