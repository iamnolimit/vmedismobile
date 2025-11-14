# 🔧 FIX: GraphQL Endpoint 404 Error

## 🐛 Problem

User level 0 (gr_id 28) tidak mendapat menu access di Swift app, padahal di Android app mendapat full access.

**Error yang terjadi**:

```
HTTP Status: 404
Response: <!DOCTYPE html><html>...Page not found...</html>
```

## 🔍 Root Cause Analysis

### 1. GraphQL Endpoint Berbeda

**Android App** (`vmedis-mobile`):

```javascript
// File: Apollo.js
const httpLink = new HttpLink({
  uri: "https://gqlmobile.vmedis.com/ailawa-aed", // ✅ BENAR
});
```

**Swift App (SEBELUM FIX)** (`vmedismobile`):

```swift
// File: LoginService.swift
private let baseURL = "https://api3.vmedis.com"

// Di fetchMenuAccess():
guard let url = URL(string: "\(baseURL)/graphql") else {  // ❌ SALAH
    throw LoginError.invalidURL
}
// Result: https://api3.vmedis.com/graphql → 404 Not Found
```

### 2. Endpoint Yang Benar

GraphQL server Vmedis Mobile berada di:

```
https://gqlmobile.vmedis.com/ailawa-aed
```

**BUKAN** di:

```
https://api3.vmedis.com/graphql  ← 404 Not Found
```

## ✅ Solution

### File: `LoginService.swift`

**1. Tambahkan GraphQL URL constant:**

```swift
@MainActor
class LoginService: ObservableObject {
    private let baseURL = "https://api3.vmedis.com"
    private let domainValidationURL = "https://api3penjualan.vmedis.com"
    private let graphqlURL = "https://gqlmobile.vmedis.com/ailawa-aed"  // ✅ ADDED
```

**2. Update fetchMenuAccess() function:**

```swift
// BEFORE (Line ~402)
guard let url = URL(string: "\(baseURL)/graphql") else {
    throw LoginError.invalidURL
}

// AFTER
guard let url = URL(string: graphqlURL) else {
    throw LoginError.invalidURL
}
```

## 🧪 Testing

### Before Fix:

```
📡 GraphQL Request:
   URL: https://api3.vmedis.com/graphql
   HTTP Status: 404
❌ HTTP Error: Status code 404
📥 Response: <!DOCTYPE html>...Page not found...</html>
```

### After Fix (Expected):

```
📡 GraphQL Request:
   URL: https://gqlmobile.vmedis.com/ailawa-aed
   HTTP Status: 200
✅ mutGroupUserV2.Items1 found: X items
✅ Menu access parsed: X URLs
```

## 📝 Next Steps

1. **Clean Build** (`Shift + Cmd + K`)
2. **Build** (`Cmd + B`)
3. **Run** (`Cmd + R`)
4. **Login** dengan user `fadil123` (gr_id 28, level 0)
5. **Verify** menu access di log console
6. **Check** tab access sudah muncul semua

## 🎯 Expected Result

User dengan **level 0** dan **gr_id 28** akan mendapat menu access berdasarkan **group permissions** (BUKAN berdasarkan level), sama seperti di Android app.

Menu access ditentukan oleh:

- ✅ `gr_id` (Group ID) → Query ke `group_menu` table
- ❌ `level` → Tidak dipakai untuk filtering menu

## 📚 Related Files

- ✅ `d:\RESEARCH\vmedismobile\vmedismobile\Services\LoginService.swift` - **FIXED**
- 📋 `d:\WORK\vmedis-mobile\Apollo.js` - Reference (Android GraphQL config)
- 📋 `d:\WORK\vmedis-mobile-graphql\resolvers\vmed\Group_User.js` - GraphQL resolver

## ✅ Status

**FIXED** - GraphQL endpoint sekarang sama dengan Android mobile app.
