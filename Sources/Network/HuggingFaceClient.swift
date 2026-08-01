import Foundation

/// Client pour interagir avec Hugging Face Hub
class HuggingFaceClient {
    static let shared = HuggingFaceClient()
    
    private let baseURL = "https://huggingface.co/api"
    private let session = URLSession.shared
    private var accessToken: String?
    
    /// Configure le token d'accès Hugging Face
    func configure(accessToken: String) {
        self.accessToken = accessToken
    }
    
    /// Recherche des modèles sur Hugging Face
    func searchModels(query: String, filter: String? = nil, limit: Int = 10, completion: @escaping (Result<[HuggingFaceModel], Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/models")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let filter = filter {
            queryItems.append(URLQueryItem(name: "filter", value: filter))
        }
        
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode([HuggingFaceModel].self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Récupère les informations d'un modèle spécifique
    func getModelInfo(modelId: String, completion: @escaping (Result<HuggingFaceModel, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(modelId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let model = try decoder.decode(HuggingFaceModel.self, from: data)
                completion(.success(model))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Télécharge un modèle depuis Hugging Face
    func downloadModel(modelId: String, destinationURL: URL, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        let url = URL(string: "https://huggingface.co/\(modelId)/resolve/main")!
        
        var request = URLRequest(url: url)
        
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let downloadTask = session.downloadTask(with: request) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                // Copier le fichier temporaire vers la destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        // Observer la progression
        downloadTask.addObserver(forKeyPath: "countOfBytesReceived", options: .new, context: nil) { task, _ in
            if let downloadTask = task as? URLSessionDownloadTask,
               let totalBytes = downloadTask.countOfBytesExpectedToReceive,
               totalBytes > 0 {
                let receivedBytes = downloadTask.countOfBytesReceived
                let progressValue = Double(receivedBytes) / Double(totalBytes)
                DispatchQueue.main.async {
                    progress(progressValue)
                }
            }
        }
        
        downloadTask.resume()
    }
    
    /// Liste les fichiers d'un modèle
    func listModelFiles(modelId: String, completion: @escaping (Result<[HuggingFaceFile], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(modelId)/tree/main")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode([HuggingFaceFile].self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// MARK: - Modèles de données

struct HuggingFaceModel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let author: String?
    let tags: [String]?
    let likes: Int?
    let downloads: Int?
    let lastModified: String?
    let privateModel: Bool?
    let pipelineTag: String?
    let libraryName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, author, tags, likes, downloads, lastModified, privateModel, pipelineTag, libraryName = "library_name"
    }
    
    var displayName: String {
        name.isEmpty ? id : name
    }
    
    var formattedDownloads: String {
        guard let downloads = downloads else { return "0" }
        if downloads >= 1_000_000 {
            return String(format: "%.1fM", Double(downloads) / 1_000_000)
        } else if downloads >= 1_000 {
            return String(format: "%.1fK", Double(downloads) / 1_000)
        } else {
            return String(downloads)
        }
    }
}

struct HuggingFaceFile: Identifiable, Codable {
    let path: String
    let size: Int64?
    let lfs: Bool?
    
    var id: String { path }
    
    var filename: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
    
    var fileExtension: String {
        URL(fileURLWithPath: path).pathExtension
    }
    
    var formattedSize: String {
        guard let size = size else { return "Unknown" }
        let bytes = Double(size)
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.2f MB", bytes / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.2f KB", bytes / 1024)
        } else {
            return "\(size) B"
        }
    }
}

// MARK: - Erreurs

enum NetworkError: Error {
    case noData
    case invalidURL
    case authenticationFailed
    case rateLimited
    case notFound
    
    var localizedDescription: String {
        switch self {
        case .noData: return "Aucune donnée reçue"
        case .invalidURL: return "URL invalide"
        case .authenticationFailed: return "Échec de l'authentification"
        case .rateLimited: return "Trop de requêtes. Veuillez réessayer plus tard."
        case .notFound: return "Ressource non trouvée"
        }
    }
}
