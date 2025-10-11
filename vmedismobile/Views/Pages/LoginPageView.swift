// File: Views/Pages/LoginPageView.swift - Simplified for direct apotek/klinik login
import SwiftUI

struct LoginPageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var loginService = LoginService()
    
    @State private var subdomain: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var showPassword: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    // Fixed colors for apotek/klinik branding
    private let accentColor = Color.blue
    private let backgroundColor = Color.blue.opacity(0.1)
      var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
              VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        headerSection.padding(.top, 40)
                        loginFormSection
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Logo from Bundle Resource
            if let logoImage = UIImage(named: "logo") {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
            } else {
                // Fallback medical icon for apotek/klinik
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 120, height: 120)
                        .shadow(color: accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "cross.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            
            VStack(spacing: 12) {
                Text("Selamat Datang")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Masuk ke Vmedis Apotek / Klinik")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Login Form Section
        // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                CleanTextField(
                    title: "Subdomain",
                    text: $subdomain,
                    placeholder: "Masukkan nama subdomain",
                    suffix: ".vmedis.com",
                    icon: "building.2",
                    accentColor: accentColor
                )
                
                CleanTextField(
                    title: "Username",
                    text: $username,
                    placeholder: "Masukkan username",
                    icon: "person",
                    accentColor: accentColor
                )
                
                CleanPasswordField(
                    title: "Password",
                    text: $password,
                    placeholder: "Masukkan password",
                    showPassword: $showPassword,
                    accentColor: accentColor
                )
            }
            
            Button(action: {
                Task { await handleLogin() }
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Masuk")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isFormValid ? accentColor : Color.gray.opacity(0.4))
                .cornerRadius(16)
                .shadow(
                    color: isFormValid ? accentColor.opacity(0.4) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!isFormValid || isLoading)
            .scaleEffect(isFormValid ? 1.0 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFormValid)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 20) {
            Text("Powered by Vmedis V1.9.7")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
      // MARK: - Computed Properties
    private var isFormValid: Bool {
        !subdomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !password.isEmpty
    }
      // MARK: - Actions
    private func handleLogin() async {
        guard isFormValid else { return }
        
        isLoading = true
        let cleanSubdomain = subdomain.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let response = try await loginService.login(
                username: cleanUsername,
                password: password,
                domain: cleanSubdomain
            )
            
            if response.status == "success" {
                print("=== LOGIN SUCCESS - APOTEK/KLINIK ===")
                print("Domain: \(cleanSubdomain)")
                print("Username: \(cleanUsername)")
                
                if let userData = response.data {
                    print("User Data:")
                    print("- ID: \(userData.id ?? 0)")
                    print("- Username: \(userData.username ?? "")")
                    print("- Token: \(userData.token ?? "")")
                    print("- Klinik: \(userData.kl_nama ?? "")")
                    print("- Level: \(userData.lvl ?? 0)")
                    
                    // Update AppState with login data
                    await MainActor.run {
                        print("=== UPDATING APP STATE ===")
                        appState.login(with: userData)
                        print("AppState login successful")
                        print("isLoggedIn: \(appState.isLoggedIn)")
                    }
                }
                print("=====================================")
                
            } else {
                await MainActor.run {
                    alertTitle = "Login Gagal"
                    alertMessage = "Username atau password tidak valid"
                    showAlert = true
                }
            }
            
        } catch {
            await MainActor.run {
                alertTitle = "Error"
                if let loginError = error as? LoginError {
                    alertMessage = loginError.errorDescription ?? "Terjadi kesalahan yang tidak diketahui"
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
}

// MARK: - Clean Text Field
struct CleanTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var suffix: String? = nil
    let icon: String
    let accentColor: Color
    
    @FocusState private var isFocused: Bool
    
    var body: some View {        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? accentColor : .secondary)
                    .frame(width: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                
                if let suffix = suffix {
                    Text(suffix)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? accentColor : Color.secondary.opacity(0.3), lineWidth: isFocused ? 2 : 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Clean Password Field
struct CleanPasswordField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    let accentColor: Color
    
    @FocusState private var isFocused: Bool
    
    var body: some View {        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? accentColor : .secondary)
                    .frame(width: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                  if showPassword {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .focused($isFocused)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .focused($isFocused)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? accentColor : Color.secondary.opacity(0.3), lineWidth: isFocused ? 2 : 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}
