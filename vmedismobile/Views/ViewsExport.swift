// File: Views/ViewsExport.swift - Export all Views for better module recognition
import SwiftUI

// This file ensures all Views are properly exported and accessible

// Re-export Views from Pages folder
public typealias VLoginPageView = LoginPageView
public typealias VForgotPasswordView = ForgotPasswordView  
public typealias VRegisterView = RegisterView
public typealias VMainTabView = MainTabView
public typealias VAccountPickerView = AccountPickerView

// Re-export Components
public typealias VSliderItemView = SliderItemView
public typealias VCloudShape = CloudShape
