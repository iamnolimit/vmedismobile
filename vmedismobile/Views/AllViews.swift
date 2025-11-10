// File: Views/AllViews.swift - Central import for all views
import SwiftUI

// Import all page views to ensure they are available
// This helps resolve compilation issues with view references

// Views from Pages folder
public let _forgotPasswordView = ForgotPasswordView.self
public let _registerView = RegisterView.self  
public let _loginPageView = LoginPageView.self
public let _mainTabView = MainTabView.self
public let _accountPickerView = AccountPickerView.self

// Views from Components folder  
public let _sliderItemView = SliderItemView.self
public let _cloudShape = CloudShape.self

// Ensure all views are properly exported
extension ContentView {
    static func loadAllViews() {
        _ = _forgotPasswordView
        _ = _registerView
        _ = _loginPageView
        _ = _mainTabView
        _ = _accountPickerView
        _ = _sliderItemView
        _ = _cloudShape
    }
}
