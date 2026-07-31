import Foundation
import SwiftUI

/// Représente une session de chat
class ChatSession: Identifiable, ObservableObject, Codable {
    let id: UUID
    @Published var name: String
    @Published var messages: [ChatMessage]
    @Published var model: LLModel?
    @Published var modelConfig: ModelConfig
    @Published var systemPrompt: String
    @Published var isActive: Bool
    @Published var createdAt: Date
    @Published var updatedAt: Date
    @Published var metadata: [String: AnyCodable]
    
    // Pour l'interface
    @Published var isStreaming: Bool = false
    @Published var currentStreamingMessage: ChatMessage?
    @Published var errorMessage: String?
    
    init(id: UUID = UUID(), name: String = "Nouvelle conversation", model: LLModel? = nil, modelConfig: ModelConfig = ModelConfig.defaultChatConfig(), systemPrompt: String = "Tu es un assistant IA utile, précis et sûr. Réponds de manière claire et concise.") {
        self.id = id
        self.name = name
        self.messages = []
        self.model = model
        self.modelConfig = modelConfig
        self.systemPrompt = systemPrompt
        self.isActive = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.metadata = [:]
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, messages, model, modelConfig, systemPrompt, isActive, createdAt, updatedAt, metadata
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        model = try container.decodeIfPresent(LLModel.self, forKey: .model)
        modelConfig = try container.decode(ModelConfig.self, forKey: .modelConfig)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        metadata = try container.decode([String: AnyCodable].self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(messages, forKey: .messages)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encode(modelConfig, forKey: .modelConfig)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(metadata, forKey: .metadata)
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage) {
        DispatchQueue.main.async {
            self.messages.append(message)
            self.updatedAt = Date()
            self.errorMessage = nil
        }
    }
    
    func addUserMessage(_ content: String, attachments: [ChatAttachment] = []) {
        let message = ChatMessage(role: .user, content: content, attachments: attachments)
        addMessage(message)
    }
    
    func addAssistantMessage(_ content: String, toolCalls: [ToolCall]? = nil, isStreaming: Bool = false) {
        let message = ChatMessage(role: .assistant, content: content, toolCalls: toolCalls, isStreaming: isStreaming)
        addMessage(message)
        if isStreaming {
            currentStreamingMessage = message
        }
    }
    
    func addToolMessage(_ content: String, toolCallId: UUID? = nil) {
        let message = ChatMessage(role: .tool, content: content)
        addMessage(message)
    }
    
    func updateStreamingMessage(_ content: String) {
        DispatchQueue.main.async {
            if var lastMessage = self.messages.last, lastMessage.isStreaming {
                lastMessage.content = content
                lastMessage.isStreaming = true
                self.messages[self.messages.count - 1] = lastMessage
            }
        }
    }
    
    func endStreaming() {
        DispatchQueue.main.async {
            if var lastMessage = self.messages.last, lastMessage.isStreaming {
                lastMessage.isStreaming = false
                self.messages[self.messages.count - 1] = lastMessage
                self.currentStreamingMessage = nil
                self.isStreaming = false
            }
        }
    }
    
    func addToolResult(_ result: ToolResult) {
        DispatchQueue.main.async {
            if var lastMessage = self.messages.last, lastMessage.isAssistant {
                if lastMessage.toolResults == nil {
                    lastMessage.toolResults = []
                }
                lastMessage.toolResults?.append(result)
                self.messages[self.messages.count - 1] = lastMessage
            }
        }
    }
    
    func updateToolCallState(_ toolCallId: UUID, state: ToolCallState) {
        DispatchQueue.main.async {
            if var lastMessage = self.messages.last, lastMessage.isAssistant {
                if let index = lastMessage.toolCalls?.firstIndex(where: { $0.id == toolCallId }) {
                    lastMessage.toolCalls?[index].state = state
                    self.messages[self.messages.count - 1] = lastMessage
                }
            }
        }
    }
    
    func clearMessages() {
        DispatchQueue.main.async {
            self.messages = []
            self.updatedAt = Date()
        }
    }
    
    func deleteMessage(at indexSet: IndexSet) {
        DispatchQueue.main.async {
            self.messages.remove(atOffsets: indexSet)
            self.updatedAt = Date()
        }
    }
    
    // MARK: - Session Management
    
    func activate() {
        DispatchQueue.main.async {
            self.isActive = true
            self.updatedAt = Date()
        }
    }
    
    func deactivate() {
        DispatchQueue.main.async {
            self.isActive = false
            self.updatedAt = Date()
        }
    }
    
    func rename(to newName: String) {
        DispatchQueue.main.async {
            self.name = newName
            self.updatedAt = Date()
        }
    }
    
    // MARK: - Model Configuration
    
    func updateModel(_ model: LLModel) {
        DispatchQueue.main.async {
            self.model = model
            self.updatedAt = Date()
        }
    }
    
    func updateConfig(_ config: ModelConfig) {
        DispatchQueue.main.async {
            self.modelConfig = config
            self.updatedAt = Date()
        }
    }
    
    func updateSystemPrompt(_ prompt: String) {
        DispatchQueue.main.async {
            self.systemPrompt = prompt
            self.updatedAt = Date()
        }
    }
    
    // MARK: - Helper Methods
    
    var lastUserMessage: ChatMessage? {
        messages.last { $0.isUser }
    }
    
    var lastAssistantMessage: ChatMessage? {
        messages.last { $0.isAssistant }
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var userMessageCount: Int {
        messages.filter { $0.isUser }.count
    }
    
    var assistantMessageCount: Int {
        messages.filter { $0.isAssistant }.count
    }
    
    var tokenCount: Int {
        messages.reduce(0) { $0 + estimateTokenCount(for: $1.content) }
    }
    
    private func estimateTokenCount(for text: String) -> Int {
        // Estimation simple : 4 caractères = 1 token
        return max(text.count / 4, 1)
    }
    
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var previewText: String {
        guard let lastMessage = messages.last else { return "Nouvelle conversation" }
        return lastMessage.content.prefix(50) + (lastMessage.content.count > 50 ? "..." : "")
    }
}

/// Configuration du modèle pour le chat
struct ModelConfig: Codable, Equatable {
    var temperature: Double
    var topP: Double
    var topK: Int
    var maxTokens: Int
    var stopSequences: [String]
    var presencePenalty: Double
    var frequencyPenalty: Double
    var repetitionPenalty: Double
    var seed: Int?
    var useBeamSearch: Bool
    var beamWidth: Int
    var earlyStopping: Bool
    
    static func `default`() -> ModelConfig {
        ModelConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 50,
            maxTokens: 1024,
            stopSequences: ["\n\nHuman:", "\n\nAssistant:"],
            presencePenalty: 0.0,
            frequencyPenalty: 0.0,
            repetitionPenalty: 1.0,
            seed: nil,
            useBeamSearch: false,
            beamWidth: 5,
            earlyStopping: true
        )
    }
    
    static func defaultChatConfig() -> ModelConfig {
        ModelConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 50,
            maxTokens: 2048,
            stopSequences: [],
            presencePenalty: 0.6,
            frequencyPenalty: 0.6,
            repetitionPenalty: 1.1,
            seed: nil,
            useBeamSearch: false,
            beamWidth: 5,
            earlyStopping: true
        )
    }
    
    static func creativeConfig() -> ModelConfig {
        ModelConfig(
            temperature: 1.2,
            topP: 0.95,
            topK: 100,
            maxTokens: 2048,
            stopSequences: [],
            presencePenalty: 0.8,
            frequencyPenalty: 0.8,
            repetitionPenalty: 1.2,
            seed: nil,
            useBeamSearch: false,
            beamWidth: 5,
            earlyStopping: true
        )
    }
    
    static func preciseConfig() -> ModelConfig {
        ModelConfig(
            temperature: 0.2,
            topP: 0.1,
            topK: 10,
            maxTokens: 2048,
            stopSequences: [],
            presencePenalty: 0.0,
            frequencyPenalty: 0.0,
            repetitionPenalty: 1.0,
            seed: nil,
            useBeamSearch: true,
            beamWidth: 3,
            earlyStopping: true
        )
    }
    
    var description: String {
        if self == ModelConfig.defaultChatConfig() {
            return "Par défaut"
        } else if self == ModelConfig.creativeConfig() {
            return "Créatif"
        } else if self == ModelConfig.preciseConfig() {
            return "Précis"
        } else {
            return "Personnalisé"
        }
    }
}

/// Modèle de langage
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
    
    static let builtInModels: [LLModel] = [
        LLModel(
            id: "mistral-7b",
            name: "Mistral 7B",
            description: "Modèle de langage puissant et polyvalent avec 7 milliards de paramètres",
            author: "Mistral AI",
            category: "text-generation",
            parameters: 7_000_000_000,
            fileSize: 14_000_000_000,
            huggingFaceId: "mistralai/Mistral-7B-v0.1",
            supportedDevices: ["mps", "cpu"],
            license: "Apache 2.0",
            tags: ["text-generation", "chat", "general"],
            isDownloaded: false,
            localPath: nil
        ),
        LLModel(
            id: "llama-2-7b",
            name: "Llama 2 7B",
            description: "Modèle de langage open-source de Meta avec 7 milliards de paramètres",
            author: "Meta",
            category: "text-generation",
            parameters: 7_000_000_000,
            fileSize: 13_000_000_000,
            huggingFaceId: "meta-llama/Llama-2-7b-chat-hf",
            supportedDevices: ["mps", "cpu"],
            license: "Llama 2",
            tags: ["text-generation", "chat", "general"],
            isDownloaded: false,
            localPath: nil
        ),
        LLModel(
            id: "phi-2",
            name: "Phi-2",
            description: "Modèle léger et efficace avec 2.7 milliards de paramètres",
            author: "Microsoft",
            category: "text-generation",
            parameters: 2_700_000_000,
            fileSize: 4_500_000_000,
            huggingFaceId: "microsoft/phi-2",
            supportedDevices: ["mps", "cpu"],
            license: "MIT",
            tags: ["text-generation", "lightweight", "efficient"],
            isDownloaded: false,
            localPath: nil
        ),
        LLModel(
            id: "gemma-2b",
            name: "Gemma 2B",
            description: "Modèle léger de Google avec 2 milliards de paramètres",
            author: "Google",
            category: "text-generation",
            parameters: 2_000_000_000,
            fileSize: 3_000_000_000,
            huggingFaceId: "google/gemma-2b",
            supportedDevices: ["mps", "cpu"],
            license: "Apache 2.0",
            tags: ["text-generation", "lightweight", "fast"],
            isDownloaded: false,
            localPath: nil
        ),
        LLModel(
            id: "qwen-1.5-0.5b",
            name: "Qwen 1.5 0.5B",
            description: "Modèle très léger avec 500 millions de paramètres",
            author: "Alibaba",
            category: "text-generation",
            parameters: 500_000_000,
            fileSize: 1_000_000_000,
            huggingFaceId: "Qwen/Qwen1.5-0.5B-Chat",
            supportedDevices: ["mps", "cpu"],
            license: "Apache 2.0",
            tags: ["text-generation", "tiny", "fast"],
            isDownloaded: false,
            localPath: nil
        )
    ]
}

/// Gestionnaire des sessions de chat
class ChatSessionManager: ObservableObject {
    static let shared = ChatSessionManager()
    
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let storage: ChatStorageProtocol
    
    init(storage: ChatStorageProtocol = ChatStorage()) {
        self.storage = storage
        loadSessions()
    }
    
    // MARK: - Session Management
    
    func createNewSession(model: LLModel? = nil) -> ChatSession {
        let session = ChatSession(model: model)
        sessions.insert(session, at: 0)
        currentSession = session
        session.activate()
        saveSessions()
        return session
    }
    
    func switchToSession(_ session: ChatSession) {
        currentSession?.deactivate()
        currentSession = session
        session.activate()
    }
    
    func deleteSession(_ session: ChatSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        
        if currentSession?.id == session.id {
            currentSession = nil
        }
        
        sessions.remove(at: index)
        saveSessions()
    }
    
    func deleteAllSessions() {
        sessions.removeAll()
        currentSession = nil
        saveSessions()
    }
    
    func renameSession(_ session: ChatSession, to newName: String) {
        session.rename(to: newName)
        saveSessions()
    }
    
    // MARK: - Persistence
    
    private func loadSessions() {
        do {
            sessions = try storage.loadSessions()
            currentSession = sessions.first
            currentSession?.activate()
        } catch {
            print("Failed to load sessions: \(error)")
            self.error = error
        }
    }
    
    private func saveSessions() {
        do {
            try storage.saveSessions(sessions)
        } catch {
            print("Failed to save sessions: \(error)")
            self.error = error
        }
    }
    
    // MARK: - Helper Methods
    
    var hasSessions: Bool {
        !sessions.isEmpty
    }
    
    var sessionCount: Int {
        sessions.count
    }
}

// Protocole pour le stockage des sessions
protocol ChatStorageProtocol {
    func saveSessions(_ sessions: [ChatSession]) throws
    func loadSessions() throws -> [ChatSession]
}

// Implémentation par défaut du stockage
class ChatStorage: ChatStorageProtocol {
    private let directoryURL: URL
    
    init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        directoryURL = documentsURL.appendingPathComponent("MLXChatApp", isDirectory: true)
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
    
    func saveSessions(_ sessions: [ChatSession]) throws {
        let fileURL = directoryURL.appendingPathComponent("sessions.json")
        let data = try JSONEncoder().encode(sessions)
        try data.write(to: fileURL)
    }
    
    func loadSessions() throws -> [ChatSession] {
        let fileURL = directoryURL.appendingPathComponent("sessions.json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ChatSession].self, from: data)
    }
}
