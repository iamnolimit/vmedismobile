# Vmedis Mobile - iOS App

Aplikasi mobile iOS untuk sistem Vmedis Apotek & Klinik dengan fitur multi-session account management.

## 🚀 Fitur Utama

### 1. **Multi-Session Account Management**

- ✅ Support hingga 5 akun berbeda
- ✅ Switch antar akun dengan mudah
- ✅ Account picker saat startup (jika ada multiple sessions)
- ✅ Persistent sessions dengan Keychain security
- ✅ Smart session management (auto-remove oldest inactive session)

### 2. **Menu Access Control & Leveling System**

- ✅ Leveling system berdasarkan user role
- ✅ Dynamic menu access control via GraphQL
- ✅ Tab access control (Home, Obat, Keuangan, Forecast)
- ✅ Superadmin (lvl=1) full access
- ✅ Regular users: access berdasarkan permission

### 3. **Modern UI/UX**

- ✅ Native SwiftUI interface
- ✅ Smooth animations dan transitions
- ✅ Profile photos dari userData
- ✅ Relative time display
- ✅ Loading states dan error handling
- ✅ Light mode optimized

### 4. **Performance Optimized**

- ✅ WebView caching untuk performa optimal
- ✅ Lazy loading untuk tab content
- ✅ Efficient session management
- ✅ Minimal API calls

## 📁 Struktur Project

```
vmedismobile/
├── App/
│   ├── AppState.swift              # Global app state & session management
│   ├── ContentView.swift           # Main content router
│   └── vmedismobileApp.swift       # App entry point
├── Models/
│   ├── AccountSession.swift        # Session data model
│   └── MenuAccess.swift            # Menu access model
├── Services/
│   ├── SessionManager.swift        # Multi-session manager
│   ├── LoginService.swift          # Authentication service
│   └── [WebView services]          # WebView implementations
├── Views/
│   ├── Pages/
│   │   ├── LoginPageView.swift     # Login screen
│   │   ├── MainTabView.swift       # Main tab interface
│   │   └── AccountPickerView.swift # Account picker screen
│   └── Components/
│       └── [UI components]
└── Utilities/
    └── AppVersion.swift            # App version info
```

## 🔧 Setup & Installation

### Requirements

- iOS 15.6+
- Xcode 16+
- Swift 5.9+

### Build & Run

1. Open `vmedismobile.xcodeproj` in Xcode
2. Select target device/simulator
3. Press `Cmd + R` to build and run

## 📖 Dokumentasi

- [Multi-Session Implementation](MULTI_SESSION_IMPLEMENTATION.md)
- [Menu Leveling Implementation](MENU_LEVELING_IMPLEMENTATION.md)
- [Tab Access Control Implementation](TAB_ACCESS_CONTROL_IMPLEMENTATION.md)

## 🔐 Security

- **Keychain**: Token dan sensitive data disimpan di Keychain
- **Session Management**: Auto-cleanup inactive sessions
- **Authentication**: JWT token-based authentication
- **Data Persistence**: Secure UserDefaults storage

## 🎯 User Flow

### First Time Login

```
Open App → Login Screen → Enter Credentials → Main Tab View
```

### Multiple Accounts Saved

```
Open App → Account Picker → Select Account → Main Tab View
```

### Add New Account

```
Main Tab View → Tab Akun → Kelola Akun → Tambah → Login Screen → Main Tab View
```

### Switch Account

```
Main Tab View → Tab Akun → Kelola Akun → Ganti → Main Tab View (new session)
```

## 🧪 Testing

Lihat testing checklist di:

- [Multi-Session Testing](MULTI_SESSION_IMPLEMENTATION.md#testing-checklist)
- [Menu Leveling Testing](MENU_LEVELING_IMPLEMENTATION.md#testing)

## 📝 API Integration

### Base URLs

- **API**: `https://api3.vmedis.com`
- **Domain Validation**: `https://api3penjualan.vmedis.com`
- **Images**: `https://apt.vmedis.com/foto/`

### Endpoints

- `POST /klinik/validate-domain` - Domain validation
- `POST /graphql` - Login & menu access queries

## 👥 Account Management

### Features

- **Add Account**: Maksimal 5 akun
- **Switch Account**: Instant switch tanpa re-login
- **Remove Account**: Hapus akun dengan konfirmasi
- **Logout Options**:
  - Logout Akun Ini (keep other sessions)
  - Logout Semua Akun (clear all sessions)

### Session Data

Setiap session menyimpan:

- User credentials & token
- Klinik/Apotek info
- Menu access permissions
- Login & last access timestamps

## 🎨 UI Components

### Account Management Section

- Session list dengan avatar
- Active indicator badge
- Switch & delete actions
- Add account button (with limit check)

### Account Picker

- Full-screen selection
- Profile photos
- Relative timestamps
- Continue & add new options

### Profile View

- User info header
- Dynamic menu (based on access)
- Account management
- Logout options

## 🔄 State Management

### AppState (ObservableObject)

- `isLoggedIn`: Login status
- `userData`: Current user data
- `showAccountPicker`: Show/hide account picker
- Methods: `login()`, `logout()`, `switchAccount()`, `logoutAllAccounts()`

### SessionManager (Singleton)

- `sessions`: Array of AccountSession
- `activeSession`: Current active session
- Methods: `addOrUpdateSession()`, `switchSession()`, `removeSession()`

## 🚀 Future Improvements

- [ ] Biometric authentication untuk switch account
- [ ] Push notifications per account
- [ ] Account nickname/label customization
- [ ] Quick account switcher in navigation bar
- [ ] Account sync status indicator
- [ ] Export/Import account settings
- [ ] Dark mode support

## 📄 License

Proprietary - Vmedis Indonesia

## 👨‍💻 Development

### Code Style

- SwiftUI for UI
- Async/await for async operations
- MVVM architecture pattern
- Singleton for managers
- Environment objects for state

### Best Practices

- Handle errors gracefully
- Show loading states
- Validate user input
- Secure sensitive data
- Test edge cases

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Powered by**: Vmedis Indonesia
