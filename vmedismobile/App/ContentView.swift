// File: App/ContentView.swift - With Account Picker Support and Navigation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        Group {
            if appState.isLoggedIn, appState.userData != nil {
                MainTabView()
                    .environmentObject(appState)
                    .id(appState.userData?.id ?? "0") // Force complete re-render when userData changes
            } else if appState.showAccountPicker {
                AccountPickerView()
            } else {
                // For iOS 15.6 compatibility, use NavigationView instead of NavigationStack
                NavigationView {
                    LoginPageView()
                        .environmentObject(navigationCoordinator)
                        .navigationBarHidden(true)
                }
                .environmentObject(navigationCoordinator)
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.3), value: appState.showAccountPicker)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
