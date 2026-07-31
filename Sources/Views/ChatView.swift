import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatSessionManager: ChatSessionManager
    
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showModelSelector: Bool = false
    @State private var showSettings: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedFiles: [URL] = []
    @State private var isStreaming: Bool = false
    @State private var scrollProxy: ScrollViewProxy?
    
    private var currentSession: ChatSession? {
        chatSessionManager.currentSession
    }
    
    var body: some View {
        NavigationSplitView {
            ChatSidebarView()
                .environmentObject(chatSessionManager)
        } detail: {
            mainChatView
        }
        .navigationTitle(currentSession?.name ?? "Nouvelle conversation")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                chatToolbar
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.text, .pdf, .image, .audio, .video, .folder],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(selectedModel: Binding(
                get: { currentSession?.model },
                set: { newModel in
                    currentSession?.updateModel(newModel)
                }
            ))
            .environmentObject(appState)
        }
        .sheet(isPresented: $showSettings) {
            ChatSettingsView(config: Binding(
                get: { currentSession?.modelConfig ?? ModelConfig.defaultChatConfig() },
                set: { newConfig in
                    currentSession?.updateConfig(newConfig)
                }
            ))
        }
        .onAppear {
            if chatSessionManager.sessions.isEmpty {
                chatSessionManager.createNewSession()
            }
        }
    }
    
    private var mainChatView: some View {
        VStack(spacing: 0) {
            // Zone des messages
            messagesView
            
            // Zone d'entrée
            inputArea
        }
        .background(Color(.systemBackground))
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(currentSession?.messages ?? []) { message in
                        MessageView(message: message)
                            .id(message.id)
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    if isStreaming {
                        StreamingIndicatorView()
                            .id("streaming")
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .onChange(of: currentSession?.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isStreaming) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom(proxy: proxy)
            }
        }
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
                chatSessionManager.createNewSession()
            }) {
                Image(systemName: "plus")
            }
            .help("Nouveau chat")
            
            // Bouton pour sélectionner le modèle
            Button(action: {
                showModelSelector = true
            }) {
                Image(systemName: "brain")
            }
            .help("Changer de modèle")
            
            // Bouton pour les paramètres
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "slider.horizontal.3")
            }
            .help("Paramètres du chat")
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard let session = currentSession, !inputText.isEmpty else { return }
        
        isSending = true
        isStreaming = true
        
        // Ajouter le message utilisateur
        session.addUserMessage(inputText)
        inputText = ""
        
        // Simuler une réponse de l'assistant
        simulateAssistantResponse(session: session)
    }
    
    private func simulateAssistantResponse(session: ChatSession) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulation de temps de traitement
            Thread.sleep(forTimeInterval: 0.5)
            
            let responseText = generateResponse(for: session)
            
            DispatchQueue.main.async {
                // Commencer le streaming
                session.addAssistantMessage("", isStreaming: true)
                
                // Simuler le streaming token par token
                let tokens = responseText.map { String($0) }
                var fullResponse = ""
                
                for token in tokens {
                    Thread.sleep(forTimeInterval: 0.02)
                    fullResponse += token
                    DispatchQueue.main.async {
                        session.updateStreamingMessage(fullResponse)
                    }
                }
                
                // Terminer le streaming
                DispatchQueue.main.async {
                    session.endStreaming()
                    self.isSending = false
                    self.isStreaming = false
                }
            }
        }
    }
    
    private func generateResponse(for session: ChatSession) -> String {
        let lastUserMessage = session.lastUserMessage?.content ?? ""
        
        // Réponse simple basée sur le message
        if lastUserMessage.lowercased().contains("bonjour") || lastUserMessage.lowercased().contains("salut") {
            return "Bonjour ! Comment puis-je vous aider aujourd'hui ?"
        } else if lastUserMessage.lowercased().contains("comment ça va") {
            return "Je vais très bien, merci ! Et vous ?"
        } else if lastUserMessage.lowercased().contains("qui es-tu") {
            return "Je suis un assistant IA basé sur \(session.model?.name ?? 'un modèle de langage'). Je suis ici pour vous aider avec vos questions et tâches."
        } else if lastUserMessage.lowercased().contains("calcule") {
            return "Je peux effectuer des calculs pour vous. Essayez de me demander un calcul spécifique comme 'Quelle est la racine carrée de 144 ?'"
        } else if lastUserMessage.lowercased().contains("fichier") {
            return "Je peux vous aider à analyser des fichiers. Vous pouvez joindre des fichiers en cliquant sur l'icône de trombone dans la barre d'entrée."
        } else {
            return "Je comprends. Voici une réponse basée sur votre message : '\(lastUserMessage)'. N'hésitez pas à me donner plus de détails si vous avez besoin d'aide supplémentaire."
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processFiles(urls)
        case .failure(let error):
            appState.showError("Échec de l'importation : \(error.localizedDescription)")
        }
    }
    
    private func processFiles(_ urls: [URL]) {
        guard let session = currentSession else { return }
        
        var attachments: [ChatAttachment] = []
        
        for url in urls {
            let fileName = url.lastPathComponent
            let fileType = url.pathExtension
            let fileSize = getFileSize(url)
            
            // Lire un aperçu pour les fichiers texte
            var preview: String? = nil
            if fileType == "txt" || fileType == "md" || fileType == "json" || fileType == "csv" {
                preview = try? String(contentsOf: url).prefix(200).description
            }
            
            let attachment = ChatAttachment(
                filename: fileName,
                fileType: fileType,
                fileSize: fileSize,
                fileURL: url,
                preview: preview,
                metadata: ["importedAt": Date().ISO8601Format()]
            )
            
            attachments.append(attachment)
        }
        
        if !attachments.isEmpty {
            session.addUserMessage("Fichiers joints: \(attachments.map { $0.filename }.joined(separator: ", "))", attachments: attachments)
        }
    }
    
    private func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = currentSession?.messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if isStreaming {
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
                
                // Appels d'outils
                if message.hasToolCalls {
                    ToolCallsView(toolCalls: message.toolCalls ?? [])
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
            
            // Bouton pour télécharger/ouvrir
            Button(action: {}) {
                Image(systemName: "arrow.down")
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

struct ToolCallsView: View {
    let toolCalls: [ToolCall]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(toolCalls) { toolCall in
                ToolCallView(toolCall: toolCall)
            }
        }
    }
}

struct ToolCallView: View {
    let toolCall: ToolCall
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench")
                .font(.system(size: 14))
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(toolCall.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if !toolCall.arguments.isEmpty {
                    Text(argumentsDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // État
            stateIndicator
        }
        .padding(8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var argumentsDescription: String {
        toolCall.arguments.map { "\($0.key): \($0.value.value)" }.joined(separator: ", ")
    }
    
    private var stateIndicator: some View {
        Group {
            switch toolCall.state {
            case .pending:
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.5)
            case .running:
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

struct StreamingIndicatorView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "robot")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.green)
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

// MARK: - Sidebar

struct ChatSidebarView: View {
    @EnvironmentObject var chatSessionManager: ChatSessionManager
    
    var body: some View {
        List(selection: $chatSessionManager.currentSession) {
            Section("Conversations") {
                // Bouton pour nouveau chat
                Button(action: {
                    chatSessionManager.createNewSession()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 16))
                        
                        Text("Nouveau chat")
                            .font(.body)
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                
                // Liste des sessions
                ForEach(chatSessionManager.sessions) { session in
                    NavigationLink(value: session) {
                        SessionRowView(session: session)
                            .tag(session)
                    }
                    .tag(session)
                }
                .onDelete { indices in
                    deleteSessions(at: indices)
                }
            }
            
            Section("Outils") {
                NavigationLink {
                    LLMRecommenderView()
                        .environmentObject(AppState.shared)
                        .environmentObject(ModelViewModel.shared)
                } label: {
                    Label("Recommandation LLM", systemImage: "server.rack")
                }
                
                NavigationLink {
                    ModelManagerView()
                        .environmentObject(ModelViewModel.shared)
                } label: {
                    Label("Gestion des modèles", systemImage: "brain.head.profile")
                }
            }
        }
        .navigationTitle("MLX Chat")
        .listStyle(.sidebar)
        .toolbar {
            EditButton()
        }
    }
    
    private func deleteSessions(at indices: IndexSet) {
        for index in indices {
            let session = chatSessionManager.sessions[index]
            chatSessionManager.deleteSession(session)
        }
    }
}

struct SessionRowView: View {
    let session: ChatSession
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.body)
                    .lineLimit(1)
                
                if !session.messages.isEmpty {
                    Text(session.previewText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if session.isActive {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings

struct ChatSettingsView: View {
    @Binding var config: ModelConfig
    @Environment(\dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Paramètres de génération")) {
                    // Température
                    SliderSetting(
                        value: $config.temperature,
                        range: 0...2,
                        step: 0.1,
                        label: "Température",
                        description: "Contrôle la créativité. Plus c'est élevé, plus les réponses sont variées."
                    )
                    
                    // Top P
                    SliderSetting(
                        value: $config.topP,
                        range: 0...1,
                        step: 0.05,
                        label: "Top P",
                        description: "Probabilité cumulative pour l'échantillonnage."
                    )
                    
                    // Top K
                    SliderSetting(
                        value: Binding(
                            get: { Double(config.topK) },
                            set: { config.topK = Int($0) }
                        ),
                        range: 1...100,
                        step: 1,
                        label: "Top K",
                        description: "Nombre de tokens à considérer pour l'échantillonnage."
                    )
                }
                
                Section(header: Text("Limites")) {
                    // Max Tokens
                    StepperSetting(
                        value: $config.maxTokens,
                        range: 16...4096,
                        step: 16,
                        label: "Tokens maximum",
                        description: "Nombre maximum de tokens à générer."
                    )
                }
                
                Section(header: Text("Pénalités")) {
                    // Presence Penalty
                    SliderSetting(
                        value: $config.presencePenalty,
                        range: -2...2,
                        step: 0.1,
                        label: "Pénalité de présence",
                        description: "Pénalise les nouveaux sujets."
                    )
                    
                    // Frequency Penalty
                    SliderSetting(
                        value: $config.frequencyPenalty,
                        range: -2...2,
                        step: 0.1,
                        label: "Pénalité de fréquence",
                        description: "Pénalise les répétitions."
                    )
                    
                    // Repetition Penalty
                    SliderSetting(
                        value: $config.repetitionPenalty,
                        range: 0.1...2,
                        step: 0.1,
                        label: "Pénalité de répétition",
                        description: "Pénalise les répétitions exactes."
                    )
                }
                
                Section(header: Text("Options avancées")) {
                    Toggle("Utiliser la recherche par faisceau", isOn: $config.useBeamSearch)
                    
                    if config.useBeamSearch {
                        Stepper("Largeur du faisceau: \(config.beamWidth)", value: $config.beamWidth, in: 2...10)
                    }
                    
                    Toggle("Arrêt précoce", isOn: $config.earlyStopping)
                }
            }
            .navigationTitle("Paramètres du chat")
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

// MARK: - Model Selection

struct ModelSelectorView: View {
    @Binding var selectedModel: LLModel?
    @EnvironmentObject var appState: AppState
    @Environment(\dismiss) var dismiss
    
    @State private var searchText: String = ""
    @State private var showHuggingFaceSearch: Bool = false
    
    var filteredModels: [LLModel] {
        if searchText.isEmpty {
            return LLModel.builtInModels
        } else {
            return LLModel.builtInModels.filter { model in
                model.name.lowercased().contains(searchText.lowercased()) ||
                model.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    SearchBar(text: $searchText, placeholder: "Rechercher un modèle...")
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                }
                
                Section("Modèles intégrés") {
                    ForEach(filteredModels) { model in
                        ModelRowView(
                            model: model,
                            isSelected: selectedModel?.id == model.id,
                            action: { selectedModel = model }
                        )
                    }
                }
                
                Section {
                    Button(action: {
                        showHuggingFaceSearch = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                            
                            Text("Rechercher sur Hugging Face")
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Sélectionner un modèle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHuggingFaceSearch) {
                HuggingFaceSearchView(selectedModel: $selectedModel)
            }
        }
    }
}

struct ModelRowView: View {
    let model: LLModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
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
        .buttonStyle(.plain)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
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

// MARK: - Hugging Face Search

struct HuggingFaceSearchView: View {
    @Binding var selectedModel: LLModel?
    @Environment(\dismiss) var dismiss
    
    @State private var searchText: String = ""
    @State private var searchResults: [HuggingFaceModel] = []
    @State private var isSearching: Bool = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText, placeholder: "Rechercher sur Hugging Face...")
                    .padding(.horizontal)
                    .onChange(of: searchText) { newValue in
                        if !newValue.isEmpty {
                            searchModels()
                        } else {
                            searchResults = []
                        }
                    }
                
                if isSearching {
                    ProgressView()
                        .padding(20)
                } else if let error = error {
                    ErrorView(error: error) {
                        searchModels()
                    }
                    .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        Text("Aucun résultat trouvé")
                            .font(.headline)
                        
                        Text("Essayez une autre requête de recherche")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(searchResults) { model in
                        HuggingFaceModelRow(model: model, action: { selectedModel = convertToLLModel(model) })
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Hugging Face")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchModels() {
        isSearching = true
        error = nil
        
        HuggingFaceClient.shared.searchModels(query: searchText, filter: "text-generation", limit: 20) { result in
            DispatchQueue.main.async {
                isSearching = false
                
                switch result {
                case .success(let models):
                    searchResults = models
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
    
    private func convertToLLModel(_ model: HuggingFaceModel) -> LLModel {
        LLModel(
            id: model.id,
            name: model.displayName,
            description: model.description ?? "",
            author: model.author ?? "Inconnu",
            category: "text-generation",
            parameters: 0, // À déterminer
            fileSize: 0, // À déterminer
            huggingFaceId: model.id,
            supportedDevices: ["mps", "cpu"],
            license: "Inconnu",
            tags: model.tags ?? [],
            isDownloaded: false,
            localPath: nil
        )
    }
}

struct HuggingFaceModelRow: View {
    let model: HuggingFaceModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let description = model.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let downloads = model.downloads {
                        Text(model.formattedDownloads)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let likes = model.likes {
                        Text("\(likes) likes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
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
            
            Button(action: retryAction) {
                Text("Réessayer")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Model Manager

struct ModelManagerView: View {
    @EnvironmentObject var modelViewModel: ModelViewModel
    @State private var showDownloader: Bool = false
    @State private var selectedModel: LLModel?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Modèles téléchargés") {
                    ForEach(modelViewModel.downloadedModels) { model in
                        ModelManagerRow(model: model)
                    }
                }
                
                Section("Modèles disponibles") {
                    ForEach(LLModel.builtInModels.filter { !$0.isDownloaded }) { model in
                        ModelManagerRow(model: model)
                            .swipeActions {
                                Button(action: {
                                    selectedModel = model
                                    showDownloader = true
                                }) {
                                    Label("Télécharger", systemImage: "arrow.down")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Gestion des modèles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showDownloader = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showDownloader) {
                if let model = selectedModel {
                    ModelDownloadView(model: model)
                        .environmentObject(modelViewModel)
                }
            }
        }
    }
}

struct ModelManagerRow: View {
    let model: LLModel
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(model.formattedParameters)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if model.isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct ModelDownloadView: View {
    let model: LLModel
    @EnvironmentObject var modelViewModel: ModelViewModel
    @Environment(\dismiss) var dismiss
    
    @State private var progress: Double = 0
    @State private var isDownloading: Bool = false
    @State private var error: Error?
    
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
                    
                    Text(model.formattedSize)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if isDownloading {
                    VStack(spacing: 12) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(.linear)
                            .scaleEffect(1.5, anchor: .center)
                        
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.headline)
                    }
                } else if let error = error {
                    ErrorView(error: error) {
                        startDownload()
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
                            startDownload()
                        }
                        .disabled(isDownloading)
                    }
                }
            }
        }
    }
    
    private func startDownload() {
        isDownloading = true
        error = nil
        progress = 0
        
        modelViewModel.downloadModel(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    self.error = error
                    isDownloading = false
                }
            }
        } onProgress: { progressValue in
            DispatchQueue.main.async {
                progress = progressValue
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
        .environmentObject(AppState.shared)
        .environmentObject(ChatSessionManager.shared)
}
