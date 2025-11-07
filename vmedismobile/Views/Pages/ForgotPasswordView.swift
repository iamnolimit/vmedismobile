// File: Views/Pages/ForgotPasswordView.swift
import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var forgotPasswordService = ForgotPasswordService()
    
    @State private var domain: String = ""
    @State private var email: String = ""
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
                    VStack(spacing: 40) {
                        iconSection
                            .padding(.top, 20)
                        formSection
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
                
                Image(systemName: "key.fill")
                    .font(.system(size: 45))
                    .foregroundColor(accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Lupa Password?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Masukkan domain dan email Anda untuk reset password")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                CleanTextField(
                    title: "Domain",
                    text: $domain,
                    placeholder: "Masukkan nama domain",
                    suffix: ".vmedis.com",
                    icon: "building.2",
                    accentColor: accentColor
                )
                
                CleanTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "Masukkan email Anda",
                    icon: "envelope",
                    accentColor: accentColor
                )
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            }
            
            Button(action: {
                Task { await handleResetPassword() }
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Kirim Link Reset")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "paperplane.fill")
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
    }
    
    private var isFormValid: Bool {
        !domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
    
    private func handleResetPassword() async {
        guard isFormValid else { return }
        
        isLoading = true
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let response = try await forgotPasswordService.requestResetPassword(
                domain: cleanDomain,
                email: cleanEmail
            )
            
            await MainActor.run {
                isLoading = false
                
                if response.status == "success" {
                    isSuccess = true
                    alertTitle = "Berhasil!"
                    alertMessage = "Link reset password telah dikirim ke email Anda. Silakan cek inbox atau folder spam Anda."
                } else {
                    alertTitle = "Reset Password Gagal"
                    alertMessage = response.message ?? "Email tidak terdaftar atau domain tidak valid"
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

#Preview {
    ForgotPasswordView()
}
