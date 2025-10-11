# 🔧 Domain Validation Error Handling Fix

## 🐛 Problem

Ketika domain salah, aplikasi menampilkan error:

```
Network Error: failed to decode response : failed to decode domain validation response
```

Padahal seharusnya menampilkan:

```
Domain tidak tersedia
```

---

## 🔍 Root Cause

### Response Structure Berbeda

**Domain Benar:**

```json
{
    "status": "success",
    "data": {
        "app_id": "5177",
        "kl_id": "458",
        "kl_nama": "DEMO APOTEKKLINIK PEMUDA 30",
        "kl_logo": "logo_458_20250925090436.png",
        ...
    }
}
```

**Domain Salah:**

```json
{
  "status": "failed",
  "message": "domain tidak ditemukan",
  "data": null
}
```

### Masalah di Code:

1. **Decoding Error** - Ketika response `status: "failed"`, struktur berbeda dan decode gagal
2. **Error Handling Kurang Spesifik** - Tidak ada check untuk `status` sebelum decode
3. **Throw Generic Error** - Langsung throw `decodingError` tanpa cek response status

---

## ✅ Solution

### 1. Update DomainValidationResponse Struct

**BEFORE:**

```swift
struct DomainValidationResponse: Codable {
    let status: String
    let data: DomainData?
}
```

**AFTER:**

```swift
struct DomainValidationResponse: Codable {
    let status: String
    let message: String?    // ← Tambah untuk error message
    let data: DomainData?   // ← Already optional
}
```

### 2. Add Status Check Before Decoding

**BEFORE:**

```swift
// Decode response
do {
    let domainResponse = try JSONDecoder().decode(DomainValidationResponse.self, from: data)
    print("Domain Validation Status: \(domainResponse.status)")
    return domainResponse
} catch {
    print("Decoding Error: \(error)")
    throw LoginError.decodingError("Failed to decode domain validation response")
}
```

**AFTER:**

```swift
// Try to decode as generic JSON first to check structure
if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    print("JSON Structure: \(jsonObject)")

    // Check if status is "failed" or "error"
    if let status = jsonObject["status"] as? String {
        print("Response Status: \(status)")

        if status == "failed" || status == "error" {
            print("Domain validation failed - domain not found")
            throw LoginError.domainNotFound  // ← Throw specific error
        }
    }
}

// Decode response
do {
    let domainResponse = try JSONDecoder().decode(DomainValidationResponse.self, from: data)
    print("Domain Validation Status: \(domainResponse.status)")

    // Double check status after decoding
    if domainResponse.status == "failed" || domainResponse.status == "error" {
        throw LoginError.domainNotFound
    }

    return domainResponse
} catch let decodingError as DecodingError {
    print("Decoding Error: \(decodingError)")
    // If decoding fails, likely domain not found (different response structure)
    throw LoginError.domainNotFound  // ← Fallback to domain not found
} catch {
    print("Other Error: \(error)")
    throw error
}
```

---

## 🔄 Logic Flow

```
API Response Received
    ↓
Parse as Generic JSON
    ↓
Check "status" field
    ↓
┌───────────────────┐
│ status == "failed"│
│ or "error"?       │
└─────────┬─────────┘
          │
    ┌─────┴─────┐
   YES         NO
    │           │
    ▼           ▼
Throw      Try Decode
domainNotFound  DomainValidationResponse
    │           │
    │      ┌────┴────┐
    │    Success  DecodingError
    │      │         │
    │      ▼         ▼
    │  Return    Throw
    │  Response  domainNotFound
    │      │         │
    └──────┴─────────┘
           │
           ▼
    Show Alert to User
```

---

## 🧪 Test Scenarios

| Scenario         | Response Status | Expected Behavior                            |
| ---------------- | --------------- | -------------------------------------------- |
| Domain benar     | `"success"`     | ✅ Lanjut ke login                           |
| Domain salah     | `"failed"`      | ✅ Alert: "Domain tidak tersedia"            |
| Domain typo      | `"failed"`      | ✅ Alert: "Domain tidak tersedia"            |
| Network error    | N/A             | ⚠️ Alert: "Network error: ..."               |
| Invalid response | N/A             | ✅ Alert: "Domain tidak tersedia" (fallback) |

---

## 📝 Code Changes Summary

### File: `Services/LoginService.swift`

**Changes Made:**

1. ✅ Added `message` field to `DomainValidationResponse`
2. ✅ Added JSON pre-check before decoding
3. ✅ Check `status` field from raw JSON
4. ✅ Throw `domainNotFound` if status is "failed" or "error"
5. ✅ Catch `DecodingError` specifically and throw `domainNotFound`
6. ✅ Added more debug logging

**Lines Modified:** ~120-150

---

## 🎯 Result

### BEFORE Fix:

```
❌ Domain salah → "Network Error: failed to decode response..."
```

### AFTER Fix:

```
✅ Domain salah → "Domain tidak tersedia"
✅ Domain benar → Lanjut ke login
✅ Network error → "Network error: [description]"
```

---

## 💡 Key Insights

1. **Always Check Response Status First** - Jangan langsung decode, cek status dulu
2. **Handle Different Response Structures** - Success vs error punya struktur berbeda
3. **Specific Error Types** - Gunakan custom error types untuk different scenarios
4. **Fallback Strategy** - Jika decode gagal, assume domain not found (safer)
5. **Debug Logging** - Print raw response untuk debugging

---

## 📚 Related Files

- `Services/LoginService.swift` - Main implementation
- `Views/Pages/LoginPageView.swift` - Error display
- `DOMAIN_VALIDATION_IMPLEMENTATION.md` - Original implementation guide

---

## ✅ Checklist

- [x] Update `DomainValidationResponse` struct
- [x] Add status pre-check before decoding
- [x] Throw specific `domainNotFound` error
- [x] Handle `DecodingError` as domain not found
- [x] Test with wrong domain
- [x] Test with correct domain
- [x] Verify error messages

---

📅 **Fixed:** January 2025  
🐛 **Issue:** Decoding error instead of domain validation error  
✅ **Status:** RESOLVED  
👨‍💻 **Developer:** Vmedis Team
