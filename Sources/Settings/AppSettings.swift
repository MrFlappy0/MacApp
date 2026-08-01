import Foundation
import SwiftUI
import Combine

/// Classe principale pour TOUTES les configurations de l'application
/// Centralise : modèles, MCP, paramètres généraux, etc.
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // MARK: - Onglet actuel
    @Published var currentTab: Tab = .chat
    
    enum Tab {
        case chat, models, mcp, files, settings
    }
    
    // MARK: - Apparence
    @Published var colorScheme: ColorScheme? = nil
    @Published var theme: Theme = .system
    
    enum Theme: String, CaseIterable {
        case system = "Système"
        case light = "Clair"
        case dark = "Sombre"
    }
    
    var effectiveColorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    // MARK: - Paramètres généraux
    @Published var appName: String = "MLX for All"
    @Published var appVersion: String = "2.0.0"
    @Published var autoCheckForUpdates: Bool = true
    
    // MARK: - Paramètres de performance
    @Published var useMetalAcceleration: Bool = true
    @Published var preferredDevice: Device = .auto
    @Published var precision: Precision = .float16
    @Published var batchSize: Int = 1
    @Published var maxMemoryUsage: Int = 80 // Pourcentage
    
    enum Device: String, CaseIterable {
        case auto = "Auto"
        case cpu = "CPU"
        case gpu = "GPU"
        case mps = "MPS (Metal)"
    }
    
    enum Precision: String, CaseIterable {
        case float32 = "Float 32"
        case float16 = "Float 16"
        case int8 = "Int 8"
    }
    
    // MARK: - Gestion des modèles (CENTRALISÉ ICI)
    @Published var models: [LLModel] = []
    @Published var downloadedModels: [LLModel] = []
    @Published var loadedModel: LLModel?
    @Published var isDownloadingModel: Bool = false
    @Published var downloadProgress: Double = 0
    @Published var modelDownloadError: Error?
    
    // MARK: - Configuration du modèle actuel
    @Published var currentModelConfig = ModelConfig()
    
    // MARK: - Gestion MCP (CENTRALISÉ ICI)
    @Published var mcpEnabled: Bool = true
    @Published var availableTools: [MCPTool] = []
    @Published var enabledTools: Set<String> = []
    @Published var mcpServers: [MCPServerConfig] = []
    
    // MARK: - Gestion des fichiers
    @Published var recentFiles: [FileItem] = []
    @Published var fileStoragePath: URL
    
    // MARK: - Paramètres de chat
    @Published var chatHistory: [ChatSession] = []
    @Published var currentChat: ChatSession?
    @Published var systemPrompt: String = "Tu es un assistant IA utile, précis et sûr. Réponds de manière claire et concise."
    
    // MARK: - Initialisation
    private init() {
        // Initialiser le chemin de stockage
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileStoragePath = documentsURL.appendingPathComponent("MLXForAll", isDirectory: true)
        
        // Créer le répertoire si nécessaire
        createStorageDirectory()
        
        // Charger les modèles 2026
        load2026Models()
        
        // Charger les outils MCP
        loadMCPTools()
        
        // Charger l'historique de chat
        loadChatHistory()
        
        // Charger les fichiers récents
        loadRecentFiles()
    }
    
    // MARK: - Méthodes privées
    
    private func createStorageDirectory() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: fileStoragePath.path) {
            try? fileManager.createDirectory(at: fileStoragePath, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Méthodes publiques
    
    func load2026Models() {
        // Modèles MLX 2026 - Dernières versions
        models = [
            // Modèles Mistral 2026
            LLModel(
                id: "mistral-large-2026",
                name: "Mistral Large 2026",
                description: "Modèle phare de Mistral AI avec 123B paramètres, optimisé pour le raisonnement complexe",
                author: "Mistral AI",
                category: "text-generation",
                parameters: 123_000_000_000,
                fileSize: 240_000_000_000,
                huggingFaceId: "mistralai/Mistral-Large-2026",
                supportedDevices: ["mps"],
                license: "Apache 2.0",
                tags: ["text-generation", "reasoning", "advanced"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            LLModel(
                id: "mistral-small-2026",
                name: "Mistral Small 2026",
                description: "Modèle léger et rapide avec 22B paramètres, parfait pour les tâches quotidiennes",
                author: "Mistral AI",
                category: "text-generation",
                parameters: 22_000_000_000,
                fileSize: 42_000_000_000,
                huggingFaceId: "mistralai/Mistral-Small-2026",
                supportedDevices: ["mps", "cpu"],
                license: "Apache 2.0",
                tags: ["text-generation", "fast", "efficient"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            // Modèles Apple M5 (2026)
            LLModel(
                id: "apple-m5-llm",
                name: "Apple M5 LLM",
                description: "Modèle optimisé pour Apple Silicon M5, intégration native avec Metal",
                author: "Apple",
                category: "text-generation",
                parameters: 40_000_000_000,
                fileSize: 75_000_000_000,
                huggingFaceId: "apple/M5-LLM",
                supportedDevices: ["mps"],
                license: "Apple",
                tags: ["text-generation", "apple-silicon", "optimized"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            LLModel(
                id: "apple-m5-vision",
                name: "Apple M5 Vision",
                description: "Modèle multimodal pour la vision par ordinateur, optimisé pour M5",
                author: "Apple",
                category: "multimodal",
                parameters: 22_000_000_000,
                fileSize: 40_000_000_000,
                huggingFaceId: "apple/M5-Vision",
                supportedDevices: ["mps"],
                license: "Apple",
                tags: ["vision", "multimodal", "apple-silicon"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            // Modèles MLX 2026
            LLModel(
                id: "mlx-hermes-2",
                name: "MLX Hermes 2",
                description: "Modèle open-source optimisé pour MLX 2.0, excellent pour le chat",
                author: "NousResearch",
                category: "text-generation",
                parameters: 30_000_000_000,
                fileSize: 60_000_000_000,
                huggingFaceId: "NousResearch/Hermes-2-Mistral-7B",
                supportedDevices: ["mps", "cpu"],
                license: "Apache 2.0",
                tags: ["text-generation", "chat", "mlx-optimized"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            LLModel(
                id: "mlx-phi-3",
                name: "MLX Phi-3",
                description: "Phi-3 optimisé pour MLX, très efficace en mémoire",
                author: "Microsoft",
                category: "text-generation",
                parameters: 14_000_000_000,
                fileSize: 25_000_000_000,
                huggingFaceId: "microsoft/phi-3-mini-128k-instruct",
                supportedDevices: ["mps", "cpu"],
                license: "MIT",
                tags: ["text-generation", "efficient", "mlx-optimized"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            // Modèles légers pour les Mac avec moins de RAM
            LLModel(
                id: "tiny-llama-1.1b",
                name: "Tiny Llama 1.1B",
                description: "Modèle ultra-léger pour les Mac avec 8 Go de RAM",
                author: "Community",
                category: "text-generation",
                parameters: 1_100_000_000,
                fileSize: 2_000_000_000,
                huggingFaceId: "TinyLlama/TinyLlama-1.1B-intermediate-step-1430k-3T",
                supportedDevices: ["mps", "cpu"],
                license: "Apache 2.0",
                tags: ["text-generation", "lightweight", "low-ram"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            ),
            
            LLModel(
                id: "gemma-2-2b",
                name: "Gemma 2 2B",
                description: "Modèle léger de Google, optimisé pour l'inférence rapide",
                author: "Google",
                category: "text-generation",
                parameters: 2_000_000_000,
                fileSize: 3_500_000_000,
                huggingFaceId: "google/gemma-2-2b-it",
                supportedDevices: ["mps", "cpu"],
                license: "Apache 2.0",
                tags: ["text-generation", "fast", "lightweight"],
                isDownloaded: false,
                localPath: nil,
                framework: "mlx",
                frameworkVersion: "2.0.0"
            )
        ]
    }
    
    func loadMCPTools() {
        // Charger tous les outils MCP disponibles
        availableTools = MCPToolRegistry.shared.listAllTools()
        enabledTools = Set(availableTools.map { $0.name })
    }
    
    func loadChatHistory() {
        // Charger l'historique de chat depuis le stockage
        let storage = ChatStorage()
        do {
            chatHistory = try storage.loadSessions()
            currentChat = chatHistory.first
        } catch {
            print("Failed to load chat history: \(error)")
        }
    }
    
    func loadRecentFiles() {
        // Charger les fichiers récents
        let fileManager = FileManager.default
        let filesURL = fileStoragePath.appendingPathComponent("Files", isDirectory: true)
        
        do {
            if fileManager.fileExists(atPath: filesURL.path) {
                let contents = try fileManager.contentsOfDirectory(at: filesURL, includingPropertiesForKeys: nil)
                recentFiles = contents.map { url in
                    FileItem(url: url)
                }.sorted { $0.modificationDate > $1.modificationDate }
            }
        } catch {
            print("Failed to load recent files: \(error)")
        }
    }
    
    // MARK: - Méthodes publiques pour la gestion des modèles
    
    func downloadModel(_ model: LLModel) {
        guard !model.isDownloaded else {
            modelDownloadError = AppError.modelAlreadyDownloaded
            return
        }
        
        isDownloadingModel = true
        downloadProgress = 0
        modelDownloadError = nil
        
        let destinationURL = fileStoragePath
            .appendingPathComponent("Models", isDirectory: true)
            .appendingPathComponent(model.id, isDirectory: true)
        
        HuggingFaceClient.shared.downloadModel(
            modelId: model.huggingFaceId,
            destinationURL: destinationURL
        ) { [weak self] progress in
            DispatchQueue.main.async {
                self?.downloadProgress = progress
            }
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.isDownloadingModel = false
                
                switch result {
                case .success:
                    var updatedModel = model
                    updatedModel.isDownloaded = true
                    updatedModel.localPath = destinationURL.path
                    
                    if let index = self?.models.firstIndex(where: { $0.id == model.id }) {
                        self?.models[index] = updatedModel
                    }
                    
                    self?.downloadedModels.append(updatedModel)
                    self?.loadedModel = updatedModel
                    
                case .failure(let error):
                    self?.modelDownloadError = error
                }
            }
        }
    }
    
    func loadModel(_ model: LLModel) {
        guard model.isDownloaded, let localPath = model.localPath else {
            modelDownloadError = AppError.modelNotDownloaded
            return
        }
        
        MLXIntegration.shared.loadModel(from: localPath) { [weak self] result in
            switch result {
            case .success:
                self?.loadedModel = model
                self?.modelDownloadError = nil
            case .failure(let error):
                self?.modelDownloadError = error
            }
        }
    }
    
    func unloadModel() {
        if let model = loadedModel {
            MLXIntegration.shared.unloadModel(model.id)
            loadedModel = nil
        }
    }
    
    func deleteModel(_ model: LLModel) {
        guard model.isDownloaded, let localPath = model.localPath else { return }
        
        do {
            let modelURL = URL(fileURLWithPath: localPath)
            try FileManager.default.removeItem(at: modelURL)
            
            // Mettre à jour les listes
            if let index = downloadedModels.firstIndex(where: { $0.id == model.id }) {
                downloadedModels.remove(at: index)
            }
            
            if let index = models.firstIndex(where: { $0.id == model.id }) {
                var updatedModel = models[index]
                updatedModel.isDownloaded = false
                updatedModel.localPath = nil
                models[index] = updatedModel
            }
            
            if loadedModel?.id == model.id {
                loadedModel = nil
            }
        } catch {
            modelDownloadError = error
        }
    }
    
    // MARK: - Méthodes publiques pour MCP
    
    func toggleTool(_ toolName: String, enabled: Bool) {
        if enabled {
            enabledTools.insert(toolName)
        } else {
            enabledTools.remove(toolName)
        }
    }
    
    func isToolEnabled(_ toolName: String) -> Bool {
        enabledTools.contains(toolName)
    }
    
    func addMCPServer(_ server: MCPServerConfig) {
        mcpServers.append(server)
    }
    
    func removeMCPServer(_ server: MCPServerConfig) {
        mcpServers.removeAll { $0.id == server.id }
    }
    
    // MARK: - Méthodes publiques pour le chat
    
    func createNewChat() {
        let newChat = ChatSession(
            id: UUID(),
            name: "Nouvelle conversation",
            model: loadedModel,
            modelConfig: currentModelConfig
        )
        chatHistory.insert(newChat, at: 0)
        currentChat = newChat
    }
    
    func switchToChat(_ chat: ChatSession) {
        currentChat = chat
    }
    
    func deleteChat(_ chat: ChatSession) {
        guard let index = chatHistory.firstIndex(where: { $0.id == chat.id }) else { return }
        
        chatHistory.remove(at: index)
        
        if currentChat?.id == chat.id {
            currentChat = chatHistory.first
        }
    }
    
    // MARK: - Méthodes publiques pour les fichiers
    
    func addRecentFile(_ url: URL) {
        let fileItem = FileItem(url: url)
        
        // Supprimer les doublons
        recentFiles.removeAll { $0.url == url }
        
        // Ajouter le nouveau fichier
        recentFiles.insert(fileItem, at: 0)
        
        // Garder seulement les 20 derniers fichiers
        if recentFiles.count > 20 {
            recentFiles.removeLast()
        }
    }
    
    func removeRecentFile(_ fileItem: FileItem) {
        recentFiles.removeAll { $0.url == fileItem.url }
    }
    
    // MARK: - Sauvegarde et chargement
    
    func saveSettings() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(self)
            let settingsURL = fileStoragePath.appendingPathComponent("settings.json")
            try data.write(to: settingsURL)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func loadSettings() {
        let settingsURL = fileStoragePath.appendingPathComponent("settings.json")
        
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: settingsURL)
            let decoder = JSONDecoder()
            let settings = try decoder.decode(AppSettings.self, from: data)
            
            // Copier les propriétés
            self.theme = settings.theme
            self.useMetalAcceleration = settings.useMetalAcceleration
            self.preferredDevice = settings.preferredDevice
            self.precision = settings.precision
            self.batchSize = settings.batchSize
            self.mcpEnabled = settings.mcpEnabled
            self.enabledTools = settings.enabledTools
            self.mcpServers = settings.mcpServers
            self.systemPrompt = settings.systemPrompt
            self.currentModelConfig = settings.currentModelConfig
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
}

// MARK: - Extensions pour la compatibilité Codable

extension AppSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case theme, useMetalAcceleration, preferredDevice, precision, batchSize
        case mcpEnabled, enabledTools, mcpServers
        case systemPrompt, currentModelConfig
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(theme, forKey: .theme)
        try container.encode(useMetalAcceleration, forKey: .useMetalAcceleration)
        try container.encode(preferredDevice, forKey: .preferredDevice)
        try container.encode(precision, forKey: .precision)
        try container.encode(batchSize, forKey: .batchSize)
        try container.encode(mcpEnabled, forKey: .mcpEnabled)
        try container.encode(Array(enabledTools), forKey: .enabledTools)
        try container.encode(mcpServers, forKey: .mcpServers)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(currentModelConfig, forKey: .currentModelConfig)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        theme = try container.decodeIfPresent(Theme.self, forKey: .theme) ?? .system
        useMetalAcceleration = try container.decodeIfPresent(Bool.self, forKey: .useMetalAcceleration) ?? true
        preferredDevice = try container.decodeIfPresent(Device.self, forKey: .preferredDevice) ?? .auto
        precision = try container.decodeIfPresent(Precision.self, forKey: .precision) ?? .float16
        batchSize = try container.decodeIfPresent(Int.self, forKey: .batchSize) ?? 1
        mcpEnabled = try container.decodeIfPresent(Bool.self, forKey: .mcpEnabled) ?? true
        enabledTools = Set(try container.decodeIfPresent([String].self, forKey: .enabledTools) ?? [])
        mcpServers = try container.decodeIfPresent([MCPServerConfig].self, forKey: .mcpServers) ?? []
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt) ?? "Tu es un assistant IA utile, précis et sûr."
        currentModelConfig = try container.decodeIfPresent(ModelConfig.self, forKey: .currentModelConfig) ?? ModelConfig()
        
        // Initialiser les autres propriétés
        let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        fileStoragePath = baseDirectory.appendingPathComponent("MLXForAll", isDirectory: true)
        
        load2026Models()
        loadMCPTools()
        loadChatHistory()
        loadRecentFiles()
    }
}

// MARK: - Modèles de données

struct LLModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let author: String
    let category: String
    let parameters: Int64
    let fileSize: Int64
    let huggingFaceId: String
    let supportedDevices: [String]
    let license: String
    let tags: [String]
    var isDownloaded: Bool
    var localPath: String?
    let framework: String
    let frameworkVersion: String
    
    var formattedSize: String {
        let gb = Double(fileSize) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var formattedParameters: String {
        if parameters >= 1_000_000_000 {
            return String(format: "%.1fB", Double(parameters) / 1_000_000_000)
        } else if parameters >= 1_000_000 {
            return String(format: "%.1fM", Double(parameters) / 1_000_000)
        } else {
            return "\(parameters)K"
        }
    }
    
    var supportsCurrentDevice: Bool {
        let currentDevice = AppSettings.shared.preferredDevice.rawValue.lowercased()
        return supportedDevices.contains(where: { $0.lowercased() == currentDevice })
    }
}

struct ModelConfig: Codable, Equatable {
    var temperature: Double = 0.7
    var topP: Double = 0.9
    var topK: Int = 50
    var maxTokens: Int = 2048
    var stopSequences: [String] = []
    var presencePenalty: Double = 0.0
    var frequencyPenalty: Double = 0.0
    var repetitionPenalty: Double = 1.0
    var seed: Int? = nil
    var useBeamSearch: Bool = false
    var beamWidth: Int = 5
    var earlyStopping: Bool = true
    
    static func `default`() -> ModelConfig {
        ModelConfig()
    }
    
    static func creative() -> ModelConfig {
        var config = ModelConfig()
        config.temperature = 1.2
        config.topP = 0.95
        config.topK = 100
        config.presencePenalty = 0.8
        config.frequencyPenalty = 0.8
        return config
    }
    
    static func precise() -> ModelConfig {
        var config = ModelConfig()
        config.temperature = 0.2
        config.topP = 0.1
        config.topK = 10
        config.useBeamSearch = true
        config.beamWidth = 3
        return config
    }
    
    static func balanced() -> ModelConfig {
        var config = ModelConfig()
        config.temperature = 0.7
        config.topP = 0.9
        config.topK = 50
        config.presencePenalty = 0.6
        config.frequencyPenalty = 0.6
        return config
    }
}

struct MCPTool: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let parameters: [MCPParameter]
    
    struct MCPParameter: Codable {
        let name: String
        let type: String
        let description: String
        let required: Bool
        let defaultValue: String?
    }
}

struct MCPServerConfig: Identifiable, Codable {
    let id: UUID
    var name: String
    var url: String
    var isConnected: Bool
    var tools: [String]
    
    init(id: UUID = UUID(), name: String, url: String, isConnected: Bool = false, tools: [String] = []) {
        self.id = id
        self.name = name
        self.url = url
        self.isConnected = isConnected
        self.tools = tools
    }
}

struct FileItem: Identifiable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let fileType: String
    let fileSize: Int64
    let modificationDate: Date
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.fileType = url.pathExtension
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? Int64 ?? 0
            self.modificationDate = attributes[.modificationDate] as? Date ?? Date()
        } catch {
            self.fileSize = 0
            self.modificationDate = Date()
        }
    }
    
    var formattedSize: String {
        let bytes = Double(fileSize)
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f Go", bytes / (1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.2f Mo", bytes / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.2f Ko", bytes / 1024)
        } else {
            return "\(fileSize) o"
        }
    }
}

// MARK: - Gestion des erreurs

enum AppError: Error, LocalizedError {
    case modelAlreadyDownloaded
    case modelNotDownloaded
    case modelLoadFailed
    case fileNotFound
    case invalidURL
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .modelAlreadyDownloaded: return "Ce modèle est déjà téléchargé"
        case .modelNotDownloaded: return "Le modèle n'est pas téléchargé"
        case .modelLoadFailed: return "Échec du chargement du modèle"
        case .fileNotFound: return "Fichier non trouvé"
        case .invalidURL: return "URL invalide"
        case .networkError: return "Erreur réseau"
        }
    }
}
