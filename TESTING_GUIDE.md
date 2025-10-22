# Multi-Session Quick Start Guide

## 🚀 Testing Multi-Session Features

### 1️⃣ Login Akun Pertama

1. Buka aplikasi
2. Masukkan subdomain, username, dan password
3. Klik "Masuk"
4. ✅ Akun pertama tersimpan sebagai session aktif

---

### 2️⃣ Tambah Akun Kedua

1. Buka tab **Akun**
2. Di section **Kelola Akun**, klik tombol **Tambah**
3. Modal akan muncul dengan konfirmasi
4. Klik **Lanjutkan ke Login**
5. ✅ User diarahkan ke login page (akun pertama tetap tersimpan)
6. Login dengan akun kedua
7. ✅ Kedua akun tersimpan, akun kedua menjadi aktif

**Expected Result:**

- Counter menunjukkan "2/5 akun tersimpan"
- Akun kedua ditandai dengan badge "Aktif"
- Akun pertama muncul di dropdown "Ganti Akun"

---

### 3️⃣ Ganti Akun (Switch Account)

#### Via Dropdown "Ganti Akun":

1. Buka tab **Akun**
2. Di section **Kelola Akun**, klik tombol **Ganti Akun**
3. Dropdown akan expand menampilkan list akun lain
4. Klik pada akun yang ingin digunakan
5. ✅ App langsung reload dengan akun tersebut

**Expected Result:**

- Dropdown menutup otomatis
- Akun baru menjadi aktif (badge "Aktif" berpindah)
- Tab content berubah sesuai akun baru
- Last access time terupdate

---

### 4️⃣ Hapus Akun

#### Hapus Akun Tidak Aktif:

1. Klik **Ganti Akun** untuk membuka dropdown
2. Klik icon **trash** pada akun yang ingin dihapus
3. Konfirmasi penghapusan
4. ✅ Akun terhapus dari list

#### Hapus Akun Aktif:

1. Klik icon **trash** di samping akun aktif
2. Konfirmasi penghapusan
3. ✅ Akun terhapus dan otomatis switch ke akun pertama dalam list

**Expected Result:**

- Counter "X/5 akun tersimpan" berkurang
- Jika menghapus akun aktif → auto switch ke akun lain
- Jika hapus semua akun → redirect ke login page

---

### 5️⃣ Multiple Sessions (3-5 Akun)

1. Ulangi proses tambah akun hingga 5 akun
2. ✅ Counter menunjukkan "5/5 akun tersimpan"
3. ✅ Tombol "Tambah" menjadi disabled (abu-abu)

**Test Case:**

- Coba tambah akun ke-6
- ✅ Tombol "Tambah" tidak dapat diklik

---

### 6️⃣ Account Picker (Startup)

#### Skenario: Multiple Sessions Tersimpan

1. Tutup aplikasi (force close)
2. Buka kembali aplikasi
3. ✅ Account Picker screen muncul
4. Pilih akun yang ingin digunakan
5. Klik **Lanjutkan**
6. ✅ Login dengan akun terpilih

**Alternative:**

- Klik **Tambah Akun Baru** untuk login akun berbeda

---

### 7️⃣ Logout Options

#### Logout Akun Ini (Single Logout):

1. Scroll ke bawah di tab **Akun**
2. Klik **Logout Akun Ini**
3. ✅ Logout session aktif
4. ✅ Auto switch ke akun lain (jika ada)
5. ✅ Jika tidak ada akun lain → redirect ke login page

#### Logout Semua Akun:

1. Pastikan ada >1 akun tersimpan
2. ✅ Tombol **Logout Semua Akun** muncul (warna merah)
3. Klik tombol tersebut
4. ✅ Semua session terhapus
5. ✅ Redirect ke login page

---

## 🎯 Expected UI/UX Behavior

### Account Management Section

```
┌─────────────────────────────────────────┐
│ Kelola Akun                    [+ Tambah]│
│ 2/5 akun tersimpan                       │
├─────────────────────────────────────────┤
│ 🟦 John Doe          [Aktif]      [🗑️]  │
│    Klinik Sehat                          │
├─────────────────────────────────────────┤
│ 🔄 Ganti Akun                         ▼  │
│   ┌───────────────────────────────────┐ │
│   │ 👤 Jane Smith            [🗑️]    │ │
│   │    Apotek Sejahtera               │ │
│   └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Dropdown Expanded

- **Icon**: Arrow left-right circle (🔄)
- **Text**: "Ganti Akun"
- **Chevron**: Down (collapsed) / Up (expanded)
- **Background**: Light blue
- **List**: Akun non-aktif dengan avatar, nama, domain
- **Action**: Tap anywhere on row to switch
- **Delete**: Trash icon di sebelah kanan

---

## ✅ Checklist Testing

### Basic Flow

- [ ] Login akun pertama berhasil
- [ ] Session pertama tersimpan
- [ ] Tambah akun kedua (akun pertama tetap tersimpan)
- [ ] Counter "2/5 akun tersimpan" muncul
- [ ] Badge "Aktif" pada akun yang sedang digunakan

### Switch Account

- [ ] Klik "Ganti Akun" membuka dropdown
- [ ] List akun lain muncul di dropdown
- [ ] Klik akun di dropdown → switch berhasil
- [ ] Dropdown menutup otomatis
- [ ] Badge "Aktif" berpindah ke akun baru
- [ ] Tab content berubah sesuai akun baru

### Delete Account

- [ ] Hapus akun dari dropdown → terhapus
- [ ] Hapus akun aktif → auto switch ke akun lain
- [ ] Counter berkurang saat hapus akun
- [ ] Hapus semua akun → redirect ke login

### Session Limit

- [ ] Tambah hingga 5 akun
- [ ] Counter "5/5 akun tersimpan"
- [ ] Tombol "Tambah" disabled
- [ ] Auto-remove oldest saat tambah akun ke-6

### Persistence

- [ ] Tutup dan buka app → Account Picker muncul
- [ ] Pilih akun di Account Picker → login berhasil
- [ ] Session tetap tersimpan setelah restart

### Logout

- [ ] "Logout Akun Ini" → switch ke akun lain
- [ ] "Logout Semua Akun" muncul jika >1 akun
- [ ] "Logout Semua Akun" → semua session terhapus

### UI/UX

- [ ] Avatar loading dari userData
- [ ] Smooth animation saat expand/collapse dropdown
- [ ] Smooth animation saat switch account
- [ ] Blue border pada avatar aktif
- [ ] Green badge "Aktif" terlihat jelas
- [ ] Delete icon warna merah
- [ ] Responsive tap areas

---

## 🐛 Known Issues & Edge Cases

### Edge Case 1: Tambah Akun Saat Limit Penuh

**Scenario:** 5 akun tersimpan, coba tambah akun ke-6
**Expected:** Tombol "Tambah" disabled
**Status:** ✅ Handled

### Edge Case 2: Hapus Semua Akun

**Scenario:** User hapus satu per satu hingga tidak ada akun tersisa
**Expected:** Redirect ke login page
**Status:** ✅ Handled

### Edge Case 3: Network Error Saat Switch

**Scenario:** Switch akun saat tidak ada internet
**Expected:** Show error message, tetap di akun lama
**Status:** ⚠️ Perlu tambahan error handling

### Edge Case 4: Duplicate Session

**Scenario:** Login dengan username & domain yang sama
**Expected:** Update existing session, tidak create duplicate
**Status:** ✅ Handled in `SessionManager.addOrUpdateSession()`

---

## 📊 Performance Metrics

**Target:**

- Switch account: < 500ms
- Dropdown animation: < 300ms
- Session load on startup: < 200ms

**Test:**

1. Measure time from tap "Ganti Akun" to UI update
2. Measure dropdown expand/collapse animation smoothness
3. Measure app launch time with multiple sessions

---

## 🔒 Security Checklist

- [ ] Token stored in Keychain (not UserDefaults)
- [ ] Session data encrypted
- [ ] Clear sensitive data on logout
- [ ] No password stored in plain text
- [ ] Validate session before switching

---

**Last Updated:** October 22, 2025  
**Version:** 1.0.0
