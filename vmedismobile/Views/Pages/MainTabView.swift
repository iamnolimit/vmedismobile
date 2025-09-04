// File: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    let userData: UserData
    @State private var selectedTab = 0
    
    var body: some View {        TabView(selection: $selectedTab) {
            // Home Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
                            .tabItem {
                                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                                Text("Home")
                            }
                            .tag(0)
            
            // Patients Tab
            PatientsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.3.fill" : "person.3")
                    Text("Patients")
                }
                .tag(1)
            
            // Transactions Tab
            TransactionsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "creditcard.fill" : "creditcard")
                    Text("Transactions")
                }
                .tag(2)
              // Profile Tab
            ProfileView(userData: userData)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    Text("Profile")
                }
                .tag(3)
            
            // Debug Tab (temporary for testing)
            BypassDebugView(userData: userData)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "wrench.fill" : "wrench")
                    Text("Debug")
                }
                .tag(4)
        }
        .accentColor(.blue)
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

// MARK: - Home View
struct HomeView: View {
    let userData: UserData
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome Back,")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                
                                Text(userData.nama_lengkap ?? "User")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            // Profile Image
                            AsyncImage(url: URL(string: "https://via.placeholder.com/50")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        }
                        
                        // Clinic Info
                        if let klinikName = userData.kl_nama {
                            Text(klinikName)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Quick Actions
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        QuickActionCard(
                            title: "New Patient",
                            icon: "person.badge.plus",
                            color: .green
                        ) {
                            // Handle new patient action
                        }
                        
                        QuickActionCard(
                            title: "New Transaction",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            // Handle new transaction action
                        }
                        
                        QuickActionCard(
                            title: "Reports",
                            icon: "chart.bar.fill",
                            color: .orange
                        ) {
                            // Handle reports action
                        }
                        
                        QuickActionCard(
                            title: "Inventory",
                            icon: "cube.box.fill",
                            color: .purple
                        ) {
                            // Handle inventory action
                        }
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(0..<3) { index in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Transaction #\(1000 + index)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("Patient consultation - Rp 150,000")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text("2h ago")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Patients View
struct PatientsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Patients")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Patient management coming soon...")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Patients")
        }
    }
}

// MARK: - Transactions View
struct TransactionsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Transactions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Transaction history coming soon...")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Transactions")
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let userData: UserData
    @EnvironmentObject var appState: AppState
    
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
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Profile Options
                    VStack(spacing: 0) {
                        ProfileOptionRow(icon: "gear", title: "Settings", action: {})
                        Divider()
                        ProfileOptionRow(icon: "bell", title: "Notifications", action: {})
                        Divider()
                        ProfileOptionRow(icon: "questionmark.circle", title: "Help & Support", action: {})
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
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Profile")
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
