// File: App/ContentView.swift - With Account Picker Support
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn, let userData = appState.userData {
                MainTabView(userData: userData)
            } else if appState.showAccountPicker {
                AccountPickerView()
            } else {
                LoginPageView()
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
