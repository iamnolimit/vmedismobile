# Implementasi Multi-Session Account Management

## Ringkasan

Implementasi fitur multi-session yang memungkinkan user untuk menyimpan dan beralih antara maksimal 5 akun berbeda melalui tab Akun.

## File yang Dibuat/Dimodifikasi

### 1. File Baru

#### `Models/AccountSession.swift`

Model untuk menyimpan data session akun dengan properties:

- `id`: Unique identifier
- `userData`: Data user lengkap
- `loginTime`: Waktu login pertama
- `lastAccessTime`: Waktu akses terakhir
- `isActive`: Status aktif/tidak
- Helper methods untuk display name dan domain info

#### `Services/SessionManager.swift`

Service untuk mengelola multiple sessions dengan fitur:

- Menyimpan hingga 5 akun
- Tambah/update session
- Switch antar session
- Hapus session
- Persistence ke UserDefaults
- Auto-remove oldest inactive session saat limit tercapai

### 2. File yang Dimodifikasi

#### `App/AppState.swift`

Update untuk support multi-session:

- `login()`: Sekarang juga menambahkan session ke SessionManager
- `logout()`: Hanya logout session aktif, bukan semua session
- `switchAccount()`: Method baru untuk switch ke session lain
- `logoutAllAccounts()`: Method baru untuk logout semua akun sekaligus
- `showAccountPicker`: Flag untuk menampilkan account picker
- `checkForMultipleSessions()`: Check saat startup jika ada multiple sessions

#### `Views/Pages/MainTabView.swift`

Tambahan UI components:

- **`AccountManagementSection`**: Section untuk menampilkan dan mengelola akun
  - Menampilkan list semua session
  - Tombol tambah akun (maksimal 5)
  - Counter akun tersimpan
- **`AccountSessionRow`**: Row untuk setiap session
  - Avatar dengan indicator aktif
  - Info nama dan domain
  - Badge "Aktif" untuk session yang sedang digunakan
  - Tombol "Ganti" untuk switch session
  - Tombol hapus session
- **`AddAccountSheet`**: Modal untuk tambah akun baru
  - Penjelasan proses tambah akun
  - Redirect ke halaman login

#### `Views/Pages/AccountPickerView.swift` (NEW)

View untuk memilih akun saat startup jika ada multiple sessions:

- **`AccountPickerView`**: Main view dengan list akun
  - Menampilkan semua session tersimpan
  - Auto-select active session atau session pertama
  - Tombol "Lanjutkan" untuk masuk dengan akun terpilih
  - Tombol "Tambah Akun Baru" untuk login akun baru
- **`AccountPickerRow`**: Row untuk setiap session
  - Avatar dengan border selection
  - Info nama, domain, dan last access time (relative)
  - Checkmark indicator untuk selection

#### `App/ContentView.swift`

Update untuk menampilkan AccountPickerView jika ada multiple sessions

## Cara Penggunaan

### Memilih Akun Saat Startup (Account Picker)

Jika ada lebih dari 1 akun tersimpan:

1. App akan menampilkan **Account Picker** saat dibuka
2. Pilih akun yang ingin digunakan dari list
3. Klik tombol **Lanjutkan** untuk masuk dengan akun tersebut
4. Atau klik **Tambah Akun Baru** untuk login dengan akun berbeda

### Tambah Akun Baru

1. Buka tab **Akun**
2. Di section **Kelola Akun**, klik tombol **Tambah**
3. User akan di-logout dan diarahkan ke halaman login
4. Login dengan akun baru
5. Akun baru akan tersimpan dan menjadi akun aktif

### Ganti Akun

1. Buka tab **Akun**
2. Di section **Kelola Akun**, lihat list akun tersimpan
3. Klik tombol **Ganti** pada akun yang ingin digunakan
4. App akan reload dengan session akun tersebut

### Hapus Akun

1. Buka tab **Akun**
2. Di section **Kelola Akun**, klik icon **trash** pada akun yang ingin dihapus
3. Konfirmasi penghapusan
4. Jika akun yang dihapus adalah akun aktif, app akan otomatis switch ke akun pertama (jika ada)

## Batasan

- Maksimal **5 akun** dapat disimpan
- Saat mencapai limit dan ingin tambah akun baru, session paling lama yang tidak aktif akan dihapus otomatis
- Session disimpan di UserDefaults dan akan persist setelah app ditutup

## Keamanan

- Token disimpan di Keychain untuk keamanan maksimal
- Setiap session memiliki data lengkap termasuk authentication token
- Last access time diupdate setiap kali session digunakan

## UI/UX Features

- **Account Picker Screen**: Ditampilkan saat startup jika ada multiple sessions
  - List semua akun tersimpan
  - Relative time display (e.g., "5 menit yang lalu")
  - Selection indicator dengan checkmark
  - Blue border pada avatar yang dipilih
- **Account Management Section** di tab Akun:
  - Visual indicator untuk akun yang sedang aktif
  - Badge hijau "Aktif" pada session yang digunakan
  - Blue border pada avatar akun aktif
  - Counter "X/5 akun tersimpan"
  - Disable button "Tambah" saat sudah 5 akun
  - Loading avatar dari userData (foto profil atau logo klinik/apotek)
- **Logout Options**:
  - "Logout Akun Ini" - hanya logout session aktif
  - "Logout Semua Akun" - logout semua session (muncul jika >1 akun)
- **Smooth Animations**: Transisi halus saat switch account atau logout

## Testing Checklist

- [ ] **Account Picker**: Tutup dan buka app dengan 2+ akun, verifikasi account picker muncul
- [ ] **Account Picker Selection**: Pilih akun dari account picker dan verifikasi login berhasil
- [ ] Login dengan akun pertama
- [ ] Tambah akun kedua melalui tab Akun
- [ ] Switch antara 2 akun
- [ ] Verifikasi badge "Aktif" muncul pada akun yang sedang digunakan
- [ ] Tambah 3 akun lagi (total 5)
- [ ] Coba tambah akun ke-6 (harus auto-remove yang lama)
- [ ] Verifikasi button "Tambah" disabled saat sudah 5 akun
- [ ] Hapus akun tidak aktif
- [ ] Hapus akun aktif (harus switch ke akun lain)
- [ ] Test "Logout Akun Ini" - verifikasi switch ke akun lain
- [ ] Test "Logout Semua Akun" - verifikasi semua session terhapus
- [ ] Verifikasi tombol "Logout Semua" hanya muncul jika >1 akun
- [ ] Logout saat hanya 1 akun tersisa
- [ ] Tutup dan buka app (persistence test)
- [ ] Switch akun dan cek apakah data tab sesuai dengan akun
- [ ] Test relative time display di account picker
- [ ] Test avatar loading dari userData

## Future Improvements

- Add biometric authentication untuk switch account
- Add account nickname/label
- Add last used timestamp display
- Add quick account switcher di navigation bar
- Add account sync status indicator
