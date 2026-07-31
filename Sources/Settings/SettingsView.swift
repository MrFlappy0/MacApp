import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Apparence
                appearanceSection
                
                // MARK: - Modèle et Inférence
                modelSection
                
                // MARK: - Performances
                performanceSection
                
                // MARK: - MCP
                mcpSection
                
                // MARK: - Chat
                chatSection
                
                // MARK: - Fichiers
                filesSection
                
                // MARK: - À propos
                aboutSection
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Sections
    
    private var appearanceSection: some View {
        Section(header: Text("Apparence")) {
            Picker("Thème", selection: $appSettings.theme) {
                ForEach(AppSettings.Theme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            
            Toggle("Utiliser le thème du système", isOn: Binding(
                get: { appSettings.theme == .system },
                set: { if $0 { appSettings.theme = .system } }
            ))
            .disabled(appSettings.theme == .system)
        }
    }
    
    private var modelSection: some View {
        Section(header: Text("Modèle et Inférence")) {
            // Sélection du modèle
            Picker("Modèle actuel", selection: $appSettings.loadedModel) {
                Text("Aucun").tag(nil as LLModel?)
                
                ForEach(appSettings.downloadedModels) { model in
                    Text(model.name).tag(model as LLModel?)
                }
            }
            
            if appSettings.loadedModel == nil && !appSettings.downloadedModels.isEmpty {
                Text("Aucun modèle chargé. Sélectionnez un modèle téléchargé.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Configuration du modèle
            NavigationLink {
                ModelConfigView()
                    .environmentObject(appSettings)
            } label: {
                Text("Configuration du modèle")
            }
            
            // Gestion des modèles
            NavigationLink {
                ModelsView()
                    .environmentObject(appSettings)
            } label: {
                Text("Gestion des modèles")
            }
        }
    }
    
    private var performanceSection: some View {
        Section(header: Text("Performances")) {
            Toggle("Accélération Metal (MPS)", isOn: $appSettings.useMetalAcceleration)
                .help("Utiliser Metal Performance Shaders pour une inférence plus rapide")
            
            Picker("Périphérique", selection: $appSettings.preferredDevice) {
                ForEach(AppSettings.Device.allCases, id: \.self) { device in
                    Text(device.rawValue).tag(device)
                }
            }
            .help("Périphérique à utiliser pour l'inférence")
            
            Picker("Précision", selection: $appSettings.precision) {
                ForEach(AppSettings.Precision.allCases, id: \.self) { precision in
                    Text(precision.rawValue).tag(precision)
                }
            }
            .help("Précision des calculs (Float32 = haute qualité, Int8 = économique)")
            
            Stepper("Taille du batch: \(appSettings.batchSize)", value: $appSettings.batchSize, in: 1...16)
                .help("Nombre d'inputs traités simultanément")
            
            Slider(
                value: Binding(
                    get: { Double(appSettings.maxMemoryUsage) },
                    set: { appSettings.maxMemoryUsage = Int($0) }
                ),
                in: 10...100,
                step: 5
            ) {
                Text("Mémoire max: \(appSettings.maxMemoryUsage)%")
            }
            .help("Pourcentage maximum de mémoire à utiliser")
        }
    }
    
    private var mcpSection: some View {
        Section(header: Text("MCP (Model Context Protocol)")) {
            Toggle("Activer MCP", isOn: $appSettings.mcpEnabled)
                .help("Permettre à l'IA d'utiliser des outils externes")
            
            if appSettings.mcpEnabled {
                NavigationLink {
                    MCPView()
                        .environmentObject(appSettings)
                } label: {
                    Text("Configurer les outils MCP")
                }
                
                Text("\(appSettings.enabledTools.count) outils activés")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var chatSection: some View {
        Section(header: Text("Chat")) {
            TextEditor(text: $appSettings.systemPrompt)
                .frame(minHeight: 100)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .help("Message système envoyé au modèle pour définir son comportement")
            
            Button("Réinitialiser le message système") {
                appSettings.systemPrompt = "Tu es un assistant IA utile, précis et sûr. Réponds de manière claire et concise."
            }
            .help("Réinitialiser au message par défaut")
        }
    }
    
    private var filesSection: some View {
        Section(header: Text("Fichiers")) {
            NavigationLink {
                FilesView()
                    .environmentObject(appSettings)
            } label: {
                Text("Gestion des fichiers")
            }
            
            Text("\(appSettings.recentFiles.count) fichiers récents")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("À propos")) {
            InfoRow(icon: "app", label: "Nom", value: appSettings.appName)
            InfoRow(icon: "number", label: "Version", value: appSettings.appVersion)
            
            Link("Visiter le dépôt GitHub", destination: URL(string: "https://github.com/MrFlappy0/MacApp")!)
            
            Text("Une application IA puissante pour macOS, optimisée pour Apple Silicon.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Vue de configuration du modèle

struct ModelConfigView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Paramètres de génération")) {
                    // Température
                    SliderSetting(
                        value: $appSettings.currentModelConfig.temperature,
                        range: 0...2,
                        step: 0.1,
                        label: "Température",
                        description: "Contrôle la créativité. Plus c'est élevé, plus les réponses sont variées."
                    )
                    
                    // Top P
                    SliderSetting(
                        value: $appSettings.currentModelConfig.topP,
                        range: 0...1,
                        step: 0.05,
                        label: "Top P",
                        description: "Probabilité cumulative pour l'échantillonnage."
                    )
                    
                    // Top K
                    SliderSetting(
                        value: Binding(
                            get: { Double(appSettings.currentModelConfig.topK) },
                            set: { appSettings.currentModelConfig.topK = Int($0) }
                        ),
                        range: 1...100,
                        step: 1,
                        label: "Top K",
                        description: "Nombre de tokens à considérer pour l'échantillonnage."
                    )
                }
                
                Section(header: Text("Limites")) {
                    StepperSetting(
                        value: $appSettings.currentModelConfig.maxTokens,
                        range: 16...4096,
                        step: 16,
                        label: "Tokens maximum",
                        description: "Nombre maximum de tokens à générer."
                    )
                }
                
                Section(header: Text("Pénalités")) {
                    // Presence Penalty
                    SliderSetting(
                        value: $appSettings.currentModelConfig.presencePenalty,
                        range: -2...2,
                        step: 0.1,
                        label: "Pénalité de présence",
                        description: "Pénalise les nouveaux sujets."
                    )
                    
                    // Frequency Penalty
                    SliderSetting(
                        value: $appSettings.currentModelConfig.frequencyPenalty,
                        range: -2...2,
                        step: 0.1,
                        label: "Pénalité de fréquence",
                        description: "Pénalise les répétitions."
                    )
                    
                    // Repetition Penalty
                    SliderSetting(
                        value: $appSettings.currentModelConfig.repetitionPenalty,
                        range: 0.1...2,
                        step: 0.1,
                        label: "Pénalité de répétition",
                        description: "Pénalise les répétitions exactes."
                    )
                }
                
                Section(header: Text("Options avancées")) {
                    Toggle("Utiliser la recherche par faisceau", isOn: $appSettings.currentModelConfig.useBeamSearch)
                    
                    if appSettings.currentModelConfig.useBeamSearch {
                        Stepper("Largeur du faisceau: \(appSettings.currentModelConfig.beamWidth)", value: $appSettings.currentModelConfig.beamWidth, in: 2...10)
                    }
                    
                    Toggle("Arrêt précoce", isOn: $appSettings.currentModelConfig.earlyStopping)
                }
                
                Section {
                    HStack {
                        Spacer()
                        
                        Button("Réinitialiser aux valeurs par défaut") {
                            appSettings.currentModelConfig = ModelConfig()
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Configuration du Modèle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Composants réutilisables

struct SliderSetting: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 50)
            }
            
            Slider(value: $value, in: range, step: step)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StepperSetting: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let label: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 50)
            }
            
            Stepper("", value: $value, in: range, step: step)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
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

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
