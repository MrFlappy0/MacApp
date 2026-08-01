import Foundation

/// Client MCP pour gérer les outils et serveurs
class MCPClient {
    static let shared = MCPClient()
    
    private var tools: [MCPTool] = []
    private var servers: [MCPServerConfig] = []
    
    private init() {
        registerBuiltInTools()
    }
    
    // MARK: - Tool Management
    
    func registerTool(_ tool: MCPTool) {
        tools.append(tool)
    }
    
    func unregisterTool(_ name: String) {
        tools.removeAll { $0.name == name }
    }
    
    func getTool(_ name: String) -> MCPTool? {
        tools.first { $0.name == name }
    }
    
    func listTools() -> [MCPTool] {
        tools
    }
    
    func executeTool(_ name: String, arguments: [String: String], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let tool = tools.first(where: { $0.name == name }) else {
            completion(.failure(MCPError.toolNotFound))
            return
        }
        
        // Simuler l'exécution de l'outil
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 0.5)
            
            let result = MCPToolResult(
                content: "Résultat de l'outil \(name): [Contenu simulé]",
                success: true,
                error: nil
            )
            
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
    
    // MARK: - Server Management
    
    func addServer(_ server: MCPServerConfig) {
        servers.append(server)
    }
    
    func removeServer(_ server: MCPServerConfig) {
        servers.removeAll { $0.id == server.id }
    }
    
    func listServers() -> [MCPServerConfig] {
        servers
    }
    
    // MARK: - Built-in Tools
    
    private func registerBuiltInTools() {
        // Outils web
        registerTool(MCPTool(
            name: "web_search",
            description: "Effectue une recherche sur le web",
            category: "web",
            parameters: [
                MCPTool.MCPParameter(name: "query", type: "string", description: "Requête de recherche", required: true, defaultValue: nil),
                MCPTool.MCPParameter(name: "max_results", type: "integer", description: "Nombre maximum de résultats", required: false, defaultValue: "5")
            ]
        ))
        
        registerTool(MCPTool(
            name: "web_fetch",
            description: "Récupère le contenu d'une URL",
            category: "web",
            parameters: [
                MCPTool.MCPParameter(name: "url", type: "string", description: "URL à récupérer", required: true, defaultValue: nil)
            ]
        ))
        
        // Outils de fichiers
        registerTool(MCPTool(
            name: "file_read",
            description: "Lit le contenu d'un fichier",
            category: "file",
            parameters: [
                MCPTool.MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil)
            ]
        ))
        
        registerTool(MCPTool(
            name: "file_write",
            description: "Écrit du contenu dans un fichier",
            category: "file",
            parameters: [
                MCPTool.MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil),
                MCPTool.MCPParameter(name: "content", type: "string", description: "Contenu à écrire", required: true, defaultValue: nil)
            ]
        ))
        
        registerTool(MCPTool(
            name: "file_list",
            description: "Liste les fichiers dans un répertoire",
            category: "file",
            parameters: [
                MCPTool.MCPParameter(name: "path", type: "string", description: "Chemin du répertoire", required: true, defaultValue: nil)
            ]
        ))
        
        // Outils système
        registerTool(MCPTool(
            name: "datetime",
            description: "Récupère la date et l'heure actuelles",
            category: "system",
            parameters: [
                MCPTool.MCPParameter(name: "format", type: "string", description: "Format de date", required: false, defaultValue: "yyyy-MM-dd HH:mm:ss")
            ]
        ))
        
        registerTool(MCPTool(
            name: "calculator",
            description: "Effectue des calculs mathématiques",
            category: "calculator",
            parameters: [
                MCPTool.MCPParameter(name: "expression", type: "string", description: "Expression mathématique", required: true, defaultValue: nil)
            ]
        ))
        
        // Outils de code
        registerTool(MCPTool(
            name: "python_execute",
            description: "Exécute du code Python",
            category: "code",
            parameters: [
                MCPTool.MCPParameter(name: "code", type: "string", description: "Code Python", required: true, defaultValue: nil)
            ]
        ))
        
        registerTool(MCPTool(
            name: "swift_execute",
            description: "Exécute du code Swift",
            category: "code",
            parameters: [
                MCPTool.MCPParameter(name: "code", type: "string", description: "Code Swift", required: true, defaultValue: nil)
            ]
        ))
    }
}

/// Registry pour tous les outils MCP
class MCPToolRegistry {
    static let shared = MCPToolRegistry()
    
    func listAllTools() -> [MCPTool] {
        MCPClient.shared.listTools()
    }
}

// MARK: - Modèles de données

struct MCPTool: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let parameters: [MCPParameter]
    
    init(id: String = UUID().uuidString, name: String, description: String, category: String, parameters: [MCPParameter]) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.parameters = parameters
    }
    
    struct MCPParameter: Codable {
        let name: String
        let type: String
        let description: String
        let required: Bool
        let defaultValue: String?
    }
}

struct MCPToolResult: Codable {
    let content: String
    let success: Bool
    let error: String?
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

// MARK: - Erreurs

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
