import Foundation
import SwiftUI

/// Représente un message dans la conversation
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

/// Structure d'un message dans le chat
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: ChatMessageRole
    let content: String
    let timestamp: Date
    var attachments: [ChatAttachment]
    var toolCalls: [ToolCall]?
    var toolResults: [ToolResult]?
    var isStreaming: Bool
    var metadata: [String: AnyCodable]?
    
    init(id: UUID = UUID(), role: ChatMessageRole, content: String, attachments: [ChatAttachment] = [], toolCalls: [ToolCall]? = nil, isStreaming: Bool = false, metadata: [String: AnyCodable]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.attachments = attachments
        self.toolCalls = toolCalls
        self.isStreaming = isStreaming
        self.metadata = metadata
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
    
    var isSystem: Bool {
        role == .system
    }
    
    var isTool: Bool {
        role == .tool
    }
    
    var hasAttachments: Bool {
        !attachments.isEmpty
    }
    
    var hasToolCalls: Bool {
        toolCalls?.isEmpty == false
    }
}

/// Pièce jointe dans un message
struct ChatAttachment: Identifiable, Codable {
    let id: UUID
    let filename: String
    let fileType: String
    let fileSize: Int64
    let fileURL: URL
    let preview: String?
    let metadata: [String: String]
    
    init(id: UUID = UUID(), filename: String, fileType: String, fileSize: Int64, fileURL: URL, preview: String? = nil, metadata: [String: String] = [:]) {
        self.id = id
        self.filename = filename
        self.fileType = fileType
        self.fileSize = fileSize
        self.fileURL = fileURL
        self.preview = preview
        self.metadata = metadata
    }
    
    var formattedSize: String {
        let bytes = Double(fileSize)
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.2f MB", bytes / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.2f KB", bytes / 1024)
        } else {
            return "\(fileSize) B"
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

/// Appel d'outil dans un message
struct ToolCall: Identifiable, Codable {
    let id: UUID
    let name: String
    let arguments: [String: AnyCodable]
    var state: ToolCallState
    
    init(id: UUID = UUID(), name: String, arguments: [String: AnyCodable], state: ToolCallState = .pending) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.state = state
    }
}

/// État d'un appel d'outil
enum ToolCallState: String, Codable {
    case pending = "pending"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
}

/// Résultat d'un appel d'outil
struct ToolResult: Identifiable, Codable {
    let id: UUID
    let toolCallId: UUID
    let content: String
    let success: Bool
    let error: String?
    
    init(id: UUID = UUID(), toolCallId: UUID, content: String, success: Bool = true, error: String? = nil) {
        self.id = id
        self.toolCallId = toolCallId
        self.content = content
        self.success = success
        self.error = error
    }
}

/// Type pour gérer Any dans Codable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self.value = string
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Value cannot be encoded"))
        }
    }
}
