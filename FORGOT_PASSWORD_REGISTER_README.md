# Fitur Lupa Password & Register - Vmedis Mobile Swift

## 📋 Overview

Dokumentasi ini menjelaskan implementasi fitur **Lupa Password** dan **Register (Buat Akun)** untuk aplikasi Vmedis Mobile iOS (Swift).

## 🎯 Fitur yang Ditambahkan

### 1. **Lupa Password** (`ForgotPasswordView.swift`)

- User dapat mereset password dengan memasukkan domain dan email
- Validasi domain sebelum proses reset
- Integrasi dengan GraphQL API Vmedis
- Link reset dikirim ke email user

### 2. **Register / Buat Akun** (`RegisterView.swift`)

- User dapat mendaftar akun baru
- Validasi domain availability
- Form lengkap: domain, nama lengkap, username, email, no. WhatsApp, password
- Password validation real-time (minimal 6 karakter, password match)
- Terms & conditions agreement

## 📁 File yang Ditambahkan

```
vmedismobile/
├── Views/
│   └── Pages/
│       ├── ForgotPasswordView.swift       # UI Lupa Password
│       ├── RegisterView.swift             # UI Register
│       └── LoginPageView.swift            # Updated with links
└── Services/
    ├── ForgotPasswordService.swift        # Service untuk reset password
    └── RegisterService.swift              # Service untuk registrasi
```

## 🔧 Cara Kerja

### Forgot Password Flow

1. **User Input**: User memasukkan domain dan email
2. **Domain Validation**: Cek domain tersedia via API
   ```swift
   POST https://vmedis.com/site/cek-domain-tersedia
   Body: domain=<subdomain>
   ```
3. **Reset Request**: Kirim request reset via GraphQL
   ```graphql
   mutation {
     vmedresetuser(domain: "<domain>", email: "<email>") {
       gak
       user {
         user_id
         email
         nama_lengkap
       }
       errors {
         path
         message
       }
     }
   }
   ```
4. **Email Sent**: Link reset dikirim ke email user
5. **Success**: User diarahkan kembali ke login page

### Register Flow

1. **User Input**: User mengisi form lengkap:

   - Domain (subdomain.vmedis.com)
   - Nama Lengkap
   - Username
   - Email
   - No. WhatsApp (format: 08xxxxxxxxxx)
   - Password (minimal 6 karakter)
   - Confirm Password

2. **Client-side Validation**:

   - Domain tidak kosong
   - Email format valid (@)
   - No. WhatsApp dimulai dengan 08
   - Password ≥ 6 karakter
   - Password match

3. **Domain Availability Check**:

   ```swift
   POST https://vmedis.com/site/cek-domain-tersedia
   Body: domain=<subdomain>
   ```

4. **Registration Request**:

   ```swift
   POST https://api.vmedis.com/api/v1/register
   Content-Type: application/json
   Body: {
       "domain": "...",
       "nama_lengkap": "...",
       "username": "...",
       "email": "...",
       "user_wa": "...",
       "password": "...",
       "device": "mobile_ios"
   }
   ```

5. **Success**: User diarahkan untuk login dengan akun baru

## 🎨 UI Components

### ForgotPasswordView

- Clean minimal design
- Domain + Email input fields
- Loading state with spinner
- Alert for success/error messages
- Back button to return to login

### RegisterView

- Comprehensive form with 7 fields
- Password visibility toggle
- Real-time password validation indicators:
  - ✓ Minimal 6 karakter
  - ✓ Password cocok
- Terms & conditions note
- Loading state with spinner
- Alert for success/error messages
- Back button to return to login

### Updated LoginPageView

- "Lupa Password?" link below login button
- "Belum punya akun? Buat Akun" link in footer

## 🔐 Security

1. **Password Requirements**:

   - Minimal 6 karakter
   - Confirm password harus match

2. **Domain Validation**:

   - Check availability sebelum register
   - Check exists sebelum reset password

3. **API Security**:
   - HTTPS untuk semua requests
   - Proper error handling
   - Tidak menyimpan sensitive data di client

## 📱 Navigasi

```
LoginPageView
├── [Tap "Lupa Password?"] → ForgotPasswordView
│   └── [Success] → Back to LoginPageView
└── [Tap "Buat Akun"] → RegisterView
    └── [Success] → Back to LoginPageView
```

## ⚙️ Konfigurasi

### API Endpoints

Ubah endpoint sesuai environment Anda:

**ForgotPasswordService.swift**:

```swift
let graphqlEndpoint = "https://apollo.vmedis.com/graphql"
```

**RegisterService.swift**:

```swift
let registerEndpoint = "https://api.vmedis.com/api/v1/register"
```

### Domain Validation URL

```swift
let url = URL(string: "https://vmedis.com/site/cek-domain-tersedia")!
```

## 🧪 Testing

### Test Scenarios

#### Forgot Password

1. ✅ Valid domain & email → Success message
2. ❌ Invalid domain → Error: "Domain tidak tersedia"
3. ❌ Email tidak terdaftar → Error: "Email tidak terdaftar"
4. ❌ Empty fields → Button disabled

#### Register

1. ✅ Valid form data → Success, redirect to login
2. ❌ Domain sudah digunakan → Error: "Domain sudah digunakan"
3. ❌ Email tidak valid → Button disabled
4. ❌ Password < 6 karakter → Button disabled
5. ❌ Password tidak match → Button disabled
6. ❌ No. WA tidak dimulai 08 → Button disabled

## 🚀 Deployment

1. **Add files to Xcode project**:

   - Drag & drop semua file ke project
   - Pastikan target membership correct

2. **Update navigation**:

   - Pastikan `LoginPageView` wrapped in `NavigationView`

3. **Test build**:

   ```bash
   # Build for simulator
   xcodebuild -scheme vmedismobile -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

4. **Run on device/simulator**

## 🐛 Troubleshooting

### Issue: "Cannot find type 'ForgotPasswordView' in scope"

**Solution**: Pastikan file sudah ditambahkan ke Xcode project dengan target membership yang benar.

### Issue: "Navigation not working"

**Solution**: Pastikan `LoginPageView` di-wrap dengan `NavigationView`:

```swift
NavigationView {
    LoginPageView()
}
```

### Issue: "API request failed"

**Solution**:

1. Cek network connection
2. Verify API endpoint URLs
3. Check response format di console log
4. Validate JSON parsing

## 📞 Support

Untuk pertanyaan atau issue:

1. Check console logs untuk debugging
2. Verify API responses
3. Contact backend team untuk API issues

## 📝 TODO / Future Improvements

- [ ] Add biometric authentication option
- [ ] Remember domain functionality
- [ ] Social login (Google, Apple)
- [ ] Email verification after register
- [ ] Password strength indicator
- [ ] Resend verification email
- [ ] Username availability check real-time
- [ ] Email availability check real-time
- [ ] Captcha for security

## 📄 License

© 2024 PT VIRTUAL MEDIS INTERNASIONAL. All rights reserved.
