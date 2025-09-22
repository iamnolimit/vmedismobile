// File: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    let userData: UserData
    @State private var selectedTab = 0
      var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Home Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            // 2. Obat Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                    Text("Obat")
                }
                .tag(1)
            
            // 3. Keuangan Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=orders")
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "banknote.fill" : "banknote")
                    Text("Keuangan")
                }
                .tag(2)
                
            // 4. Forecast Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=forecast")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Forecast")
                }
                .tag(3)
            
            // 5. Customer Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=customers")
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.3.fill" : "person.3")
                    Text("Customer")
                }
                .tag(4)
                
            // 6. Profile Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=profile")
                .tabItem {
                    Image(systemName: selectedTab == 5 ? "person.circle.fill" : "person.circle")
                    Text("Profil")
                }
                .tag(5)
            
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
