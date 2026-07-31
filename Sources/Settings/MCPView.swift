import SwiftUI

struct MCPView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var searchText: String = ""
    @State private var showServerSheet: Bool = false
    @State private var showToolDetail: Bool = false
    @State private var selectedTool: MCPTool?
    
    var filteredTools: [MCPTool] {
        if searchText.isEmpty {
            return appSettings.availableTools
        } else {
            return appSettings.availableTools.filter { tool in
                tool.name.lowercased().contains(searchText.lowercased()) ||
                tool.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // En-tête
                headerSection
                
                // Barre de recherche
                searchBar
                
                // Liste des outils
                toolsList
            }
            .navigationTitle("Outils MCP")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addServerButton
                }
            }
            .sheet(isPresented: $showServerSheet) {
                AddServerView()
                    .environmentObject(appSettings)
            }
            .sheet(item: $selectedTool) { tool in
                ToolDetailView(tool: tool)
                    .environmentObject(appSettings)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Activer MCP", isOn: $appSettings.mcpEnabled)
                .toggleStyle(.switch)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            if appSettings.mcpEnabled {
                Text("MCP (Model Context Protocol) permet à l'IA d'utiliser des outils externes pour effectuer des tâches comme la recherche web, l'accès aux fichiers, et plus encore.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var searchBar: some View {
        SearchBar(text: $searchText, placeholder: "Rechercher un outil...")
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
    
    private var toolsList: some View {
        List {
            // Section des outils activés
            if appSettings.mcpEnabled {
                Section(header: Text("Outils activés")) {
                    ForEach(filteredTools.filter { appSettings.isToolEnabled($0.name) }) { tool in
                        ToolRowView(tool: tool, isEnabled: true)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive, action: {
                                    appSettings.toggleTool(tool.name, enabled: false)
                                }) {
                                    Label("Désactiver", systemImage: "xmark.circle")
                                }
                            }
                            .onTapGesture {
                                selectedTool = tool
                            }
                    }
                }
                
                // Section de tous les outils
                Section(header: Text("Outils disponibles")) {
                    ForEach(filteredTools.filter { !appSettings.isToolEnabled($0.name) }) { tool in
                        ToolRowView(tool: tool, isEnabled: false)
                            .swipeActions(edge: .trailing) {
                                Button(action: {
                                    appSettings.toggleTool(tool.name, enabled: true)
                                }) {
                                    Label("Activer", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                            .onTapGesture {
                                selectedTool = tool
                            }
                    }
                }
            } else {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("MCP est désactivé")
                            .font(.headline)
                        
                        Text("Activez MCP dans les paramètres pour utiliser les outils.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var addServerButton: some View {
        Button(action: {
            showServerSheet = true
        }) {
            Image(systemName: "plus")
        }
        .help("Ajouter un serveur MCP")
    }
}

// MARK: - Subviews

struct ToolRowView: View {
    let tool: MCPTool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône
            Image(systemName: toolIcon(for: tool.category))
                .font(.system(size: 16))
                .foregroundColor(isEnabled ? .green : .secondary)
                .frame(width: 24, height: 24)
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // État
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(isEnabled ? .green : .secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func toolIcon(for category: String) -> String {
        switch category.lowercased() {
        case "web": return "globe"
        case "file": return "folder"
        case "system": return "gear"
        case "code": return "curlybraces"
        case "data": return "chart.bar"
        case "calculator": return "plus.forwardslash.minus"
        default: return "wrench"
        }
    }
}

struct ToolDetailView: View {
    let tool: MCPTool
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations")) {
                    InfoRow(icon: "info.circle", label: "Nom", value: tool.name)
                    InfoRow(icon: "doc.text", label: "Description", value: tool.description)
                    InfoRow(icon: "tag", label: "Catégorie", value: tool.category)
                }
                
                Section(header: Text("Paramètres")) {
                    if tool.parameters.isEmpty {
                        Text("Aucun paramètre requis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(tool.parameters, id: \.name) { param in
                            ParameterRow(param: param)
                        }
                    }
                }
                
                Section {
                    Toggle("Activé", isOn: Binding(
                        get: { appSettings.isToolEnabled(tool.name) },
                        set: { appSettings.toggleTool(tool.name, enabled: $0) }
                    ))
                }
            }
            .navigationTitle(tool.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ParameterRow: View {
    let param: MCPTool.MCPParameter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(param.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(param.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(param.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let defaultValue = param.defaultValue {
                    Text("Défaut: \(defaultValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AddServerView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\dismiss) var dismiss
    
    @State private var serverName: String = ""
    @State private var serverURL: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    
    var formIsValid: Bool {
        !serverName.isEmpty && !serverURL.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations du serveur")) {
                    TextField("Nom du serveur", text: $serverName)
                    TextField("URL du serveur", text: $serverURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    if let result = testResult {
                        Text(result)
                            .foregroundColor(isTesting ? .blue : (result.contains("succès") ? .green : .red))
                    }
                }
            }
            .navigationTitle("Ajouter un serveur MCP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let server = MCPServerConfig(
                            name: serverName,
                            url: serverURL
                        )
                        appSettings.addMCPServer(server)
                        dismiss()
                    }
                    .disabled(!formIsValid)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MCPView()
        .environmentObject(AppSettings.shared)
}
