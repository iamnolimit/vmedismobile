// File: vmedismobileApp.swift
import SwiftUI

@main
struct vmedismobileApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn, let userData = appState.userData {
                MainTabView(userData: userData)
                    .environmentObject(appState)
            } else {
                ContentView()
                    .environmentObject(appState)
            }
        }
    }
}
