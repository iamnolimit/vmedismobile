// File: Views/Pages/RegisterView.swift
import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var registerService = RegisterService()
    
    @State private var domain: String = ""
    @State private var namaLengkap: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var noWhatsApp: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSuccess = false
    
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
                // Header with back button
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        iconSection
                            .padding(.top, 20)
                        formSection
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Kembali")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(accentColor)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    private var iconSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 45))
                    .foregroundColor(accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Buat Akun Baru")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Daftar untuk menggunakan Vmedis Apotek / Klinik")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 18) {
                CleanTextField(
                    title: "Domain",
                    text: $domain,
                    placeholder: "Masukkan nama domain",
                    suffix: ".vmedis.com",
                    icon: "building.2",
                    accentColor: accentColor
                )
                
                CleanTextField(
                    title: "Nama Lengkap",
                    text: $namaLengkap,
                    placeholder: "Masukkan nama lengkap",
                    icon: "person",
                    accentColor: accentColor
                )
                
                CleanTextField(
                    title: "Username",
                    text: $username,
                    placeholder: "Masukkan username",
                    icon: "at",
                    accentColor: accentColor
                )
                .textInputAutocapitalization(.never)
                
                CleanTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "Masukkan email",
                    icon: "envelope",
                    accentColor: accentColor
                )
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                
                CleanTextField(
                    title: "No. WhatsApp",
                    text: $noWhatsApp,
                    placeholder: "08xxxxxxxxxx",
                    icon: "phone.fill",
                    accentColor: accentColor
                )
                .keyboardType(.phonePad)
                
                CleanPasswordField(
                    title: "Password",
                    text: $password,
                    placeholder: "Minimal 6 karakter",
                    showPassword: $showPassword,
                    accentColor: accentColor
                )
                
                CleanPasswordField(
                    title: "Konfirmasi Password",
                    text: $confirmPassword,
                    placeholder: "Ketik ulang password",
                    showPassword: $showConfirmPassword,
                    accentColor: accentColor
                )
                
                // Password validation hints
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ValidationRow(
                            isValid: password.count >= 6,
                            text: "Minimal 6 karakter"
                        )
                        ValidationRow(
                            isValid: password == confirmPassword && !confirmPassword.isEmpty,
                            text: "Password cocok"
                        )
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 4)
                }
            }
            
            Button(action: {
                Task { await handleRegister() }
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Daftar Sekarang")
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
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Dengan mendaftar, Anda menyetujui")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text("Syarat & Ketentuan")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Text("dan")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("Kebijakan Privasi")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)
            }
        }
    }
    
    private var isFormValid: Bool {
        !domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !namaLengkap.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !noWhatsApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        noWhatsApp.hasPrefix("08") &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func handleRegister() async {
        guard isFormValid else { return }
        
        isLoading = true
        
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNamaLengkap = namaLengkap.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNoWA = noWhatsApp.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let response = try await registerService.register(
                domain: cleanDomain,
                namaLengkap: cleanNamaLengkap,
                username: cleanUsername,
                email: cleanEmail,
                noWhatsApp: cleanNoWA,
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                
                if response.status == "success" {
                    isSuccess = true
                    alertTitle = "Berhasil Mendaftar!"
                    alertMessage = "Akun Anda berhasil dibuat. Silakan login dengan username dan password yang telah Anda buat."
                } else {
                    alertTitle = "Pendaftaran Gagal"
                    alertMessage = response.message ?? "Terjadi kesalahan saat mendaftar. Silakan coba lagi."
                }
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertTitle = "Kesalahan"
                alertMessage = "Terjadi kesalahan. Silakan coba lagi."
                showAlert = true
            }
        }
    }
}

// MARK: - Validation Row Component
struct ValidationRow: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isValid ? .green : .gray.opacity(0.5))
            
            Text(text)
                .foregroundColor(isValid ? .green : .secondary)
        }
    }
}

#Preview {
    RegisterView()
}
