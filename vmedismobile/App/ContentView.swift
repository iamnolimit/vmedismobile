// File: App/ContentView.swift - With Account Picker Support and Navigation
import SwiftUI

// Navigation coordinator untuk mengelola navigasi antar views (iOS 15.6 compatible)
class NavigationCoordinator: ObservableObject {
    @Published var currentView: NavigationDestination = .login
    @Published var showForgotPassword = false
    @Published var showRegister = false
    
    enum NavigationDestination {
        case login
        case forgotPassword
        case register
        case mainTab
    }
    
    func navigate(to destination: NavigationDestination) {
        currentView = destination
    }
    
    func pushToForgotPassword() {
        showForgotPassword = true
    }
    
    func pushToRegister() {
        showRegister = true
    }
    
    func dismissForgotPassword() {
        showForgotPassword = false
    }
    
    func dismissRegister() {
        showRegister = false
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var navigationCoordinator = NavigationCoordinator()
      var body: some View {
        Group {
            if appState.isLoggedIn, let userData = appState.userData {
                MainTabView()
                    .environmentObject(appState)
                    .id(userData.id ?? "0") // Force complete re-render when userData changes
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
