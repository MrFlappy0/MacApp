import Foundation
import Metal

/// Gestionnaire d'intégration avec MLX 2.0
class MLXIntegration {
    static let shared = MLXIntegration()
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var loadedModels: [String: MLXModelWrapper] = [:]
    private var memoryManager = MLXMemoryManager()
    
    private init() {
        setupMetal()
    }
    
    // MARK: - Setup
    
    private func setupMetal() {
        #if os(macOS)
        device = MTLCreateSystemDefaultDevice()
        if let device = device {
            commandQueue = device.makeCommandQueue()
            print("Metal device: \(device.name)")
        }
        #endif
    }
    
    // MARK: - Model Loading
    
    /// Charge un modèle depuis un chemin local
    func loadModel(from path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let modelId = UUID().uuidString
        
        // Vérifier la mémoire disponible
        do {
            try memoryManager.checkMemoryAvailable()
        } catch {
            completion(.failure(error))
            return
        }
        
        // Charger le modèle (simulation pour l'instant)
        let model = MLXModelWrapper(
            id: modelId,
            path: path,
            device: device,
            commandQueue: commandQueue
        )
        
        loadedModels[modelId] = model
        memoryManager.registerModel(model)
        
        completion(.success(()))
    }
    
    /// Décharge un modèle
    func unloadModel(_ modelId: String) {
        if let model = loadedModels[modelId] {
            model.cleanup()
            memoryManager.unregisterModel(model)
            loadedModels.removeValue(forKey: modelId)
        }
    }
    
    /// Décharge tous les modèles
    func unloadAllModels() {
        for (_, model) in loadedModels {
            model.cleanup()
            memoryManager.unregisterModel(model)
        }
        loadedModels.removeAll()
    }
    
    /// Vérifie si un modèle est chargé
    func isModelLoaded(_ modelId: String) -> Bool {
        loadedModels[modelId] != nil
    }
    
    // MARK: - Inference
    
    /// Exécute une inférence
    func generateText(
        modelId: String,
        prompt: String,
        config: ModelConfig,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let model = loadedModels[modelId] else {
            completion(.failure(MLXError.modelNotLoaded))
            return
        }
        
        model.generateText(prompt: prompt, config: config, completion: completion)
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
            completion(.failure(MLXError.modelNotLoaded))
            return
        }
        
        model.generateTextStream(prompt: prompt, config: config, onToken: onToken, completion: completion)
    }
    
    // MARK: - Memory Management
    
    func getMemoryUsage() -> MLXMemoryInfo {
        memoryManager.getMemoryInfo()
    }
    
    func optimizeMemory() {
        memoryManager.optimizeMemory()
    }
    
    func cleanupUnusedModels() {
        memoryManager.cleanupUnusedModels()
    }
}

/// Wrapper pour un modèle MLX
class MLXModelWrapper {
    let id: String
    let path: String
    let device: MTLDevice?
    let commandQueue: MTLCommandQueue?
    
    private var isLoaded: Bool = true
    private var memoryUsage: Int64 = 0
    
    init(id: String, path: String, device: MTLDevice?, commandQueue: MTLCommandQueue?) {
        self.id = id
        self.path = path
        self.device = device
        self.commandQueue = commandQueue
        
        // Estimer l'utilisation mémoire
        self.memoryUsage = estimateMemoryUsage()
    }
    
    private func estimateMemoryUsage() -> Int64 {
        // Estimation basée sur la taille du fichier
        // En réalité, cela dépendrait du modèle chargé
        return 4_000_000_000 // 4 Go par défaut
    }
    
    /// Génère du texte
    func generateText(prompt: String, config: ModelConfig, completion: @escaping (Result<String, Error>) -> Void) {
        // Simulation de l'inférence
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Générer une réponse simulée
            let responses = [
                "Voici une réponse générée avec température \(config.temperature).",
                "Je comprends votre question. Voici une réponse détaillée et utile.",
                "D'après mon analyse, voici ce que je peux vous dire...",
                "Intéressante question ! Voici ma réponse basée sur les informations disponibles."
            ]
            
            let response = responses.randomElement() ?? "Réponse du modèle."
            
            DispatchQueue.main.async {
                completion(.success(response))
            }
        }
    }
    
    /// Génère du texte en streaming
    func generateTextStream(prompt: String, config: ModelConfig, onToken: @escaping (String) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        // Simulation de streaming
        DispatchQueue.global(qos: .userInitiated).async {
            let response = "Voici une réponse en streaming générée avec température \(config.temperature)."
            let tokens = response.map { String($0) }
            
            for token in tokens {
                Thread.sleep(forTimeInterval: 0.05)
                DispatchQueue.main.async {
                    onToken(token)
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
    
    /// Nettoie les ressources
    func cleanup() {
        isLoaded = false
        // Libérer les ressources Metal
    }
    
    /// Obtient l'utilisation mémoire
    func getMemoryUsage() -> Int64 {
        memoryUsage
    }
}

/// Gestionnaire de mémoire pour MLX
class MLXMemoryManager {
    private var registeredModels: [String: MLXModelWrapper] = [:]
    private var totalAllocated: Int64 = 0
    private var peakMemory: Int64 = 0
    
    private let warningThreshold: Int64 = 8 * 1024 * 1024 * 1024 // 8 Go
    private let criticalThreshold: Int64 = 12 * 1024 * 1024 * 1024 // 12 Go
    
    func registerModel(_ model: MLXModelWrapper) {
        registeredModels[model.id] = model
        totalAllocated += model.getMemoryUsage()
        updatePeakMemory()
    }
    
    func unregisterModel(_ model: MLXModelWrapper) {
        if let key = registeredModels.first(where: { $0.value.id == model.id })?.key {
            totalAllocated -= model.getMemoryUsage()
            registeredModels.removeValue(forKey: key)
        }
    }
    
    func getMemoryInfo() -> MLXMemoryInfo {
        MLXMemoryInfo(
            totalAllocated: totalAllocated,
            peakMemory: peakMemory,
            availableMemory: getAvailableMemory(),
            totalSystemMemory: getTotalSystemMemory()
        )
    }
    
    func checkMemoryAvailable() throws {
        let available = getAvailableMemory()
        if available < 2 * 1024 * 1024 * 1024 { // Moins de 2 Go disponibles
            throw MLXError.insufficientMemory
        }
    }
    
    func optimizeMemory() {
        // Décharger les modèles les moins utilisés
        let sortedModels = registeredModels.sorted { $0.value.getMemoryUsage() < $1.value.getMemoryUsage() }
        
        var modelsToUnload: [String] = []
        var currentUsage = totalAllocated
        
        for (_, model) in sortedModels {
            if currentUsage < warningThreshold {
                break
            }
            modelsToUnload.append(model.id)
            currentUsage -= model.getMemoryUsage()
        }
        
        for modelId in modelsToUnload {
            if let model = registeredModels[modelId] {
                unregisterModel(model)
            }
        }
    }
    
    func cleanupUnusedModels() {
        // Nettoyer les modèles non utilisés depuis longtemps
    }
    
    private func updatePeakMemory() {
        peakMemory = max(peakMemory, totalAllocated)
    }
    
    private func getAvailableMemory() -> Int64 {
        #if os(macOS)
        var size: vm_size_t = 0
        var address: vm_address_t = 0
        var count: mach_msg_type_number_t = 0
        var object_name: vm_region_basic_info_data_64_t = vm_region_basic_info_data_64_t()
        var object_count = mach_msg_type_number_t(MemoryLayout<vm_region_basic_info_data_64_t>.stride / MemoryLayout<integer_t>.stride)
        
        var result = vm_region_64(
            vm_map_t(mach_task_self_),
            &address,
            &size,
            VM_REGION_BASIC_INFO_64,
            &object_name,
            &object_count,
            &count
        )
        
        var freeMemory: Int64 = 0
        while result == KERN_SUCCESS {
            if object_name.protection == VM_PROT_NONE {
                freeMemory += Int64(size)
            }
            address += size
            result = vm_region_64(
                vm_map_t(mach_task_self_),
                &address,
                &size,
                VM_REGION_BASIC_INFO_64,
                &object_name,
                &object_count,
                &count
            )
        }
        
        return freeMemory
        #else
        return 0
        #endif
    }
    
    private func getTotalSystemMemory() -> Int64 {
        #if os(macOS)
        return Int64(ProcessInfo.processInfo.physicalMemory)
        #else
        return 0
        #endif
    }
}

/// Informations sur la mémoire
struct MLXMemoryInfo {
    let totalAllocated: Int64
    let peakMemory: Int64
    let availableMemory: Int64
    let totalSystemMemory: Int64
    
    var formattedTotalAllocated: String {
        let gb = Double(totalAllocated) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var formattedPeakMemory: String {
        let gb = Double(peakMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var formattedAvailableMemory: String {
        let gb = Double(availableMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var formattedTotalSystemMemory: String {
        let gb = Double(totalSystemMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var usagePercentage: Double {
        guard totalSystemMemory > 0 else { return 0 }
        return Double(totalAllocated) / Double(totalSystemMemory) * 100.0
    }
    
    var formattedUsagePercentage: String {
        String(format: "%.1f%%", usagePercentage)
    }
}

/// Erreurs MLX
enum MLXError: Error {
    case modelNotLoaded
    case modelNotFound
    case insufficientMemory
    case deviceNotAvailable
    case inferenceFailed
    case invalidInput
    
    var localizedDescription: String {
        switch self {
        case .modelNotLoaded: return "Le modèle n'est pas chargé"
        case .modelNotFound: return "Modèle non trouvé"
        case .insufficientMemory: return "Mémoire insuffisante"
        case .deviceNotAvailable: return "Périphérique non disponible"
        case .inferenceFailed: return "Échec de l'inférence"
        case .invalidInput: return "Entrée invalide"
        }
    }
}
