import Foundation
import SwiftUI

/// Protocole pour les outils MCP
protocol MCPToolProtocol {
    var name: String { get }
    var description: String { get }
    var parameters: [MCPParameter] { get }
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void)
}

/// Paramètre d'un outil MCP
struct MCPParameter: Codable {
    let name: String
    let type: String
    let description: String
    let required: Bool
    let defaultValue: Any?
}

/// Résultat d'un outil MCP
struct MCPToolResult: Codable {
    let content: String
    let success: Bool
    let error: String?
    let metadata: [String: AnyCodable]?
}

/// Client MCP pour gérer les outils
class MCPClient {
    static let shared = MCPClient()
    
    private var tools: [String: MCPToolProtocol] = [:]
    private var connectedServers: [MCPServer] = []
    
    init() {
        registerBuiltInTools()
    }
    
    // MARK: - Tool Management
    
    func registerTool(_ tool: MCPToolProtocol) {
        tools[tool.name] = tool
    }
    
    func unregisterTool(_ name: String) {
        tools.removeValue(forKey: name)
    }
    
    func getTool(_ name: String) -> MCPToolProtocol? {
        tools[name]
    }
    
    func listTools() -> [MCPToolProtocol] {
        Array(tools.values)
    }
    
    func executeTool(_ name: String, arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let tool = tools[name] else {
            completion(.failure(MCPError.toolNotFound))
            return
        }
        
        tool.execute(arguments: arguments, completion: completion)
    }
    
    // MARK: - Server Management
    
    func connectServer(_ server: MCPServer) {
        connectedServers.append(server)
        server.connect()
    }
    
    func disconnectServer(_ server: MCPServer) {
        if let index = connectedServers.firstIndex(where: { $0.id == server.id }) {
            connectedServers[index].disconnect()
            connectedServers.remove(at: index)
        }
    }
    
    func listServers() -> [MCPServer] {
        connectedServers
    }
    
    // MARK: - Built-in Tools
    
    private func registerBuiltInTools() {
        // Outils de recherche web
        registerTool(WebSearchTool())
        registerTool(WebFetchTool())
        
        // Outils de fichiers
        registerTool(FileReadTool())
        registerTool(FileWriteTool())
        registerTool(FileListTool())
        registerTool(FileDeleteTool())
        
        // Outils système
        registerTool(DateTimeTool())
        registerTool(CalculatorTool())
        
        // Outils de calcul
        registerTool(CodeExecutionTool())
    }
}

/// Erreurs MCP
enum MCPError: Error {
    case toolNotFound
    case invalidArguments
    case executionFailed
    case serverNotFound
    case connectionFailed
    
    var localizedDescription: String {
        switch self {
        case .toolNotFound: return "Outil non trouvé"
        case .invalidArguments: return "Arguments invalides"
        case .executionFailed: return "Échec de l'exécution"
        case .serverNotFound: return "Serveur non trouvé"
        case .connectionFailed: return "Échec de la connexion"
        }
    }
}

/// Serveur MCP
class MCPServer: Identifiable {
    let id: UUID
    let name: String
    let url: String
    var isConnected: Bool = false
    var tools: [MCPToolProtocol] = []
    
    init(id: UUID = UUID(), name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
    
    func connect() {
        // Connexion au serveur MCP
        isConnected = true
    }
    
    func disconnect() {
        isConnected = false
    }
    
    func listTools() -> [MCPToolProtocol] {
        tools
    }
}

// MARK: - Built-in Tools

/// Outil de recherche web
class WebSearchTool: MCPToolProtocol {
    let name = "web_search"
    let description = "Effectue une recherche sur le web"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "query", type: "string", description: "Requête de recherche", required: true, defaultValue: nil),
        MCPParameter(name: "max_results", type: "integer", description: "Nombre maximum de résultats", required: false, defaultValue: 5)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let query = arguments["query"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let maxResults = arguments["max_results"] as? Int ?? 5
        
        // Simulation de recherche web
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.0)
            
            let results = (1...maxResults).map { index in
                "Résultat \(index): Informations pertinentes sur '\(query)' depuis une source fiable."
            }
            
            let content = results.joined(separator: "\n\n")
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: content,
                    success: true,
                    error: nil,
                    metadata: nil
                )))
            }
        }
    }
}

/// Outil de récupération de page web
class WebFetchTool: MCPToolProtocol {
    let name = "web_fetch"
    let description = "Récupère le contenu d'une URL"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "url", type: "string", description: "URL à récupérer", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let urlString = arguments["url"] as? String,
              let url = URL(string: urlString) else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        // Simulation de récupération web
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.5)
            
            let content = "Contenu récupéré depuis \(urlString). Voici le texte extrait de la page."
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: content,
                    success: true,
                    error: nil,
                    metadata: ["url": AnyCodable(urlString)]
                )))
            }
        }
    }
}

/// Outil de lecture de fichier
class FileReadTool: MCPToolProtocol {
    let name = "file_read"
    let description = "Lit le contenu d'un fichier"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            let content = try String(contentsOf: fileURL)
            completion(.success(MCPToolResult(
                content: content,
                success: true,
                error: nil,
                metadata: ["path": AnyCodable(path)]
            )))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Outil d'écriture de fichier
class FileWriteTool: MCPToolProtocol {
    let name = "file_write"
    let description = "Écrit du contenu dans un fichier"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil),
        MCPParameter(name: "content", type: "string", description: "Contenu à écrire", required: true, defaultValue: nil),
        MCPParameter(name: "append", type: "boolean", description: "Ajouter au fichier existant", required: false, defaultValue: false)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String,
              let content = arguments["content"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let append = arguments["append"] as? Bool ?? false
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            if append, FileManager.default.fileExists(atPath: path) {
                let existingContent = try String(contentsOf: fileURL)
                try (existingContent + content).write(to: fileURL, atomically: true, encoding: .utf8)
            } else {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            
            completion(.success(MCPToolResult(
                content: "Fichier écrit avec succès: \(path)",
                success: true,
                error: nil,
                metadata: ["path": AnyCodable(path)]
            )))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Outil de liste de fichiers
class FileListTool: MCPToolProtocol {
    let name = "file_list"
    let description = "Liste les fichiers dans un répertoire"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du répertoire", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
            let files = contents.map { $0.lastPathComponent }
            let content = files.joined(separator: "\n")
            
            completion(.success(MCPToolResult(
                content: content,
                success: true,
                error: nil,
                metadata: ["path": AnyCodable(path), "count": AnyCodable(files.count)]
            )))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Outil de suppression de fichier
class FileDeleteTool: MCPToolProtocol {
    let name = "file_delete"
    let description = "Supprime un fichier"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            
            completion(.success(MCPToolResult(
                content: "Fichier supprimé: \(path)",
                success: true,
                error: nil,
                metadata: ["path": AnyCodable(path)]
            )))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Outil de date/heure
class DateTimeTool: MCPToolProtocol {
    let name = "datetime"
    let description = "Récupère la date et l'heure actuelles"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "format", type: "string", description: "Format de date (ex: yyyy-MM-dd HH:mm:ss)", required: false, defaultValue: "yyyy-MM-dd HH:mm:ss")
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        let format = arguments["format"] as? String ?? "yyyy-MM-dd HH:mm:ss"
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let dateString = formatter.string(from: Date())
        
        completion(.success(MCPToolResult(
            content: dateString,
            success: true,
            error: nil,
            metadata: ["format": AnyCodable(format)]
        )))
    }
}

/// Outil de calculatrice
class CalculatorTool: MCPToolProtocol {
    let name = "calculator"
    let description = "Effectue un calcul mathématique"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "expression", type: "string", description: "Expression mathématique (ex: 2+2*3)", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let expression = arguments["expression"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        // Utilisation de NSExpression pour évaluer l'expression
        let mathExpression = NSExpression(format: expression)
        
        if let result = mathExpression.expressionValue(with: nil, context: nil) as? NSNumber {
            completion(.success(MCPToolResult(
                content: result.stringValue,
                success: true,
                error: nil,
                metadata: ["expression": AnyCodable(expression)]
            )))
        } else {
            completion(.failure(MCPError.executionFailed))
        }
    }
}

/// Outil d'exécution de code
class CodeExecutionTool: MCPToolProtocol {
    let name = "code_execute"
    let description = "Exécute du code Python ou Swift"
    let parameters: [MCPParameter] = [
        MCPParameter(name: "language", type: "string", description: "Langage (python ou swift)", required: true, defaultValue: "python"),
        MCPParameter(name: "code", type: "string", description: "Code à exécuter", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let language = arguments["language"] as? String,
              let code = arguments["code"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        // Simulation d'exécution de code
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 2.0)
            
            let output: String
            if language.lowercased() == "python" {
                output = "Résultat de l'exécution Python:\n\(code)\n\nSortie: [Résultat simulé]"
            } else {
                output = "Résultat de l'exécution Swift:\n\(code)\n\nSortie: [Résultat simulé]"
            }
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: output,
                    success: true,
                    error: nil,
                    metadata: ["language": AnyCodable(language)]
                )))
            }
        }
    }
}

// MARK: - MCP Integration with Chat

/// Extension pour intégrer MCP avec le chat
extension ChatSession {
    func executeMCPTool(_ toolName: String, arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        MCPClient.shared.executeTool(toolName, arguments: arguments, completion: completion)
    }
    
    func listAvailableTools() -> [MCPToolProtocol] {
        MCPClient.shared.listTools()
    }
}

/// Gestionnaire de contexte pour MCP
class MCPContextManager {
    static let shared = MCPContextManager()
    
    private var context: [String: Any] = [:]
    
    func setValue(_ value: Any, forKey key: String) {
        context[key] = value
    }
    
    func getValue(forKey key: String) -> Any? {
        context[key]
    }
    
    func removeValue(forKey key: String) {
        context.removeValue(forKey: key)
    }
    
    func clearContext() {
        context.removeAll()
    }
    
    func getAllContext() -> [String: Any] {
        context
    }
}
