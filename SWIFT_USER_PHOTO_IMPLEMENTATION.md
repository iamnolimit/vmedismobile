# 📸 Swift User Photo Implementation - Complete Guide

## 🎯 Overview

Implementasi foto profil user di aplikasi Swift Vmedis, mengikuti logika yang sama dengan mobile lama (React Native).

**Response Login dari API:**

```json
{
  "status": "success",
  "message": "login berhasil!",
  "data": {
    "id": 1413,
    "username": "demoK25",
    "logo": "demoK25_2025-06-24_11:41:27.png",
    "kl_logo": "logo_304_20250721170319.png",
    "app_jenis": 3,
    "nama_lengkap": "ahmad fadil",
    "kl_nama": "[Demo] APT Test MB/MASTER VMART",
    "domain": "vmart",
    "app_id": "43f9",
    "app_reg": "db"
  }
}
```

---

## 📂 Files Modified

### 1. **UserData Model** (`Models/UserData.swift`)

```swift
struct UserData: Codable {
    let logo: String?           // ← User personal photo
    let kl_logo: String?        // ← Clinic/Pharmacy logo
    let nama_lengkap: String?
    let kl_nama: String?
    let app_jenis: Int?         // ← 1=Klinik, 2=Apotek, 3=Both
    let domain: String?
    // ... other fields
}
```

### 2. **ProfileView** (`Views/Pages/MainTabView.swift`)

#### 🖼️ Display AsyncImage

```swift
// Profile Image - Load dari userData
AsyncImage(url: getUserPhotoURL()) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    case .empty:
        ProgressView()
    @unknown default:
        EmptyView()
    }
}
.frame(width: 100, height: 100)
.clipShape(Circle())
.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
```

#### 🔧 Helper Function

```swift
/// Construct URL foto profil user berdasarkan data yang tersedia
/// Logika sama seperti mobile lama (React Native)
private func getUserPhotoURL() -> URL? {
    // Base URL untuk gambar
    let baseImageURL = "https://vmedis.s3.amazonaws.com/"

    // Priority 1: Gunakan logo user jika ada (untuk user personal)
    if let userLogo = userData.logo, !userLogo.isEmpty {
        let photoURL = baseImageURL + userLogo
        return URL(string: photoURL)
    }

    // Priority 2: Gunakan logo klinik atau apotek berdasarkan app_jenis
    // app_jenis: 1 = Klinik, 2 = Apotek
    let appJenis = userData.app_jenis ?? 1        if appJenis == 2 {
            // Apotek - gunakan kl_logo (meski nama field kl_logo, isinya logo apotek)
            if let aptLogo = userData.kl_logo, !aptLogo.isEmpty {
                let photoURL = baseImageURL + aptLogo
                return URL(string: photoURL)
            }
        } else {
            // Klinik - gunakan kl_logo
            if let klLogo = userData.kl_logo, !klLogo.isEmpty {
                let photoURL = baseImageURL + klLogo
                return URL(string: photoURL)
            }
        }

    // Default: return nil untuk trigger placeholder
    return nil
}
```

---

## 🔄 Logic Flow

```
┌─────────────────────────────────────┐
│      Login Success                  │
│  Response: UserData with logo       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   getUserPhotoURL() Called          │
└──────────────┬──────────────────────┘
               │
               ▼
        ┌──────────────┐
        │ userData.logo │
        │   exists?     │
        └──────┬───────┘
               │
        ┌──────┴──────┐
       YES            NO
        │              │
        ▼              ▼
   ┌─────────┐   ┌──────────────┐
   │ Use     │   │ Check        │
   │ logo    │   │ app_jenis    │
   └─────────┘   └──────┬───────┘
                         │
                  ┌──────┴──────┐
                  │ app_jenis   │
                  │   == 2?     │
                  └──────┬──────┘
                         │
                  ┌──────┴──────┐
                 YES            NO
                  │              │
                  ▼              ▼
            ┌──────────┐   ┌──────────┐
            │ apt_logo │   │ kl_logo  │
            └──────────┘   └──────────┘
                  │              │
                  └──────┬───────┘
                         │
                         ▼
              ┌─────────────────────┐
              │ Construct Full URL  │
              │ baseURL + logoPath  │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │  Return URL? or nil │
              └─────────────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │  AsyncImage loads   │
              │  - Success: Show    │
              │  - Failure: Placeholder │
              └─────────────────────┘
```

---

## 🌐 URL Construction

### Formula:

```swift
let fullURL = baseImageURL + logoPath

// Example:
// baseImageURL = "https://vmedis.s3.amazonaws.com/"
// logo = "demoK25_2025-06-24_11:41:27.png"
// Result = "https://vmedis.s3.amazonaws.com/demoK25_2025-06-24_11:41:27.png"

// OR for clinic:
// kl_logo = "logo_304_20250721170319.png"
// Result = "https://vmedis.s3.amazonaws.com/logo_304_20250721170319.png"
```

### Priority Logic:

1. **User Personal Photo** (`logo`) - Highest priority
2. **Apotek Logo** (`apt_logo`) - If `app_jenis == 2`
3. **Klinik Logo** (`kl_logo`) - If `app_jenis == 1` or default
4. **Placeholder** - If all above are nil/empty

---

## 🔀 Comparison: Mobile vs Swift

| Aspect                | React Native (Mobile Lama)    | Swift (iOS)                  |
| --------------------- | ----------------------------- | ---------------------------- |
| **Data Source**       | AsyncStorage                  | UserData from Login Response |
| **Logo Field**        | `logo`, `kl_logo`, `apt_logo` | Same                         |
| **Base URL**          | From AsyncStorage (`imgUri`)  | Hardcoded constant           |
| **Display Component** | `<Image source={{uri}}>`      | `AsyncImage(url:)`           |
| **Placeholder**       | Custom placeholder            | System `person.fill`         |
| **Conditional**       | Based on `app_jenis`          | Same logic                   |

---

## 💡 Best Practices

### ✅ DO's

1. **Check for nil/empty values**

   ```swift
   if let userLogo = userData.logo, !userLogo.isEmpty {
       // Use logo
   }
   ```

2. **Provide proper placeholder**

   ```swift
   case .failure:
       Circle()
           .fill(Color.gray.opacity(0.3))
           .overlay(Image(systemName: "person.fill"))
   ```

3. **Handle all AsyncImage phases**

   ```swift
   switch phase {
   case .success(let image): // Show image
   case .failure: // Show error placeholder
   case .empty: // Show loading
   @unknown default: // Future-proof
   }
   ```

4. **Use proper aspect ratio**
   ```swift
   .aspectRatio(contentMode: .fill) // Prevent distortion
   .frame(width: 100, height: 100)
   .clipShape(Circle())
   ```

### ❌ DON'Ts

1. ❌ Don't force unwrap optional values
2. ❌ Don't skip error handling
3. ❌ Don't forget loading state
4. ❌ Don't hardcode user-specific data
5. ❌ Don't skip URL validation

---

## 🧪 Testing Scenarios

| Scenario                  | Expected Result          |
| ------------------------- | ------------------------ |
| User with personal logo   | Display `logo` photo     |
| Klinik user (app_jenis=1) | Display `kl_logo`        |
| Apotek user (app_jenis=2) | Display `apt_logo`       |
| User with no logo         | Show placeholder         |
| Invalid URL               | Show error placeholder   |
| Slow network              | Show loading spinner     |
| Switch account            | Update photo immediately |

---

## 📊 Response Mapping

```swift
// From Login Response
{
    "logo": "demoK25_2025-06-24_11:41:27.png",
    "kl_logo": "logo_304_20250721170319.png",
    "app_jenis": 3
}

// To Swift Model
UserData(
    logo: "demoK25_2025-06-24_11:41:27.png",
    kl_logo: "logo_304_20250721170319.png",
    app_jenis: 3
)

// To URL
getUserPhotoURL() →
URL("https://vmedis.s3.amazonaws.com/demoK25_2025-06-24_11:41:27.png")
```

---

## 🔗 Related Files

1. **Login Service:**

   - `Services/LoginService.swift` - Login API call & response parsing

2. **Models:**

   - `Models/UserData.swift` - User data structure

3. **Views:**

   - `Views/Pages/MainTabView.swift` - Profile display
   - `Views/Pages/LoginPageView.swift` - Login flow

4. **Documentation:**
   - `USER_PROFILE_PHOTO_GUIDE.md` - Cross-platform guide
   - `MOBILE_IMAGE_LOADING_GUIDE.md` - React Native reference

---

## ✅ Implementation Status

- [x] UserData model includes `logo`, `kl_logo` fields
- [x] Login response parsing
- [x] `getUserPhotoURL()` helper function
- [x] AsyncImage integration in ProfileView
- [x] Placeholder handling
- [x] Error state handling
- [x] Loading state handling
- [x] Same logic as mobile lama

---

## 🎯 Quick Reference

### Get Photo URL

```swift
let photoURL = getUserPhotoURL()
```

### Display Photo

```swift
AsyncImage(url: photoURL) { phase in
    switch phase {
    case .success(let image):
        image.resizable()
    case .failure:
        placeholderImage
    case .empty:
        ProgressView()
    @unknown default:
        EmptyView()
    }
}
```

### Base URL

```swift
let baseImageURL = "https://vmedis.s3.amazonaws.com/"
```

---

## 📝 Notes

1. **Same as Mobile Lama:** Logika pengambilan foto sama persis dengan React Native version
2. **S3 URL:** Semua foto disimpan di AWS S3, path relatif disimpan di database
3. **Priority:** User logo > Apotek logo > Klinik logo > Placeholder
4. **Response Field:** Field `logo` dari response login langsung bisa digunakan
5. **No Additional API:** Tidak perlu API tambahan, foto sudah ada di response login
6. **⚠️ IMPORTANT:** Field `kl_logo` digunakan untuk logo **klinik DAN apotek**. Meski namanya `kl_logo`, isinya bisa logo apotek jika `app_jenis == 2`. Backend mengirim logo yang sesuai dengan institusi user di field `kl_logo`.

---

📅 **Last Updated:** January 2025  
👨‍💻 **Author:** Vmedis Development Team  
📱 **Platform:** iOS (Swift + SwiftUI)  
🔗 **Related:** React Native mobile lama implementation
