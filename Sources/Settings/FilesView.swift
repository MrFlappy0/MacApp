import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var showFileImporter: Bool = false
    @State private var showFileDetail: Bool = false
    @State private var selectedFile: FileItem?
    @State private var showDeleteConfirmation: Bool = false
    @State private var fileToDelete: FileItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre d'outils
                toolbarSection
                
                // Liste des fichiers
                filesList
            }
            .navigationTitle("Gestion des Fichiers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addFileButton
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [
                    .text, .pdf, .image, .audio, .video, 
                    .folder, .plainText, .markdown, .json, .csv
                ],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result: result)
            }
            .sheet(item: $selectedFile) { file in
                FileDetailView(file: file)
                    .environmentObject(appSettings)
            }
            .alert("Supprimer le fichier", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    if let file = fileToDelete {
                        appSettings.removeRecentFile(file)
                        try? FileManager.default.removeItem(at: file.url)
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer ce fichier ?")
            }
        }
    }
    
    private var toolbarSection: some View {
        HStack {
            Text("Fichiers récents")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                // Rafraîchir la liste
                appSettings.loadRecentFiles()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Rafraîchir")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var filesList: some View {
        List {
            if appSettings.recentFiles.isEmpty {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Aucun fichier récent")
                            .font(.headline)
                        
                        Text("Importez des fichiers pour commencer à les gérer.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            } else {
                Section {
                    ForEach(appSettings.recentFiles) { file in
                        FileRowView(file: file)
                            .swipeActions(edge: .trailing) {
                                Button(action: {
                                    fileToDelete = file
                                    showDeleteConfirmation = true
                                }, role: .destructive) {
                                    Label("Supprimer", systemImage: "trash")
                                }
                                
                                Button(action: {
                                    NSWorkspace.shared.open(file.url)
                                }) {
                                    Label("Ouvrir", systemImage: "folder")
                                }
                                .tint(.blue)
                            }
                            .onTapGesture {
                                selectedFile = file
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var addFileButton: some View {
        Button(action: {
            showFileImporter = true
        }) {
            Image(systemName: "plus")
        }
        .help("Importer un fichier")
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                appSettings.addRecentFile(url)
            }
            
        case .failure(let error):
            appSettings.modelDownloadError = error
        }
    }
}

// MARK: - Subviews

struct FileRowView: View {
    let file: FileItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône
            Image(systemName: fileIcon(for: file.fileType))
                .font(.system(size: 16))
                .foregroundColor(fileColor(for: file.fileType))
                .frame(width: 24, height: 24)
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(file.fileType.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Date
            Text(file.modificationDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func fileIcon(for fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf": return "doc.text.magnifyingglass"
        case "txt", "md": return "doc.text"
        case "csv": return "tablecells"
        case "json": return "curlybraces"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo"
        case "mp3", "wav", "aac": return "waveform"
        case "mp4", "mov", "avi": return "video"
        case "zip", "tar", "gz": return "folder"
        case "py": return "{}"
        case "swift": return "swift"
        default: return "doc"
        }
    }
    
    private func fileColor(for fileType: String) -> Color {
        switch fileType.lowercased() {
        case "pdf": return .red
        case "txt", "md": return .blue
        case "csv": return .green
        case "json": return .yellow
        case "jpg", "jpeg", "png", "gif", "heic": return .purple
        case "mp3", "wav", "aac": return .orange
        case "mp4", "mov", "avi": return .pink
        case "zip", "tar", "gz": return .brown
        case "py": return .green
        case "swift": return .orange
        default: return .gray
        }
    }
}

struct FileDetailView: View {
    let file: FileItem
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\dismiss) var dismiss
    
    @State private var fileContent: String?
    @State private var isLoading: Bool = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        NSWorkspace.shared.open(file.url)
                    }) {
                        Image(systemName: "folder")
                    }
                    .help("Ouvrir le fichier")
                }
            }
            .onAppear {
                loadFileContent()
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            Text("Chargement du fichier...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Informations du fichier
                fileInfoSection
                
                // Contenu du fichier (si texte)
                if let content = fileContent, !content.isEmpty {
                    fileContentSection
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var fileInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informations")
                .font(.headline)
            
            InfoRow(icon: "doc.text", label: "Nom", value: file.name)
            InfoRow(icon: "tag", label: "Type", value: file.fileType.uppercased())
            InfoRow(icon: "memorychip", label: "Taille", value: file.formattedSize)
            InfoRow(icon: "clock", label: "Modifié", value: file.modificationDate.formatted())
            
            Divider()
        }
    }
    
    private var fileContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contenu")
                .font(.headline)
            
            Text(fileContent ?? "")
                .font(.body)
                .textSelection(.enabled)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Erreur")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadFileContent() {
        isLoading = true
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Vérifier si c'est un fichier texte
                let textExtensions = ["txt", "md", "csv", "json", "xml", "html", "css", "js", "py", "swift"]
                
                if textExtensions.contains(file.fileType.lowercased()) {
                    let content = try String(contentsOf: file.url, encoding: .utf8)
                    
                    // Limiter la taille pour l'affichage
                    let maxLength = 10000
                    let contentToDisplay: String
                    if content.count > maxLength {
                        contentToDisplay = String(content.prefix(maxLength)) + "\n\n... (fichier tronqué)"
                    } else {
                        contentToDisplay = content
                    }
                    
                    DispatchQueue.main.async {
                        fileContent = contentToDisplay
                        isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        fileContent = "Ce type de fichier ne peut pas être affiché directement."
                        isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    self.error = error
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FilesView()
        .environmentObject(AppSettings.shared)
}
