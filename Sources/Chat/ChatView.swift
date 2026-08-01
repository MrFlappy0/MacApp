import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedFiles: [URL] = []
    
    private var currentChat: Binding<ChatSession?> {
        Binding(
            get: { appSettings.currentChat },
            set: { appSettings.currentChat = $0 }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Zone des messages
            messagesView
            
            // Zone d'entrée
            inputArea
        }
        .background(Color(.systemBackground))
        .navigationTitle(appSettings.currentChat?.name ?? "Nouveau chat")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                chatToolbar
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
        .onAppear {
            if appSettings.currentChat == nil {
                appSettings.createNewChat()
            }
        }
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let chat = appSettings.currentChat {
                        ForEach(chat.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        if chat.isStreaming {
                            StreamingIndicatorView()
                                .id("streaming")
                                .transition(.opacity)
                        }
                    } else {
                        welcomeView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .onChange(of: appSettings.currentChat?.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: appSettings.currentChat?.isStreaming) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Bienvenue dans MLX for All")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Commencez une conversation avec l'IA. Vous pouvez :")
                .font(.title2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(.blue)
                    Text("Discuter avec l'IA")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.blue)
                    Text("Joindre des fichiers")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "wrench")
                        .foregroundColor(.blue)
                    Text("Utiliser des outils MCP")
                }
            }
            .font(.body)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Bouton pour joindre des fichiers
            Button(action: {
                showFileImporter = true
            }) {
                Image(systemName: "paperclip")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .help("Joindre un fichier")
            .disabled(isSending)
            
            // Champ de texte
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .frame(minHeight: 44, maxHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .disabled(isSending)
                
                if inputText.isEmpty {
                    Text("Saisissez votre message...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .onTapGesture {
                            // Ne rien faire, juste pour l'affichage
                        }
                }
            }
            
            // Bouton d'envoi
            Button(action: sendMessage) {
                Image(systemName: isSending ? "stop.circle" : "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isSending ? .red : (inputText.isEmpty ? .secondary : .blue))
                    .padding(8)
            }
            .buttonStyle(.plain)
            .help(isSending ? "Arrêter" : "Envoyer")
            .disabled(inputText.isEmpty && !isSending)
        }
        .padding(.all, 16)
        .background(Color(.systemBackground))
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
    
    private var chatToolbar: some View {
        HStack(spacing: 8) {
            // Bouton pour nouveau chat
            Button(action: {
                appSettings.createNewChat()
            }) {
                Image(systemName: "plus")
            }
            .help("Nouveau chat")
            
            // Bouton pour effacer le chat
            Button(action: {
                if let chat = appSettings.currentChat {
                    chat.clearMessages()
                }
            }) {
                Image(systemName: "trash")
            }
            .help("Effacer le chat")
            .disabled(appSettings.currentChat?.messages.isEmpty == false)
            
            // Bouton pour les paramètres du modèle
            Button(action: {
                appSettings.currentTab = .settings
            }) {
                Image(systemName: "slider.horizontal.3")
            }
            .help("Paramètres")
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard let chat = appSettings.currentChat, !inputText.isEmpty else { return }
        
        isSending = true
        chat.isStreaming = true
        
        // Ajouter le message utilisateur
        chat.addUserMessage(inputText, attachments: selectedFiles.map { 
            ChatAttachment(url: $0)
        })
        
        inputText = ""
        selectedFiles = []
        
        // Simuler une réponse de l'assistant
        simulateAssistantResponse(chat: chat)
    }
    
    private func simulateAssistantResponse(chat: ChatSession) {
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 0.5)
            
            let responseText = generateResponse(for: chat)
            let tokens = responseText.map { String($0) }
            var fullResponse = ""
            
            DispatchQueue.main.async {
                chat.addAssistantMessage("", isStreaming: true)
            }
            
            for token in tokens {
                Thread.sleep(forTimeInterval: 0.02)
                fullResponse += token
                DispatchQueue.main.async {
                    chat.updateStreamingMessage(fullResponse)
                }
            }
            
            DispatchQueue.main.async {
                chat.endStreaming()
                self.isSending = false
            }
        }
    }
    
    private func generateResponse(for chat: ChatSession) -> String {
        let lastUserMessage = chat.lastUserMessage?.content ?? ""
        
        // Vérifier si des outils MCP doivent être utilisés
        if appSettings.mcpEnabled && !appSettings.enabledTools.isEmpty {
            // Simuler l'utilisation d'outils
            if lastUserMessage.lowercased().contains("recherche") || lastUserMessage.lowercased().contains("web") {
                return "J'ai effectué une recherche web pour vous. Voici les résultats :\n\n[Résultats de recherche simulés]\n\nN'hésitez pas à me demander plus de détails !"
            }
            
            if lastUserMessage.lowercased().contains("calcule") || lastUserMessage.lowercased().contains("math") {
                return "Résultat du calcul : 42\n\n(Exemple de calcul simulé)"
            }
            
            if lastUserMessage.lowercased().contains("fichier") || lastUserMessage.lowercased().contains("lire") {
                return "J'ai analysé le fichier que vous avez joint. Voici ce que j'ai trouvé :\n\n[Contenu du fichier simulé]"
            }
        }
        
        // Réponses générales
        if lastUserMessage.lowercased().contains("bonjour") || lastUserMessage.lowercased().contains("salut") {
            return "Bonjour ! Comment puis-je vous aider aujourd'hui ?"
        } else if lastUserMessage.lowercased().contains("comment ça va") {
            return "Je vais très bien, merci ! Et vous ?"
        } else if lastUserMessage.lowercased().contains("qui es-tu") {
            return "Je suis \(appSettings.appName), un assistant IA basé sur \(chat.model?.name ?? 'un modèle de langage'). Je suis ici pour vous aider avec vos questions et tâches."
        } else if lastUserMessage.lowercased().contains("modèle") {
            return "Vous utilisez actuellement le modèle : \(chat.model?.name ?? 'Aucun'). Vous pouvez changer de modèle dans les paramètres."
        } else {
            return "Je comprends. Voici une réponse basée sur votre message. N'hésitez pas à me donner plus de détails si vous avez besoin d'aide supplémentaire."
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            selectedFiles = urls
            
            // Ajouter les fichiers aux fichiers récents
            for url in urls {
                appSettings.addRecentFile(url)
            }
            
            // Si on est dans un chat, on peut envoyer automatiquement
            if !urls.isEmpty && inputText.isEmpty {
                inputText = "Fichiers joints: \(urls.map { $0.lastPathComponent }.joined(separator: ", "))"
            }
            
        case .failure(let error):
            appSettings.modelDownloadError = error
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = appSettings.currentChat?.messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if appSettings.currentChat?.isStreaming == true {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }
}

// MARK: - Subviews

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Image(systemName: message.role.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(message.role.color)
                .clipShape(Circle())
            
            // Contenu du message
            VStack(alignment: .leading, spacing: 8) {
                // En-tête
                HStack(spacing: 4) {
                    Text(message.role.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(message.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Contenu
                if message.isStreaming {
                    Text(message.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                    +
                    Text("▌")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .textSelection(.disabled)
                } else {
                    Text(message.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
                
                // Pièces jointes
                if message.hasAttachments {
                    AttachmentsView(attachments: message.attachments)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(message.isUser ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(message.isUser ? Color.blue.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
        )
        .contextMenu {
            Button(action: {}) {
                Label("Copier", systemImage: "doc.on.doc")
            }
            
            if !message.isUser {
                Button(action: {}) {
                    Label("Régénérer", systemImage: "arrow.clockwise")
                }
            }
            
            Button(action: {}) {
                Label("Supprimer", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct AttachmentsView: View {
    let attachments: [ChatAttachment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                AttachmentView(attachment: attachment)
            }
        }
    }
}

struct AttachmentView: View {
    let attachment: ChatAttachment
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: attachment.icon)
                .font(.system(size: 16))
                .foregroundColor(attachment.color)
                .frame(width: 32, height: 32)
                .background(attachment.color.opacity(0.1))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(attachment.fileType.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(attachment.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Bouton pour ouvrir
            Button(action: {
                NSWorkspace.shared.open(attachment.url)
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct StreamingIndicatorView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.blue)
                .clipShape(Circle())
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.secondary)
                        .scaleEffect(index == 0 ? 1.0 : (index == 1 ? 0.7 : 0.4))
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: UUID()
                        )
                }
            }
            
            Text("Réflexion en cours...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Modèles de données pour le chat

struct ChatSession: Identifiable, ObservableObject, Codable {
    let id: UUID
    @Published var name: String
    @Published var messages: [ChatMessage]
    @Published var model: LLModel?
    @Published var modelConfig: ModelConfig
    @Published var isStreaming: Bool = false
    @Published var createdAt: Date
    @Published var updatedAt: Date
    
    init(id: UUID = UUID(), name: String = "Nouvelle conversation", model: LLModel? = nil, modelConfig: ModelConfig = ModelConfig()) {
        self.id = id
        self.name = name
        self.messages = []
        self.model = model
        self.modelConfig = modelConfig
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
    }
    
    func addUserMessage(_ content: String, attachments: [ChatAttachment] = []) {
        let message = ChatMessage(role: .user, content: content, attachments: attachments)
        addMessage(message)
    }
    
    func addAssistantMessage(_ content: String, isStreaming: Bool = false) {
        let message = ChatMessage(role: .assistant, content: content, isStreaming: isStreaming)
        addMessage(message)
    }
    
    func updateStreamingMessage(_ content: String) {
        if var lastMessage = messages.last, lastMessage.isStreaming {
            lastMessage.content = content
            messages[messages.count - 1] = lastMessage
        }
    }
    
    func endStreaming() {
        if var lastMessage = messages.last, lastMessage.isStreaming {
            lastMessage.isStreaming = false
            messages[messages.count - 1] = lastMessage
            isStreaming = false
        }
    }
    
    func clearMessages() {
        messages = []
        updatedAt = Date()
    }
    
    var lastUserMessage: ChatMessage? {
        messages.last { $0.isUser }
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

enum ChatMessageRole: String, Codable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
    case tool = "tool"
    
    var displayName: String {
        switch self {
        case .system: return "Système"
        case .user: return "Vous"
        case .assistant: return "Assistant"
        case .tool: return "Outil"
        }
    }
    
    var color: Color {
        switch self {
        case .system: return .gray
        case .user: return .blue
        case .assistant: return .green
        case .tool: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gearshape"
        case .user: return "person"
        case .assistant: return "robot"
        case .tool: return "wrench"
        }
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: ChatMessageRole
    let content: String
    let timestamp: Date
    var attachments: [ChatAttachment]
    var isStreaming: Bool
    
    init(id: UUID = UUID(), role: ChatMessageRole, content: String, attachments: [ChatAttachment] = [], isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.attachments = attachments
        self.isStreaming = isStreaming
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var isUser: Bool {
        role == .user
    }
    
    var isAssistant: Bool {
        role == .assistant
    }
    
    var hasAttachments: Bool {
        !attachments.isEmpty
    }
}

struct ChatAttachment: Identifiable, Codable {
    let id: UUID
    let url: URL
    let filename: String
    let fileType: String
    let fileSize: Int64
    
    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
        self.filename = url.lastPathComponent
        self.fileType = url.pathExtension
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            self.fileSize = 0
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
    
    var icon: String {
        switch fileType.lowercased() {
        case "pdf": return "doc.text.magnifyingglass"
        case "txt", "md", "csv": return "doc.text"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo"
        case "mp3", "wav", "aac": return "waveform"
        case "mp4", "mov", "avi": return "video"
        case "json": return "curlybraces"
        case "zip", "tar", "gz": return "folder"
        default: return "doc"
        }
    }
    
    var color: Color {
        switch fileType.lowercased() {
        case "pdf": return .red
        case "txt", "md": return .blue
        case "csv": return .green
        case "jpg", "jpeg", "png", "gif", "heic": return .purple
        case "mp3", "wav", "aac": return .orange
        case "mp4", "mov", "avi": return .pink
        case "json": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Stockage du chat

class ChatStorage {
    private let directoryURL: URL
    
    init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        directoryURL = documentsURL.appendingPathComponent("MLXForAll/Chats", isDirectory: true)
        
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

// MARK: - Preview

#Preview {
    ChatView()
        .environmentObject(AppSettings.shared)
}
