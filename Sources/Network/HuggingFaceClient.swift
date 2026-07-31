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
    /// - Parameters:
    ///   - query: Terme de recherche
    ///   - filter: Filtre (ex: "text-generation", "chat")
    ///   - limit: Nombre de résultats
    ///   - completion: Callback avec les résultats ou une erreur
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
        
        if let token = accessToken {
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
    /// - Parameters:
    ///   - modelId: ID du modèle (ex: "mistralai/Mistral-7B-v0.1")
    ///   - completion: Callback avec les informations du modèle ou une erreur
    func getModelInfo(modelId: String, completion: @escaping (Result<HuggingFaceModel, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(modelId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = accessToken {
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
    /// - Parameters:
    ///   - modelId: ID du modèle
    ///   - destinationURL: URL de destination
    ///   - progress: Callback de progression
    ///   - completion: Callback de fin
    func downloadModel(modelId: String, destinationURL: URL, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        let url = URL(string: "https://huggingface.co/\(modelId)/resolve/main")!
        
        var request = URLRequest(url: url)
        
        if let token = accessToken {
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
    
    /// Télécharge un fichier spécifique d'un modèle
    /// - Parameters:
    ///   - modelId: ID du modèle
    ///   - filePath: Chemin du fichier dans le dépôt
    ///   - destinationURL: URL de destination
    ///   - progress: Callback de progression
    ///   - completion: Callback de fin
    func downloadFile(from modelId: String, filePath: String, to destinationURL: URL, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        let url = URL(string: "https://huggingface.co/\(modelId)/resolve/main/\(filePath)")!
        
        var request = URLRequest(url: url)
        
        if let token = accessToken {
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
                try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        
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
    /// - Parameters:
    ///   - modelId: ID du modèle
    ///   - completion: Callback avec la liste des fichiers ou une erreur
    func listModelFiles(modelId: String, completion: @escaping (Result<[HuggingFaceFile], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/models/\(modelId)/tree/main")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = accessToken {
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

/// Modèle de données pour un modèle Hugging Face
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

/// Modèle de données pour un fichier dans un dépôt Hugging Face
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

/// Erreurs réseau
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

/// Client pour l'inférence locale avec MLX
class MLXInferenceClient {
    static let shared = MLXInferenceClient()
    
    private let modelLoader = MLXModelLoader()
    private var loadedModels: [String: MLXLoadedModel] = [:]
    
    /// Charge un modèle
    func loadModel(_ model: LLModel, completion: @escaping (Result<MLXLoadedModel, Error>) -> Void) {
        guard let localPath = model.localPath else {
            completion(.failure(InferenceError.modelNotDownloaded))
            return
        }
        
        modelLoader.loadModel(from: URL(fileURLWithPath: localPath)) { result in
            switch result {
            case .success(let loadedModel):
                self.loadedModels[model.id] = loadedModel
                completion(.success(loadedModel))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Exécute une inférence
    func generateText(
        modelId: String,
        prompt: String,
        config: ModelConfig,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let model = loadedModels[modelId] else {
            completion(.failure(InferenceError.modelNotLoaded))
            return
        }
        
        model.generateText(prompt: prompt, config: config) { result in
            completion(result)
        }
    }
    
    /// Exécute une inférence en streaming
    func generateTextStream(
        modelId: String,
        prompt: String,
        config: ModelConfig,
        onToken: @escaping (String) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let model = loadedModels[modelId] else {
            completion(.failure(InferenceError.modelNotLoaded))
            return
        }
        
        model.generateTextStream(prompt: prompt, config: config) { result in
            switch result {
            case .success(let token):
                onToken(token)
            case .failure(let error):
                completion(.failure(error))
            }
        } onComplete: { result in
            completion(result)
        }
    }
    
    /// Décharge un modèle
    func unloadModel(_ modelId: String) {
        if let model = loadedModels[modelId] {
            modelLoader.unloadModel(model)
            loadedModels.removeValue(forKey: modelId)
        }
    }
    
    /// Décharge tous les modèles
    func unloadAllModels() {
        for (_, model) in loadedModels {
            modelLoader.unloadModel(model)
        }
        loadedModels.removeAll()
    }
    
    /// Vérifie si un modèle est chargé
    func isModelLoaded(_ modelId: String) -> Bool {
        loadedModels[modelId] != nil
    }
}

/// Erreurs d'inférence
enum InferenceError: Error {
    case modelNotDownloaded
    case modelNotLoaded
    case invalidInput
    case outOfMemory
    case timeout
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .modelNotDownloaded: return "Le modèle n'est pas téléchargé"
        case .modelNotLoaded: return "Le modèle n'est pas chargé en mémoire"
        case .invalidInput: return "Entrée invalide"
        case .outOfMemory: return "Mémoire insuffisante"
        case .timeout: return "Temps d'exécution dépassé"
        case .unknownError: return "Erreur inconnue"
        }
    }
}

/// Protocole pour le chargement des modèles MLX
protocol MLXModelLoaderProtocol {
    func loadModel(from url: URL, completion: @escaping (Result<MLXLoadedModel, Error>) -> Void)
    func unloadModel(_ model: MLXLoadedModel)
}

/// Implémentation par défaut du chargeur de modèles
class MLXModelLoader: MLXModelLoaderProtocol {
    func loadModel(from url: URL, completion: @escaping (Result<MLXLoadedModel, Error>) -> Void) {
        // Implémentation avec MLX
        // Cela serait remplacé par l'intégration réelle avec MLX
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulation du chargement
            Thread.sleep(forTimeInterval: 2.0)
            
            let model = MLXLoadedModel(url: url, memoryUsage: 4_000_000_000) // 4 Go
            DispatchQueue.main.async {
                completion(.success(model))
            }
        }
    }
    
    func unloadModel(_ model: MLXLoadedModel) {
        // Libérer la mémoire
        model.cleanup()
    }
}

/// Modèle chargé en mémoire
class MLXLoadedModel {
    let url: URL
    let memoryUsage: Int64
    private var isLoaded: Bool = true
    
    init(url: URL, memoryUsage: Int64) {
        self.url = url
        self.memoryUsage = memoryUsage
    }
    
    func generateText(prompt: String, config: ModelConfig, completion: @escaping (Result<String, Error>) -> Void) {
        // Implémentation avec MLX
        // Simulation
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.0)
            let response = "Ceci est une réponse générée par \(config.description) avec température \(config.temperature)."
            DispatchQueue.main.async {
                completion(.success(response))
            }
        }
    }
    
    func generateTextStream(prompt: String, config: ModelConfig, onToken: @escaping (Result<String, Error>) -> Void, onComplete: @escaping (Result<Void, Error>) -> Void) {
        // Implémentation avec MLX en streaming
        let response = "Ceci est une réponse en streaming générée par le modèle."
        let tokens = response.map { String($0) }
        
        DispatchQueue.global(qos: .userInitiated).async {
            for token in tokens {
                Thread.sleep(forTimeInterval: 0.05)
                DispatchQueue.main.async {
                    onToken(.success(token))
                }
            }
            DispatchQueue.main.async {
                onComplete(.success(()))
            }
        }
    }
    
    func cleanup() {
        isLoaded = false
        // Libérer les ressources MLX
    }
}
