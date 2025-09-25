// File: App/ContentView.swift - Direct Login for Apotek/Klinik
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn, let userData = appState.userData {
                MainTabView(userData: userData)
            } else {
                LoginPageView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
