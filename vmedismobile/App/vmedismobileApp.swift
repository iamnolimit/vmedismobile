// File: vmedismobileApp.swift - Lightweight for iOS 15.6+
import SwiftUI

@main
struct vmedismobileApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light) // Force light mode
        }
    }
}
