// File: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    let userData: UserData
    @State private var selectedTab = 0
    @State private var refreshId = UUID()
    
    var body: some View {        TabView(selection: $selectedTab) {
            // 1. Home Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
                .id(refreshId)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            // 2. Obat Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
                .id(refreshId)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                    Text("Obat")
                }
                .tag(1)
            
            // 3. Keuangan Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=orders")
                .id(refreshId)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "banknote.fill" : "banknote")
                    Text("Keuangan")
                }
                .tag(2)
                  // 4. Forecast Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=forecast")
                .id(refreshId)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Forecast")
                }
                .tag(3)
                
            // 5. Account Tab - Using native ProfileView with Customer menu
            ProfileView(userData: userData)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                    Text("Akun")
                }
                .tag(4)
              }
        .accentColor(.blue)
        .onAppear {
            // Force refresh all WebViews when MainTabView appears (after login)
            refreshId = UUID()
        }
        .onAppear {
            // Customize tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.white
            
            // Selected item color
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]
            
            // Unselected item color
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let userData: UserData
    @EnvironmentObject var appState: AppState
    @State private var showingCustomer = false
    @State private var showingLaporanPenjualanObat = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        AsyncImage(url: URL(string: "https://via.placeholder.com/100")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(spacing: 4) {
                            Text(userData.nama_lengkap ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(userData.username ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let klinikName = userData.kl_nama {
                                Text(klinikName)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }                    .padding()
                    
                    // Profile Options                    VStack(spacing: 0) {
                        ProfileOptionRow(icon: "person.3", title: "Customer", action: {
                            showingCustomer = true
                        })
                        Divider()
                        ProfileOptionRow(icon: "chart.bar.doc.horizontal", title: "Laporan Penjualan Obat", action: {
                            showingLaporanPenjualanObat = true
                        })
                        Divider()
                        ProfileOptionRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Logout",
                            action: {
                                appState.logout()
                            }
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))            .navigationTitle("Profile")
            .sheet(isPresented: $showingCustomer) {
                CustomerView(userData: userData)
            }
            .sheet(isPresented: $showingLaporanPenjualanObat) {
                LaporanPenjualanObatView(userData: userData)
            }
        }
    }


// MARK: - Profile Option Row
struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

// MARK: - Customer View
struct CustomerView: View {
    let userData: UserData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=customers")
                .navigationTitle("Customer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Laporan Penjualan Obat View
struct LaporanPenjualanObatView: View {
    let userData: UserData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=lappenjualanobat")
                .navigationTitle("Laporan Penjualan Obat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
