import Foundation
import SwiftUI

/// Outils MCP supplémentaires pour l'application de chat

// MARK: - Outils de recherche et d'accès web

/// Outil pour rechercher des informations sur le web
class WebSearchTool: MCPToolProtocol {
    let name = "web_search"
    let description = "Effectue une recherche sur le web et retourne les résultats"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "query", type: "string", description: "Requête de recherche", required: true, defaultValue: nil),
        MCPParameter(name: "max_results", type: "integer", description: "Nombre maximum de résultats (1-10)", required: false, defaultValue: 5),
        MCPParameter(name: "language", type: "string", description: "Langue des résultats (ex: fr, en)", required: false, defaultValue: "fr")
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let query = arguments["query"] as? String, !query.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let maxResults = min(arguments["max_results"] as? Int ?? 5, 10)
        let language = arguments["language"] as? String ?? "fr"
        
        // Simulation de recherche web
        DispatchQueue.global(qos: .userInitiated).async {
            // Simuler un délai de recherche
            Thread.sleep(forTimeInterval: 1.0)
            
            // Générer des résultats simulés
            let results = (1...maxResults).map { index in
                """
                Résultat \(index): \(query)
                
                URL: https://example.com/result\(index)
                Description: Voici une description pertinente pour votre recherche sur '\(query)'.
                Ce résultat contient des informations utiles et fiables.
                """
            }
            
            let content = results.joined(separator: "\n---\n")
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: "Recherche web pour: \"\(query)\"\n\n\(content)",
                    success: true,
                    error: nil,
                    metadata: [
                        "query": AnyCodable(query),
                        "max_results": AnyCodable(maxResults),
                        "language": AnyCodable(language),
                        "results_count": AnyCodable(results.count)
                    ]
                )))
            }
        }
    }
}

/// Outil pour récupérer le contenu d'une URL
class WebFetchTool: MCPToolProtocol {
    let name = "web_fetch"
    let description = "Récupère et extrait le contenu textuel d'une URL"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "url", type: "string", description: "URL à récupérer", required: true, defaultValue: nil),
        MCPParameter(name: "extract", type: "string", description: "Type d'extraction (text, html, markdown)", required: false, defaultValue: "text"),
        MCPParameter(name: "max_length", type: "integer", description: "Longueur maximale du contenu (en caractères)", required: false, defaultValue: 10000)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let urlString = arguments["url"] as? String, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let extractType = arguments["extract"] as? String ?? "text"
        let maxLength = arguments["max_length"] as? Int ?? 10000
        
        // Simulation de récupération web
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.5)
            
            // Générer un contenu simulé
            let content = """
            Contenu récupéré depuis: \(urlString)
            
            Titre: Exemple de page web
            
            Corps:
            Ceci est un exemple de contenu de page web. Dans une implémentation réelle,
            cet outil récupérerait le contenu actuel de l'URL spécifiée et l'extraierait
            selon le format demandé (\(extractType)).
            
            Le contenu est limité à \(maxLength) caractères.
            
            Pour des raisons de sécurité, seules les URLs HTTPS sont autorisées.
            """
            
            let truncatedContent = String(content.prefix(maxLength))
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: truncatedContent,
                    success: true,
                    error: nil,
                    metadata: [
                        "url": AnyCodable(urlString),
                        "extract_type": AnyCodable(extractType),
                        "content_length": AnyCodable(truncatedContent.count)
                    ]
                )))
            }
        }
    }
}

// MARK: - Outils de gestion de fichiers

/// Outil pour lister les fichiers dans un répertoire
class FileListTool: MCPToolProtocol {
    let name = "file_list"
    let description = "Liste les fichiers et dossiers dans un répertoire"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du répertoire", required: true, defaultValue: nil),
        MCPParameter(name: "recursive", type: "boolean", description: "Lister récursivement", required: false, defaultValue: false),
        MCPParameter(name: "filter", type: "string", description: "Filtre par extension (ex: .txt, .pdf)", required: false, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String, !path.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let recursive = arguments["recursive"] as? Bool ?? false
        let filter = arguments["filter"] as? String
        
        let fileURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        do {
            var files: [URL] = []
            
            if recursive {
                let enumerator = fileManager.enumerator(at: fileURL, includingPropertiesForKeys: nil)
                while let url = enumerator?.nextObject() as? URL {
                    files.append(url)
                }
            } else {
                files = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
            }
            
            // Appliquer le filtre
            let filteredFiles = files.filter { url in
                if let filter = filter {
                    return url.pathExtension == filter.replacingOccurrences(of: ".", with: "")
                }
                return true
            }
            
            // Formater les résultats
            let results = filteredFiles.map { url in
                let relativePath = url.path.replacingOccurrences(of: path, with: "")
                let fileInfo = FileInfo(
                    name: url.lastPathComponent,
                    path: relativePath,
                    isDirectory: url.hasDirectoryPath,
                    size: url.fileSize,
                    extension: url.pathExtension,
                    modifiedDate: getModificationDate(url)
                )
                return fileInfo.description
            }.joined(separator: "\n")
            
            completion(.success(MCPToolResult(
                content: "Fichiers dans \(path):\n\n\(results)",
                success: true,
                error: nil,
                metadata: [
                    "path": AnyCodable(path),
                    "file_count": AnyCodable(filteredFiles.count),
                    "recursive": AnyCodable(recursive)
                ]
            )))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func getModificationDate(_ url: URL) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}

/// Outil pour lire un fichier
class FileReadTool: MCPToolProtocol {
    let name = "file_read"
    let description = "Lit le contenu d'un fichier"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil),
        MCPParameter(name: "max_length", type: "integer", description: "Longueur maximale à lire (en caractères)", required: false, defaultValue: 100000),
        MCPParameter(name: "encoding", type: "string", description: "Encodage du fichier", required: false, defaultValue: "utf8")
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String, !path.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let maxLength = arguments["max_length"] as? Int ?? 100000
        let encodingName = arguments["encoding"] as? String ?? "utf8"
        
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            let encoding = CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings[encodingName.lowercased()] ?? 0)
            )
            
            let content = try String(contentsOf: fileURL, encoding: String.Encoding(rawValue: encoding))
            let truncatedContent = String(content.prefix(maxLength))
            
            completion(.success(MCPToolResult(
                content: "Contenu de \(path):\n\n\(truncatedContent)",
                success: true,
                error: nil,
                metadata: [
                    "path": AnyCodable(path),
                    "content_length": AnyCodable(truncatedContent.count),
                    "encoding": AnyCodable(encodingName)
                ]
            )))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Outil pour écrire dans un fichier
class FileWriteTool: MCPToolProtocol {
    let name = "file_write"
    let description = "Écrit du contenu dans un fichier"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du fichier", required: true, defaultValue: nil),
        MCPParameter(name: "content", type: "string", description: "Contenu à écrire", required: true, defaultValue: nil),
        MCPParameter(name: "append", type: "boolean", description: "Ajouter au fichier existant", required: false, defaultValue: false),
        MCPParameter(name: "encoding", type: "string", description: "Encodage du fichier", required: false, defaultValue: "utf8")
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String, !path.isEmpty,
              let content = arguments["content"] as? String else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let append = arguments["append"] as? Bool ?? false
        let encodingName = arguments["encoding"] as? String ?? "utf8"
        
        let fileURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        do {
            // Créer le répertoire parent si nécessaire
            let parentDirectory = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parentDirectory.path) {
                try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            }
            
            let encoding = CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings[encodingName.lowercased()] ?? 0)
            )
            
            if append, fileManager.fileExists(atPath: path) {
                let existingContent = try String(contentsOf: fileURL, encoding: String.Encoding(rawValue: encoding))
                try (existingContent + content).write(to: fileURL, atomically: true, encoding: String.Encoding(rawValue: encoding))
            } else {
                try content.write(to: fileURL, atomically: true, encoding: String.Encoding(rawValue: encoding))
            }
            
            completion(.success(MCPToolResult(
                content: "Fichier écrit avec succès: \(path)",
                success: true,
                error: nil,
                metadata: [
                    "path": AnyCodable(path),
                    "content_length": AnyCodable(content.count),
                    "append": AnyCodable(append)
                ]
            )))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Outil pour supprimer un fichier
class FileDeleteTool: MCPToolProtocol {
    let name = "file_delete"
    let description = "Supprime un fichier ou un dossier"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "path", type: "string", description: "Chemin du fichier ou dossier", required: true, defaultValue: nil),
        MCPParameter(name: "recursive", type: "boolean", description: "Supprimer récursivement (pour les dossiers)", required: false, defaultValue: false)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let path = arguments["path"] as? String, !path.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let recursive = arguments["recursive"] as? Bool ?? false
        let fileURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: path) {
                if fileURL.hasDirectoryPath && recursive {
                    try fileManager.removeItem(at: fileURL)
                } else if !fileURL.hasDirectoryPath {
                    try fileManager.removeItem(at: fileURL)
                } else {
                    throw MCPError.executionFailed
                }
                
                completion(.success(MCPToolResult(
                    content: "Supprimé avec succès: \(path)",
                    success: true,
                    error: nil,
                    metadata: [
                        "path": AnyCodable(path),
                        "recursive": AnyCodable(recursive)
                    ]
                )))
            } else {
                completion(.failure(MCPError.executionFailed))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Outils système

/// Outil pour obtenir la date et l'heure
class DateTimeTool: MCPToolProtocol {
    let name = "datetime"
    let description = "Récupère la date et l'heure actuelles"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "format", type: "string", description: "Format de date (ex: yyyy-MM-dd HH:mm:ss)", required: false, defaultValue: "yyyy-MM-dd HH:mm:ss"),
        MCPParameter(name: "timezone", type: "string", description: "Fuseau horaire (ex: Europe/Paris)", required: false, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        let format = arguments["format"] as? String ?? "yyyy-MM-dd HH:mm:ss"
        let timezoneName = arguments["timezone"] as? String
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        if let timezoneName = timezoneName, let timezone = TimeZone(identifier: timezoneName) {
            formatter.timeZone = timezone
        }
        
        let dateString = formatter.string(from: Date())
        
        completion(.success(MCPToolResult(
            content: dateString,
            success: true,
            error: nil,
            metadata: [
                "format": AnyCodable(format),
                "timestamp": AnyCodable(Date().timeIntervalSince1970)
            ]
        )))
    }
}

/// Outil calculatrice
class CalculatorTool: MCPToolProtocol {
    let name = "calculator"
    let description = "Effectue des calculs mathématiques"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "expression", type: "string", description: "Expression mathématique (ex: 2+2*3, sqrt(16), sin(PI/2))", required: true, defaultValue: nil),
        MCPParameter(name: "precision", type: "integer", description: "Nombre de décimales", required: false, defaultValue: 4)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let expression = arguments["expression"] as? String, !expression.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let precision = arguments["precision"] as? Int ?? 4
        
        // Remplacer les fonctions mathématiques
        let processedExpression = expression
            .replacingOccurrences(of: "PI", with: "3.141592653589793")
            .replacingOccurrences(of: "E", with: "2.718281828459045")
        
        // Utiliser NSExpression pour évaluer
        let mathExpression = NSExpression(format: processedExpression)
        
        do {
            if let result = mathExpression.expressionValue(with: nil, context: nil) as? NSNumber {
                let formattedResult = String(format: "%.\(precision)f", result.doubleValue)
                
                completion(.success(MCPToolResult(
                    content: "Résultat: \(formattedResult)",
                    success: true,
                    error: nil,
                    metadata: [
                        "expression": AnyCodable(expression),
                        "result": AnyCodable(result.doubleValue),
                        "precision": AnyCodable(precision)
                    ]
                )))
            } else {
                completion(.failure(MCPError.executionFailed))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Outils de code

/// Outil pour exécuter du code Python
class PythonExecutionTool: MCPToolProtocol {
    let name = "python_execute"
    let description = "Exécute du code Python"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "code", type: "string", description: "Code Python à exécuter", required: true, defaultValue: nil),
        MCPParameter(name: "timeout", type: "integer", description: "Timeout en secondes", required: false, defaultValue: 10)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let code = arguments["code"] as? String, !code.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let timeout = arguments["timeout"] as? Int ?? 10
        
        // Simulation d'exécution Python
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Générer une sortie simulée
            let output = """
            Exécution Python:
            
            Code:
            \(code)
            
            Sortie:
            [Résultat simulé de l'exécution Python]
            
            Note: Dans une implémentation réelle, cela exécuterait le code Python
            dans un environnement sécurisé et isolé.
            """
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: output,
                    success: true,
                    error: nil,
                    metadata: [
                        "code_length": AnyCodable(code.count),
                        "timeout": AnyCodable(timeout)
                    ]
                )))
            }
        }
    }
}

/// Outil pour exécuter du code Swift
class SwiftExecutionTool: MCPToolProtocol {
    let name = "swift_execute"
    let description = "Exécute du code Swift"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "code", type: "string", description: "Code Swift à exécuter", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let code = arguments["code"] as? String, !code.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        // Simulation d'exécution Swift
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.0)
            
            let output = """
            Exécution Swift:
            
            Code:
            \(code)
            
            Sortie:
            [Résultat simulé de l'exécution Swift]
            
            Note: Dans une implémentation réelle, cela compilerait et exécuterait
            le code Swift dans un environnement sécurisé.
            """
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: output,
                    success: true,
                    error: nil,
                    metadata: [
                        "code_length": AnyCodable(code.count)
                    ]
                )))
            }
        }
    }
}

// MARK: - Outils de données

/// Outil pour générer des données JSON
class JSONGenerateTool: MCPToolProtocol {
    let name = "json_generate"
    let description = "Génère des données structurées au format JSON"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "schema", type: "string", description: "Schéma JSON (ex: {\"name\": \"string\", \"age\": \"number\"})", required: true, defaultValue: nil),
        MCPParameter(name: "count", type: "integer", description: "Nombre d'objets à générer", required: false, defaultValue: 1)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let schema = arguments["schema"] as? String, !schema.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        let count = arguments["count"] as? Int ?? 1
        
        // Simulation de génération JSON
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 0.5)
            
            // Générer des données simulées
            var jsonData: [String: Any] = [:]
            
            if let data = try? JSONSerialization.jsonObject(with: schema.data(using: .utf8)!) as? [String: Any] {
                for key in data.keys {
                    jsonData[key] = generateSampleValue(for: data[key])
                }
            }
            
            // Si count > 1, créer un tableau
            var finalResult: Any = jsonData
            if count > 1 {
                finalResult = (1...count).map { _ in jsonData }
            }
            
            let jsonString = stringFromJSON(finalResult)
            
            DispatchQueue.main.async {
                completion(.success(MCPToolResult(
                    content: jsonString,
                    success: true,
                    error: nil,
                    metadata: [
                        "schema": AnyCodable(schema),
                        "count": AnyCodable(count)
                    ]
                )))
            }
        }
    }
    
    private func generateSampleValue(for type: Any?) -> Any {
        if let typeString = type as? String {
            switch typeString.lowercased() {
            case "string": return "Exemple de texte"
            case "number", "integer": return Int.random(in: 1...100)
            case "boolean": return Bool.random()
            case "array": return [1, 2, 3]
            case "object": return ["clé": "valeur"]
            default: return "valeur"
            }
        }
        return "valeur"
    }
    
    private func stringFromJSON(_ object: Any) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }
}

/// Outil pour analyser des données JSON
class JSONAnalyzeTool: MCPToolProtocol {
    let name = "json_analyze"
    let description = "Analyse des données JSON et retourne des statistiques"
    
    let parameters: [MCPParameter] = [
        MCPParameter(name: "json", type: "string", description: "Données JSON à analyser", required: true, defaultValue: nil)
    ]
    
    func execute(arguments: [String: Any], completion: @escaping (Result<MCPToolResult, Error>) -> Void) {
        guard let jsonString = arguments["json"] as? String, !jsonString.isEmpty else {
            completion(.failure(MCPError.invalidArguments))
            return
        }
        
        do {
            let jsonData = jsonString.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            let analysis = analyzeJSON(jsonObject)
            
            completion(.success(MCPToolResult(
                content: analysis,
                success: true,
                error: nil,
                metadata: [
                    "json_length": AnyCodable(jsonString.count)
                ]
            )))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func analyzeJSON(_ object: Any) -> String {
        var result = "Analyse JSON:\n\n"
        
        if let dict = object as? [String: Any] {
            result += "Type: Objet\n"
            result += "Nombre de clés: \(dict.keys.count)\n"
            result += "Clés: \(Array(dict.keys).joined(separator: ", "))\n"
        } else if let array = object as? [Any] {
            result += "Type: Tableau\n"
            result += "Nombre d'éléments: \(array.count)\n"
        } else if let string = object as? String {
            result += "Type: Chaîne de caractères\n"
            result += "Longueur: \(string.count)\n"
        } else if let number = object as? NSNumber {
            result += "Type: Nombre\n"
            result += "Valeur: \(number)\n"
        } else if object is NSNull {
            result += "Type: Null\n"
        }
        
        return result
    }
}

// MARK: - Structures de support

/// Informations sur un fichier
struct FileInfo {
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let `extension`: String
    let modifiedDate: Date?
    
    var description: String {
        var desc = ""
        desc += "Nom: \(name)\n"
        desc += "Chemin: \(path)\n"
        desc += "Type: \(isDirectory ? "Dossier" : "Fichier")\n"
        desc += "Taille: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))\n"
        if let date = modifiedDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            desc += "Modifié: \(formatter.string(from: date))\n"
        }
        return desc
    }
}

/// Mappage des encodages
private let CFStringEncodings: [String: CFStringEncoding] = [
    "utf8": .UTF8,
    "utf16": .UTF16,
    "utf16le": .UTF16LE,
    "utf16be": .UTF16BE,
    "utf32": .UTF32,
    "utf32le": .UTF32LE,
    "utf32be": .UTF32BE,
    "ascii": .ASCII,
    "latin1": .ISOLatin1,
    "windows1252": .WindowsLatin1
]

/// Extension pour enregistrer tous les outils
class MCPToolRegistry {
    static let shared = MCPToolRegistry()
    
    private var registeredTools: [String: MCPToolProtocol.Type] = [:]
    
    func registerTool(_ toolType: MCPToolProtocol.Type) {
        let tool = toolType.init()
        registeredTools[tool.name] = toolType
        MCPClient.shared.registerTool(tool)
    }
    
    func registerAllTools() {
        // Outils web
        registerTool(WebSearchTool.self)
        registerTool(WebFetchTool.self)
        
        // Outils de fichiers
        registerTool(FileListTool.self)
        registerTool(FileReadTool.self)
        registerTool(FileWriteTool.self)
        registerTool(FileDeleteTool.self)
        
        // Outils système
        registerTool(DateTimeTool.self)
        registerTool(CalculatorTool.self)
        
        // Outils de code
        registerTool(PythonExecutionTool.self)
        registerTool(SwiftExecutionTool.self)
        
        // Outils de données
        registerTool(JSONGenerateTool.self)
        registerTool(JSONAnalyzeTool.self)
    }
}
