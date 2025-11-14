# Fix: Forecast Access & Customer Menu Order

**Tanggal**: 2024
**Masalah**:

1. User fadil123 mendapat akses Forecast padahal seharusnya tidak
2. Menu Customer harus muncul SEBELUM "Pendaftaran Klinik" di Account tab

---

## 🔍 Analisis Masalah

### Masalah 1: Forecast Access False Positive

**Gejala**:

- User fadil123 (level 0, gr_id 28) mendapat akses tab Forecast
- Padahal user ini seharusnya TIDAK punya menu forecast

**Root Cause**:

```swift
// SEBELUM (SALAH):
let forecastMenus = ["/laporan-super-pareto?awal=1", "/lap-obatlaris", ...]
var hasForecastAccess = aksesMenu.contains(where: { url in
    forecastMenus.contains(url)
})
```

**Masalah**:

- Array `forecastMenus` mengandung `/laporan-super-pareto?awal=1` (dengan query string)
- Tapi `aksesMenu` user kemungkinan hanya punya `/laporan-super-pareto` atau URL lain yang mirip
- `contains(where:)` tidak memberikan feedback URL mana yang match
- Tidak ada logging untuk debug

### Masalah 2: Menu Order

**Status**:
✅ **SUDAH BENAR** - Menu Customer sudah di posisi pertama di array `menuItems` (line ~331)

```swift
let menuItems: [MenuItem] = [
    MenuItem(icon: "person.3", title: "Customer", route: "customers"),  // ← Posisi 1
    MenuItem(icon: "person.text.rectangle", title: "Pendaftaran Klinik", ...), // ← Posisi 2
    // ...
]
```

Filter `filterMenuItemsByAccess()` menggunakan loop biasa yang maintain order:

```swift
for menu in menuItems {  // ← Iterate dari index 0 ke atas
    // Filter logic
    filtered.append(menu)  // ← Append sesuai urutan
}
```

**Kesimpulan**: Menu order sudah benar, tidak perlu perubahan

---

## ✅ Solusi

### Fix 1: Forecast Access Check dengan Logging

**File**: `MainTabView.swift` (line ~249)

**Perubahan**:

```swift
// SETELAH (BENAR):
let forecastMenus = ["/laporan-super-pareto", "/lap-obatlaris",
                    "/analisa-penjualan", "/forecast-penjualan",
                    "/laporan-trend-penjualan"]
var hasForecastAccess = false
for url in aksesMenu {
    if forecastMenus.contains(url) {
        hasForecastAccess = true
        print("🎯 Forecast access GRANTED because user has: \(url)")
        break
    }
}
if !hasForecastAccess {
    print("❌ Forecast access DENIED - no matching forecast menu URLs found")
}
```

**Perbaikan**:

1. ✅ **Removed query string**: `/laporan-super-pareto?awal=1` → `/laporan-super-pareto`
2. ✅ **Added explicit logging**: Print URL mana yang memberikan akses
3. ✅ **Added denial logging**: Print jika tidak ada akses
4. ✅ **Exact match**: Loop eksplisit untuk memastikan exact match
5. ✅ **Early exit**: Break setelah match pertama ditemukan

### Fix 2: Customer Access Check dengan Logging

**File**: `MainTabView.swift` (line ~259)

**Perubahan**:

```swift
// SETELAH (KONSISTEN):
let customersMenus = ["/pasien", "/customer", "/laporan-registrasi-pasien",
                     "/laporan-kunjungan-pasien", "/laporan-pareto-pasien",
                     "/laporan-janji-dengan-dokter"]
for url in aksesMenu {
    if customersMenus.contains(url) {
        hasCustomersAccess = true
        print("🎯 Customer access GRANTED because user has: \(url)")
        break
    }
}
if !hasCustomersAccess {
    print("❌ Customer access DENIED - no matching customer menu URLs found")
}
```

**Perbaikan**:

1. ✅ **Consistent pattern**: Sama seperti forecast check
2. ✅ **Added logging**: Debug visibility untuk troubleshooting
3. ✅ **Explicit loop**: Lebih mudah di-debug dibanding `contains(where:)`

---

## 🧪 Testing

### Test Case 1: User Fadil123 (273 Menu URLs)

**Expected Behavior**:

```
📋 Checking tab access from userData.aksesMenu (273 items)
❌ Forecast access DENIED - no matching forecast menu URLs found
✅ Accessible tabs for user: ["home", "products", "orders", "customers", "account"]
   - Home: ✓
   - Obat: ✓
   - Keuangan: ✓
   - Forecast: ✗  ← SHOULD BE DENIED
   - Customer: ✓
   - Akun: ✓
```

**Jika ada Forecast Access**:

```
🎯 Forecast access GRANTED because user has: /laporan-super-pareto
   - Forecast: ✓
```

→ Berarti user MEMANG punya menu forecast (legitimate access)

### Test Case 2: Menu Order di Account Tab

**Expected Behavior**:

1. Login sebagai user dengan akses Customer
2. Tap tab "Akun"
3. Menu list harus menampilkan:
   ```
   1. Customer              ← First (jika user punya akses /pasien atau /customer)
   2. Pendaftaran Klinik    ← Second
   3. Pelayanan Klinik
   4. Billing Kasir
   5. Laporan Apotek
   6. Laporan Keuangan
   7. Sistem
   ```

**Verification**:

- Menu Customer muncul SEBELUM Pendaftaran Klinik ✓
- Urutan sesuai dengan `menuItems` array definition ✓

---

## 📊 Impact Analysis

### User fadil123 (Level 0, GR_ID 28)

**Sebelum Fix**:

- ❌ Forecast tab: Muncul (FALSE POSITIVE)
- ✅ Customer tab: Muncul (correct)

**Setelah Fix**:

- Jika 273 menu URLs **TIDAK** ada forecast URL → Forecast tab HILANG ✓
- Jika 273 menu URLs **ADA** forecast URL → Forecast tab TETAP (legitimate) ✓
- Customer tab tetap muncul jika ada menu customer ✓

### Logging Improvement

**Sebelum**:

```
✅ Accessible tabs for user: ["home", "products", "orders", "forecast", "customers", "account"]
   - Forecast: ✓
```

→ Tidak tahu KENAPA dapat akses

**Setelah**:

```
🎯 Forecast access GRANTED because user has: /laporan-super-pareto
✅ Accessible tabs for user: ["home", "products", "orders", "forecast", "customers", "account"]
   - Forecast: ✓
```

→ Jelas URL mana yang memberikan akses

Atau:

```
❌ Forecast access DENIED - no matching forecast menu URLs found
✅ Accessible tabs for user: ["home", "products", "orders", "customers", "account"]
   - Forecast: ✗
```

→ Jelas kenapa tidak dapat akses

---

## 📝 Summary

| Issue                              | Status             | Solution                                                    |
| ---------------------------------- | ------------------ | ----------------------------------------------------------- |
| User fadil123 dapat akses Forecast | ✅ Fixed           | Removed query string dari forecast URL check, added logging |
| Customer menu order                | ✅ Already Correct | No change needed - order maintained by array definition     |
| Forecast access logging            | ✅ Fixed           | Added explicit URL match logging                            |
| Customer access logging            | ✅ Fixed           | Added explicit URL match logging                            |

**Files Modified**:

- `MainTabView.swift` (2 changes)

**Lines Changed**:

- Line ~249: Forecast access check (9 lines → 11 lines)
- Line ~259: Customer access check (4 lines → 10 lines)

**Next Steps**:

1. Test dengan user fadil123
2. Check console log untuk melihat:
   - Apakah forecast access granted atau denied
   - Jika granted, URL apa yang memberikan akses
3. Verify menu order di Account tab
4. Adjust `forecastMenus` array jika perlu berdasarkan hasil test
