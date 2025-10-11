# 🔐 Domain Validation Implementation - Swift

## 🎯 Overview

Implementasi validasi domain sebelum login untuk memastikan subdomain yang dimasukkan user valid dan tersedia di sistem Vmedis.

**Flow:** Domain Validation → Login → Success/Error

---

## 📋 Requirements

### API Endpoint

**URL:** `https://api3penjualan.vmedis.com/klinik/validate-domain`

**Method:** POST

**Content-Type:** `application/x-www-form-urlencoded`

**Parameters:**
```
domain: {subdomain}
```

### Response Success
```json
{
    "status": "success",
    "data": {
        "app_id": "5177",
        "kl_id": "458",
        "kl_nama": "DEMO APOTEKKLINIK PEMUDA 30",
        "kl_logo": "logo_458_20250925090436.png",
        "apt_nama": "DEMO APOTEKKLINIK PEMUDA 30",
        "apt_logo": "458251003131055.png"
    }
}
```

### Response Failed
```json
{
    "status": "failed"
}
```

---

## 📂 Files Modified

### 1. **LoginService.swift** - Add Domain Validation

#### New Structs
```swift
struct DomainValidationResponse: Codable {
    let status: String
    let data: DomainData?
}

struct DomainData: Codable {
    let app_id: String?
    let kl_id: String?
    let kl_nama: String?
    let kl_logo: String?
    let apt_nama: String?
    let apt_logo: String?
}
```

#### New Function
```swift
@MainActor
class LoginService: ObservableObject {
    private let baseURL = "https://api3.vmedis.com"
    private let domainValidationURL = "https://api3penjualan.vmedis.com"
    
    func validateDomain(_ domain: String) async throws -> DomainValidationResponse {
        guard let url = URL(string: "\(domainValidationURL)/klinik/validate-domain") else {
            throw LoginError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = ["domain": domain]
        
        // Convert to form data
        var formDataString = ""
        for (key, value) in parameters {
            if !formDataString.isEmpty {
                formDataString += "&"
            }
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                formDataString += "\(encodedKey)=\(encodedValue)"
            }
        }
        
        request.httpBody = formDataString.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let domainResponse = try JSONDecoder().decode(DomainValidationResponse.self, from: data)
        
        return domainResponse
    }
}
```

#### Updated Error Enum
```swift
enum LoginError: LocalizedError {
    case invalidURL
    case encodingError
    case decodingError(String)
    case networkError(Error)
    case invalidCredentials
    case serverError(String)
    case domainNotFound        // ← NEW
    case usernameNotFound      // ← NEW
    case wrongPassword         // ← NEW
    
    var errorDescription: String? {
        switch self {
        case .domainNotFound:
            return "Domain tidak tersedia"
        case .usernameNotFound:
            return "Username salah"
        case .wrongPassword:
            return "Password salah"
        // ... other cases
        }
    }
}
```

---

### 2. **LoginPageView.swift** - Update Login Flow

#### Updated handleLogin()
```swift
private func handleLogin() async {
    guard isFormValid else { return }
    
    isLoading = true
    let cleanSubdomain = subdomain.trimmingCharacters(in: .whitespacesAndNewlines)
    let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
    
    do {
        // STEP 1: Validasi domain terlebih dahulu
        print("=== STEP 1: VALIDATING DOMAIN ===")
        let domainValidation = try await loginService.validateDomain(cleanSubdomain)
        
        if domainValidation.status != "success" {
            // Domain tidak tersedia
            await MainActor.run {
                alertTitle = "Login Gagal"
                alertMessage = "Domain tidak tersedia"
                showAlert = true
                isLoading = false
            }
            return
        }
        
        print("✅ Domain valid, proceeding to login...")
        
        // STEP 2: Lanjutkan ke login jika domain valid
        print("=== STEP 2: LOGGING IN ===")
        let response = try await loginService.login(
            username: cleanUsername,
            password: password,
            domain: cleanSubdomain
        )
        
        if response.status == "success" {
            // Login berhasil
            if let userData = response.data {
                await MainActor.run {
                    appState.login(with: userData)
                }
            }
        } else if response.status == "error" {
            // Handle specific error messages
            await MainActor.run {
                alertTitle = "Login Gagal"
                
                if let message = response.message {
                    if message.lowercased().contains("password") {
                        alertMessage = "Password salah"
                    } else if message.lowercased().contains("username") || 
                              message.lowercased().contains("tidak ditemukan") {
                        alertMessage = "Username salah"
                    } else {
                        alertMessage = message
                    }
                } else {
                    alertMessage = "Username atau password tidak valid"
                }
                
                showAlert = true
            }
        }
        
    } catch {
        // Handle errors
        await MainActor.run {
            alertTitle = "Error"
            
            if let loginError = error as? LoginError {
                switch loginError {
                case .domainNotFound:
                    alertMessage = "Domain tidak tersedia"
                case .usernameNotFound:
                    alertMessage = "Username salah"
                case .wrongPassword:
                    alertMessage = "Password salah"
                default:
                    alertMessage = loginError.errorDescription ?? "Terjadi kesalahan"
                }
            } else {
                alertMessage = "Kesalahan jaringan: \(error.localizedDescription)"
            }
            
            showAlert = true
        }
    }
    
    await MainActor.run {
        isLoading = false
    }
}
```

---

## 🔄 Login Flow

```
┌─────────────────────────────────────┐
│   User Input Domain + Credentials   │
│   - subdomain                       │
│   - username                        │
│   - password                        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   STEP 1: Validate Domain           │
│   POST /klinik/validate-domain      │
│   Params: { domain: subdomain }     │
└──────────────┬──────────────────────┘
               │
        ┌──────┴───────┐
        │              │
   status=="success"   status=="failed"
        │              │
        ▼              ▼
   ┌─────────┐   ┌──────────────────┐
   │Continue │   │ STOP & Alert:    │
   │to Login │   │ "Domain tidak    │
   │         │   │  tersedia"       │
   └────┬────┘   └──────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│   STEP 2: Login                     │
│   POST /sys/login                   │
│   Params: { u, p, t, device, ... }  │
└──────────────┬──────────────────────┘
               │
        ┌──────┴───────────┐
        │                  │
   status=="success"   status=="error"
        │                  │
        ▼                  ▼
   ┌─────────┐   ┌─────────────────────┐
   │ LOGIN   │   │ Check Error Message │
   │ SUCCESS │   │                     │
   │         │   │ message.contains:   │
   │ Update  │   │ - "password"        │
   │ AppState│   │   → "Password salah"│
   │         │   │                     │
   │         │   │ - "username" atau   │
   │         │   │   "tidak ditemukan" │
   │         │   │   → "Username salah"│
   │         │   │                     │
   │         │   │ - other             │
   │         │   │   → Show message    │
   └─────────┘   └─────────────────────┘
```

---

## 🎯 Error Handling

### 1. Domain Validation Errors

| Scenario | Response | Alert Title | Alert Message |
|----------|----------|-------------|---------------|
| Domain not found | `status: "failed"` | Login Gagal | Domain tidak tersedia |
| Network error | Exception | Error | Kesalahan jaringan: ... |

### 2. Login Errors

| Scenario | Response | Alert Title | Alert Message |
|----------|----------|-------------|---------------|
| Wrong password | `status: "error"`, `message: "password salah!"` | Login Gagal | Password salah |
| Username not found | `status: "error"`, `message: "username tidak ditemukan dalam database!"` | Login Gagal | Username salah |
| Other errors | `status: "error"`, custom message | Login Gagal | {message from API} |
| Network error | Exception | Error | Kesalahan jaringan: ... |

---

## 💡 Key Features

### ✅ Implemented

1. **Two-Step Validation**
   - Domain validation first
   - Login only if domain is valid

2. **Specific Error Messages**
   - "Domain tidak tersedia" - for invalid domain
   - "Password salah" - for wrong password
   - "Username salah" - for username not found
   - Custom messages for other errors

3. **User-Friendly Flow**
   - Clear error messages in Indonesian
   - Loading state during validation
   - Stop login if domain invalid (save API call)

4. **Debug Logging**
   - Log domain validation step
   - Log login step
   - Log responses for debugging

---

## 🧪 Testing Scenarios

| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| Valid domain + valid credentials | domain: "demo", username: "user1", password: "pass1" | Login success |
| Invalid domain | domain: "notexist", username: "user1", password: "pass1" | Alert: "Domain tidak tersedia" |
| Valid domain + wrong password | domain: "demo", username: "user1", password: "wrong" | Alert: "Password salah" |
| Valid domain + wrong username | domain: "demo", username: "wronguser", password: "pass1" | Alert: "Username salah" |
| Network error during validation | Network timeout | Alert: "Kesalahan jaringan: ..." |
| Network error during login | Network timeout | Alert: "Kesalahan jaringan: ..." |

---

## 📊 API Comparison

### Domain Validation API
```
Endpoint: https://api3penjualan.vmedis.com/klinik/validate-domain
Method: POST
Content-Type: application/x-www-form-urlencoded
Body: domain={subdomain}
```

### Login API
```
Endpoint: https://api3.vmedis.com/sys/login
Method: POST
Content-Type: application/x-www-form-urlencoded
Body: u={username}&p={password}&t={domain}&device=ios&ip=&date={timestamp}
```

---

## 🔗 Related Files

1. **Services:**
   - `Services/LoginService.swift` - Domain validation & login logic

2. **Views:**
   - `Views/Pages/LoginPageView.swift` - Login UI & flow

3. **Models:**
   - `DomainValidationResponse` - Domain validation response model
   - `DomainData` - Domain data model
   - `LoginResponse` - Login response model
   - `UserData` - User data model

4. **Errors:**
   - `LoginError` - Custom error enum

---

## 📝 Notes

1. **Validation First:** Always validate domain before attempting login
2. **Error Messages:** Use Indonesian for better UX
3. **Network Efficiency:** Stop early if domain invalid (save 1 API call)
4. **Debugging:** Console logs help track the flow
5. **Future Enhancement:** Could cache validated domains to reduce API calls

---

## ✅ Implementation Status

- [x] Add DomainValidationResponse struct
- [x] Add DomainData struct
- [x] Add validateDomain() function
- [x] Update LoginError enum
- [x] Update handleLogin() flow
- [x] Add domain validation step
- [x] Handle domain validation errors
- [x] Handle login errors (password/username)
- [x] Add specific error messages
- [x] Test all scenarios

---

📅 **Last Updated:** October 2025  
👨‍💻 **Author:** Vmedis Development Team  
📱 **Platform:** iOS (Swift + SwiftUI)  
🔗 **API Version:** api3 & api3penjualan
