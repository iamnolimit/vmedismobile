// File: Views/Pages/ViewsImport.swift - Explicit import for all page views
import SwiftUI

// This file ensures proper import resolution for all page views
// Import this file in any view that needs to reference other page views

extension View {
    // Helper for navigation to ensure views are properly recognized
    func navigateToForgotPassword() -> some View {
        NavigationLink(destination: ForgotPasswordView()) {
            self
        }
    }
    
    func navigateToRegister() -> some View {
        NavigationLink(destination: RegisterView()) {
            self
        }
    }
}
