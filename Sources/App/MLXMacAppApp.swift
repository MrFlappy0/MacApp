import SwiftUI

@main
struct MLXMacAppApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var chatSessionManager = ChatSessionManager.shared
    @StateObject private var modelViewModel = ModelViewModel.shared
    
    // Gestion du thème
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(chatSessionManager)
                .environmentObject(modelViewModel)
                .frame(minWidth: 1024, minHeight: 768)
                .preferredColorScheme(appState.getCurrentColorScheme())
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .windowSizeRestrictions(minWidth: 800, minHeight: 600)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(modelViewModel)
        }
    }
}

// Vue des paramètres mise à jour
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Apparence")) {
                    Picker("Thème", selection: $appState.settings.theme) {
                        ForEach(AppState.Settings.Theme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Performances")) {
                    Toggle("Accélération Metal", isOn: $appState.settings.useMetalAcceleration)
                    
                    Picker("Précision", selection: $appState.settings.precision) {
                        ForEach(AppState.Settings.Precision.allCases, id: \.self) { precision in
                            Text(precision.rawValue).tag(precision)
                        }
                    }
                    
                    Picker("Périphérique", selection: $appState.settings.device) {
                        ForEach(AppState.Settings.Device.allCases, id: \.self) { device in
                            Text(device.rawValue).tag(device)
                        }
                    }
                    
                    Stepper("Taille du batch: \(appState.settings.batchSize)", value: $appState.settings.batchSize, in: 1...16)
                }
                
                Section(header: Text("MCP")) {
                    Toggle("Activer MCP", isOn: $appState.mcpEnabled)
                    
                    if appState.mcpEnabled {
                        NavigationLink {
                            MCPToolsView()
                        } label: {
                            Text("Gérer les outils")
                        }
                    }
                }
                
                Section(header: Text("Modèles")) {
                    NavigationLink {
                        ModelManagerView()
                            .environmentObject(modelViewModel)
                    } label: {
                        Text("Gestion des modèles")
                    }
                    
                    Toggle("Chargement automatique", isOn: $appState.settings.autoLoadModels)
                }
                
                Section {
                    Button(action: {
                        modelViewModel.unloadAllModels()
                    }) {
                        Text("Déconnecter tous les modèles")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Paramètres")
        }
    }
}

// Vue pour gérer les outils MCP
struct MCPToolsView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var tools: [MCPToolProtocol] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("Outils intégrés") {
                    ForEach(tools) { tool in
                        MCPToolRow(tool: tool)
                    }
                }
            }
            .navigationTitle("Outils MCP")
            .onAppear {
                tools = MCPClient.shared.listTools()
            }
        }
    }
}

struct MCPToolRow: View {
    let tool: MCPToolProtocol
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench")
                .font(.system(size: 16))
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

// Vue pour afficher les informations sur les modèles
struct ModelInfoView: View {
    let model: LLModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations")) {
                    InfoRow(icon: "info.circle", label: "Nom", value: model.name)
                    InfoRow(icon: "person", label: "Auteur", value: model.author)
                    InfoRow(icon: "doc.text", label: "Description", value: model.description)
                }
                
                Section(header: Text("Spécifications")) {
                    InfoRow(icon: "number", label: "Paramètres", value: model.formattedParameters)
                    InfoRow(icon: "memorychip", label: "Taille", value: model.formattedSize)
                    InfoRow(icon: "tag", label: "Catégorie", value: model.category)
                }
                
                Section(header: Text("Compatibilité")) {
                    ForEach(model.supportedDevices, id: \.self) { device in
                        Text(device)
                    }
                }
            }
            .navigationTitle(model.name)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.body)
            
            Spacer()
        }
    }
}
