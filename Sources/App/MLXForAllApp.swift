import SwiftUI

@main
struct MLXForAllApp: App {
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appSettings)
                .frame(minWidth: 1024, minHeight: 768)
                .preferredColorScheme(appSettings.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .windowSizeRestrictions(minWidth: 800, minHeight: 600)
        
        // Fenêtre des paramètres
        Settings {
            SettingsView()
                .environmentObject(appSettings)
        }
    }
}

// Vue principale
struct MainView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(appSettings)
        } detail: {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}

// Barre latérale
struct SidebarView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        List(selection: $appSettings.currentTab) {
            Section("Principal") {
                NavigationLink(value: AppSettings.Tab.chat) {
                    Label("Chat", systemImage: "bubble.left")
                }
                .tag(AppSettings.Tab.chat)
                
                NavigationLink(value: AppSettings.Tab.models) {
                    Label("Modèles", systemImage: "brain.head.profile")
                }
                .tag(AppSettings.Tab.models)
            }
            
            Section("Outils") {
                NavigationLink(value: AppSettings.Tab.mcp) {
                    Label("MCP", systemImage: "wrench")
                }
                .tag(AppSettings.Tab.mcp)
                
                NavigationLink(value: AppSettings.Tab.files) {
                    Label("Fichiers", systemImage: "folder")
                }
                .tag(AppSettings.Tab.files)
            }
            
            Section("Configuration") {
                NavigationLink(value: AppSettings.Tab.settings) {
                    Label("Paramètres", systemImage: "gear")
                }
                .tag(AppSettings.Tab.settings)
            }
        }
        .navigationTitle("MLX for All")
        .listStyle(.sidebar)
    }
}

// Vue de contenu principale
struct ContentView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Group {
            switch appSettings.currentTab {
            case .chat:
                ChatView()
                    .environmentObject(appSettings)
            case .models:
                ModelsView()
                    .environmentObject(appSettings)
            case .mcp:
                MCPView()
                    .environmentObject(appSettings)
            case .files:
                FilesView()
                    .environmentObject(appSettings)
            case .settings:
                SettingsView()
                    .environmentObject(appSettings)
            }
        }
        .navigationTitle(appSettings.currentTab.title)
        .navigationSubtitle(appSettings.currentTab.subtitle)
    }
}

// Extension pour les onglets
extension AppSettings.Tab {
    var title: String {
        switch self {
        case .chat: return "Chat"
        case .models: return "Gestion des Modèles"
        case .mcp: return "Outils MCP"
        case .files: return "Gestion des Fichiers"
        case .settings: return "Paramètres"
        }
    }
    
    var subtitle: String {
        switch self {
        case .chat: return "Discutez avec l'IA"
        case .models: return "Téléchargez et gérez les modèles"
        case .mcp: return "Configurez les outils"
        case .files: return "Gérez vos fichiers"
        case .settings: return "Configurez l'application"
        }
    }
}
