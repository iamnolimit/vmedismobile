// File: Navigation/NavigationCoordinator.swift - Central navigation management for iOS 15.6+
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
