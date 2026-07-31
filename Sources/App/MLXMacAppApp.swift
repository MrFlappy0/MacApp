import SwiftUI

@main
struct MLXMacAppApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var modelViewModel = ModelViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(modelViewModel)
                .frame(minWidth: 1200, minHeight: 800)
                .windowStyle(.titleBar)
                .windowResizability(.contentSize)
        }
        .windowSizeRestrictions(minWidth: 1024, minHeight: 768)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(modelViewModel)
        }
    }
}
