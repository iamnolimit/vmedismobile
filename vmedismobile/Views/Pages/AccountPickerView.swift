// File: Views/Pages/AccountPickerView.swift
import SwiftUI

/// View untuk memilih akun saat startup jika ada multiple sessions
struct AccountPickerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedSession: AccountSession?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Pilih Akun")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Pilih akun yang ingin Anda gunakan")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Account List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sessionManager.sessions) { session in
                            AccountPickerRow(
                                session: session,
                                isSelected: selectedSession?.id == session.id,
                                onTap: {
                                    selectedSession = session
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Actions
                VStack(spacing: 12) {
                    // Continue Button
                    Button(action: {
                        if let session = selectedSession {
                            appState.switchAccount(to: session)
                        }
                    }) {
                        HStack {
                            Text("Lanjutkan")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(selectedSession != nil ? Color.blue : Color.gray.opacity(0.4))
                        .cornerRadius(12)
                    }
                    .disabled(selectedSession == nil)
                    .padding(.horizontal, 24)
                    
                    // Add New Account
                    Button(action: {
                        // Go to login page
                        sessionManager.clearAllSessions()
                        appState.logoutAllAccounts()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Tambah Akun Baru")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Auto-select active session jika ada
            if let active = sessionManager.activeSession {
                selectedSession = active
            } else if let first = sessionManager.sessions.first {
                selectedSession = first
            }
        }
    }
}

// MARK: - Account Picker Row
struct AccountPickerRow: View {
    let session: AccountSession
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                AsyncImage(url: getPhotoURL()) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty, @unknown _:
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(session.domainInfo)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Terakhir digunakan: \(formatDate(session.lastAccessTime))")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getPhotoURL() -> URL? {
        let baseImageURL = "https://apt.vmedis.com/foto/"
        
        if let userLogo = session.userData.logo, !userLogo.isEmpty {
            return URL(string: baseImageURL + userLogo)
        }
        
        let appJenis = session.userData.app_jenis ?? 1
        if appJenis == 2 {
            if let aptLogo = session.userData.kl_logo, !aptLogo.isEmpty {
                return URL(string: baseImageURL + aptLogo)
            }
        } else {
            if let klLogo = session.userData.kl_logo, !klLogo.isEmpty {
                return URL(string: baseImageURL + klLogo)
            }
        }
        
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
struct AccountPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AccountPickerView()
            .environmentObject(AppState())
    }
}
