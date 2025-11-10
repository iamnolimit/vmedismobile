// File: Views/Pages/ViewWrappers.swift - Lazy loading wrappers for navigation
import SwiftUI

// MARK: - Lazy Loading Wrappers
// These wrappers help resolve compilation issues with circular dependencies

@available(iOS 14.0, *)
struct ForgotPasswordViewWrapper: View {
    var body: some View {
        ForgotPasswordView()
    }
}

@available(iOS 14.0, *)
struct RegisterViewWrapper: View {
    var body: some View {
        RegisterView()
    }
}

@available(iOS 14.0, *)
struct LoginPageViewWrapper: View {
    var body: some View {
        LoginPageView()
    }
}

// MARK: - Navigation Helpers
extension View {
    @available(iOS 14.0, *)
    func presentForgotPassword(isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            ForgotPasswordViewWrapper()
        }
    }
    
    @available(iOS 14.0, *)
    func presentRegister(isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            RegisterViewWrapper()
        }
    }
}
