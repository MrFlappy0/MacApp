import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var searchText: String = ""
    @State private var showModelDetail: Bool = false
    @State private var selectedModel: LLModel?
    @State private var showDownloadConfirmation: Bool = false
    @State private var modelToDownload: LLModel?
    
    var filteredModels: [LLModel] {
        if searchText.isEmpty {
            return appSettings.models
        } else {
            return appSettings.models.filter { model in
                model.name.lowercased().contains(searchText.lowercased()) ||
                model.description.lowercased().contains(searchText.lowercased()) ||
                model.author.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                searchBar
                
                // Liste des modèles
                modelsList
            }
            .navigationTitle("Gestion des Modèles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    refreshButton
                }
            }
            .sheet(item: $selectedModel) { model in
                ModelDetailView(model: model)
                    .environmentObject(appSettings)
            }
            .sheet(item: $modelToDownload) { model in
                DownloadConfirmationView(model: model)
                    .environmentObject(appSettings)
            }
        }
    }
    
    private var searchBar: some View {
        SearchBar(text: $searchText, placeholder: "Rechercher un modèle...")
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
    
    private var modelsList: some View {
        List {
            // Section des modèles téléchargés
            if !appSettings.downloadedModels.isEmpty {
                Section(header: Text("Téléchargés")) {
                    ForEach(appSettings.downloadedModels) { model in
                        ModelRowView(model: model, isDownloaded: true)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive, action: {
                                    appSettings.deleteModel(model)
                                }) {
                                    Label("Supprimer", systemImage: "trash")
                                }
                                
                                Button(action: {
                                    appSettings.loadModel(model)
                                }) {
                                    Label("Charger", systemImage: "arrow.up.circle")
                                }
                                .tint(.blue)
                            }
                            .onTapGesture {
                                selectedModel = model
                            }
                    }
                }
            }
            
            // Section de tous les modèles
            Section(header: Text("Disponibles")) {
                ForEach(filteredModels.filter { !appSettings.downloadedModels.contains(where: { $0.id == $1.id }) }) { model in
                    ModelRowView(model: model, isDownloaded: false)
                        .swipeActions(edge: .trailing) {
                            Button(action: {
                                modelToDownload = model
                            }) {
                                Label("Télécharger", systemImage: "arrow.down.circle")
                            }
                            .tint(.blue)
                        }
                        .onTapGesture {
                            selectedModel = model
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var refreshButton: some View {
        Button(action: {
            // Rafraîchir la liste des modèles
            appSettings.load2026Models()
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .help("Rafraîchir la liste")
    }
}

// MARK: - Subviews

struct ModelRowView: View {
    let model: LLModel
    let isDownloaded: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône
            Image(systemName: isDownloaded ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(isDownloaded ? .green : .secondary)
                .frame(width: 24, height: 24)
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Métriques
            VStack(alignment: .trailing, spacing: 4) {
                Text(model.formattedParameters)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(model.formattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct ModelDetailView: View {
    let model: LLModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations")) {
                    InfoRow(icon: "info.circle", label: "Nom", value: model.name)
                    InfoRow(icon: "person", label: "Auteur", value: model.author)
                    InfoRow(icon: "doc.text", label: "Description", value: model.description)
                    InfoRow(icon: "tag", label: "Catégorie", value: model.category)
                }
                
                Section(header: Text("Spécifications")) {
                    InfoRow(icon: "number", label: "Paramètres", value: model.formattedParameters)
                    InfoRow(icon: "memorychip", label: "Taille", value: model.formattedSize)
                    InfoRow(icon: "cpu", label: "Framework", value: "\(model.framework) \(model.frameworkVersion)")
                }
                
                Section(header: Text("Compatibilité")) {
                    ForEach(model.supportedDevices, id: \.self) { device in
                        HStack {
                            Image(systemName: deviceIcon(for: device))
                                .foregroundColor(.blue)
                            Text(device)
                        }
                    }
                }
                
                Section {
                    if model.isDownloaded {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                appSettings.loadModel(model)
                                dismiss()
                            }) {
                                Text("Charger le modèle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Spacer()
                            
                            Button(action: {
                                appSettings.deleteModel(model)
                                dismiss()
                            }, role: .destructive) {
                                Text("Supprimer")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    } else {
                        Button(action: {
                            appSettings.downloadModel(model)
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Télécharger le modèle")
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(model.name)
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
    
    private func deviceIcon(for device: String) -> String {
        switch device.lowercased() {
        case "mps": return "applelogo"
        case "gpu": return "gpu"
        case "cpu": return "cpu"
        default: return "questionmark"
        }
    }
}

struct DownloadConfirmationView: View {
    let model: LLModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\dismiss) var dismiss
    
    @State private var isDownloading: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text(model.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Taille: \(model.formattedSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if isDownloading {
                    VStack(spacing: 12) {
                        ProgressView(value: appSettings.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .scaleEffect(1.5, anchor: .center)
                        
                        Text(String(format: "%.0f%%", appSettings.downloadProgress * 100))
                            .font(.headline)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Télécharger ce modèle ?")
                            .font(.headline)
                        
                        Text("Ce modèle nécessite \(model.formattedSize) d'espace disque.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Téléchargement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if !isDownloading {
                        Button("Télécharger") {
                            isDownloading = true
                            appSettings.downloadModel(model)
                            dismiss()
                        }
                        .disabled(isDownloading)
                    }
                }
            }
            .onAppear {
                isDownloading = appSettings.isDownloadingModel
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            
            TextField(placeholder, text: $text)
                .font(.body)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
    ModelsView()
        .environmentObject(AppSettings.shared)
}
