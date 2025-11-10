// File: Navigation/NavigationCoordinator.swift - Central navigation management
import SwiftUI

// Navigation coordinator untuk mengelola navigasi antar views
class NavigationCoordinator: ObservableObject {
    @Published var currentView: NavigationDestination = .login
    @Published var navigationPath = NavigationPath()
    
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
        navigationPath.append(NavigationDestination.forgotPassword)
    }
    
    func pushToRegister() {
        navigationPath.append(NavigationDestination.register)
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

// Navigation view wrapper untuk handling semua navigasi
struct NavigationContainer<Content: View>: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            content()
                .navigationDestination(for: NavigationCoordinator.NavigationDestination.self) { destination in
                    switch destination {                    
                    case .login:
                        LoginPageView()
                    case .forgotPassword:
                        ForgotPasswordView()
                    case .register:
                        RegisterView()
                    case .mainTab:
                        EmptyView() // TODO: Replace with actual MainTabView
                    }                }
        }
    }
}
