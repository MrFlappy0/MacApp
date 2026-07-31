import Foundation
import Metal

/// Enumération des modes de recommandation pour les LLM
enum LLMRecommendationMode: String, CaseIterable, Identifiable {
    case smart = "Smart"
    case balanced = "Balanced"
    case powerful = "Powerful"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .smart: return "🧠 Smart (Rapide & Économe)"
        case .balanced: return "⚖️ Équilibré"
        case .powerful: return "💪 Puissant (Max Performances)"
        }
    }
    
    var description: String {
        switch self {
        case .smart:
            return "Modèles légers et optimisés pour une exécution rapide sans surchauffe. Idéal pour un usage quotidien."
        case .balanced:
            return "Compromis parfait entre performance et consommation. Adapté à la plupart des tâches."
        case .powerful:
            return "Modèles les plus performants disponibles sur votre Mac. Pour des tâches complexes nécessitant beaucoup de puissance."
        }
    }
}

/// Structure représentant une recommandation de LLM
struct LLMRecommendation: Identifiable {
    let id = UUID()
    let model: MLXModel
    let mode: LLMRecommendationMode
    let score: Double
    let estimatedMemoryUsage: Int64
    let estimatedSpeed: Double
    let estimatedTemperature: Double
    let reason: String
    
    var formattedMemoryUsage: String {
        let gb = Double(estimatedMemoryUsage) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var formattedSpeed: String {
        return String(format: "%.1f tokens/sec", estimatedSpeed)
    }
    
    var temperatureDescription: String {
        if estimatedTemperature < 30 {
            return "🟢 Frais"
        } else if estimatedTemperature < 50 {
            return "🟡 Tiède"
        } else {
            return "🔴 Chaud"
        }
    }
}

/// Gestionnaire de recommandation de LLM
class LLMRecommender {
    static let shared = LLMRecommender()
    
    private let systemInfo: SystemInfo
    
    private init() {
        self.systemInfo = SystemInfo()
    }
    
    /// Obtient les meilleures recommandations de LLM pour le Mac actuel
    /// - Parameter mode: Le mode de recommandation souhaité
    /// - Returns: Liste de recommandations triées par score
    func getRecommendations(for mode: LLMRecommendationMode) -> [LLMRecommendation] {
        let allModels = getAvailableLLMs()
        
        let recommendations = allModels.compactMap { model -> LLMRecommendation? in
            guard model.category == .nlp else { return nil }
            
            let score = calculateScore(for: model, mode: mode)
            let memoryUsage = estimateMemoryUsage(for: model)
            let speed = estimateSpeed(for: model)
            let temperature = estimateTemperature(for: model, memoryUsage: memoryUsage)
            let reason = generateReason(for: model, mode: mode)
            
            return LLMRecommendation(
                model: model,
                mode: mode,
                score: score,
                estimatedMemoryUsage: memoryUsage,
                estimatedSpeed: speed,
                estimatedTemperature: temperature,
                reason: reason
            )
        }
        
        return recommendations.sorted { $0.score > $1.score }
    }
    
    /// Obtient la meilleure recommandation pour un mode donné
    /// - Parameter mode: Le mode de recommandation souhaité
    /// - Returns: La meilleure recommandation ou nil
    func getBestRecommendation(for mode: LLMRecommendationMode) -> LLMRecommendation? {
        return getRecommendations(for: mode).first
    }
    
    /// Obtient toutes les recommandations pour tous les modes
    /// - Returns: Dictionnaire avec les meilleures recommandations par mode
    func getAllBestRecommendations() -> [LLMRecommendationMode: LLMRecommendation] {
        var result: [LLMRecommendationMode: LLMRecommendation] = [:]
        
        for mode in LLMRecommendationMode.allCases {
            if let best = getBestRecommendation(for: mode) {
                result[mode] = best
            }
        }
        
        return result
    }
    
    /// Calcule le score pour un modèle donné en fonction du mode
    private func calculateScore(for model: MLXModel, mode: LLMRecommendationMode) -> Double {
        let memoryScore = calculateMemoryScore(for: model, mode: mode)
        let speedScore = calculateSpeedScore(for: model, mode: mode)
        let capabilityScore = calculateCapabilityScore(for: model, mode: mode)
        
        switch mode {
        case .smart:
            // Pour le mode smart, on privilégie la mémoire et la vitesse
            return memoryScore * 0.4 + speedScore * 0.4 + capabilityScore * 0.2
        case .balanced:
            // Pour le mode équilibré, on donne un poids égal
            return memoryScore * 0.33 + speedScore * 0.33 + capabilityScore * 0.34
        case .powerful:
            // Pour le mode puissant, on privilégie les capacités
            return memoryScore * 0.2 + speedScore * 0.3 + capabilityScore * 0.5
        }
    }
    
    /// Calcule le score mémoire
    private func calculateMemoryScore(for model: MLXModel, mode: LLMRecommendationMode) -> Double {
        let availableMemory = systemInfo.availableMemory
        let modelMemory = estimateMemoryUsage(for: model)
        let memoryRatio = Double(modelMemory) / Double(availableMemory)
        
        // Plus le ratio est bas, meilleur est le score
        switch mode {
        case .smart:
            // Pour le mode smart, on veut des modèles très légers
            if memoryRatio < 0.1 {
                return 1.0
            } else if memoryRatio < 0.3 {
                return 0.7
            } else if memoryRatio < 0.5 {
                return 0.4
            } else {
                return 0.1
            }
        case .balanced:
            if memoryRatio < 0.2 {
                return 1.0
            } else if memoryRatio < 0.4 {
                return 0.8
            } else if memoryRatio < 0.6 {
                return 0.6
            } else {
                return 0.3
            }
        case .powerful:
            // Pour le mode puissant, on accepte des modèles plus lourds
            if memoryRatio < 0.4 {
                return 1.0
            } else if memoryRatio < 0.6 {
                return 0.8
            } else if memoryRatio < 0.8 {
                return 0.6
            } else {
                return 0.4
            }
        }
    }
    
    /// Calcule le score de vitesse
    private func calculateSpeedScore(for model: MLXModel, mode: LLMRecommendationMode) -> Double {
        let estimatedSpeed = estimateSpeed(for: model)
        
        // Normalisation de la vitesse (plus c'est rapide, meilleur est le score)
        let maxSpeed = 100.0 // tokens/sec
        let normalizedSpeed = min(estimatedSpeed / maxSpeed, 1.0)
        
        switch mode {
        case .smart:
            // Pour le mode smart, la vitesse est très importante
            return normalizedSpeed
        case .balanced:
            return normalizedSpeed * 0.9 + 0.1
        case .powerful:
            // Pour le mode puissant, la vitesse compte mais moins que les capacités
            return normalizedSpeed * 0.8 + 0.2
        }
    }
    
    /// Calcule le score de capacité
    private func calculateCapabilityScore(for model: MLXModel, mode: LLMRecommendationMode) -> Double {
        let parameters = Double(model.parameters)
        
        // Normalisation des paramètres (plus il y a de paramètres, meilleur est le score)
        let maxParameters = 7_000_000_000.0 // 7B
        let normalizedParameters = min(parameters / maxParameters, 1.0)
        
        switch mode {
        case .smart:
            // Pour le mode smart, on veut des modèles légers
            return 1.0 - normalizedParameters * 0.8
        case .balanced:
            return normalizedParameters * 0.7 + 0.3
        case .powerful:
            // Pour le mode puissant, on veut les modèles les plus capables
            return normalizedParameters
        }
    }
    
    /// Estime l'utilisation mémoire pour un modèle
    private func estimateMemoryUsage(for model: MLXModel) -> Int64 {
        // Estimation basée sur les paramètres et la précision
        let baseMemory = model.parameters * 4 // 4 bytes par paramètre en float32
        
        // Ajustement basé sur la précision
        let precisionFactor: Double
        switch AppState.shared.settings.precision {
        case .float32: precisionFactor = 1.0
        case .float16: precisionFactor = 0.5
        case .int8: precisionFactor = 0.25
        }
        
        // Ajustement basé sur le périphérique
        let deviceFactor: Double
        switch AppState.shared.settings.device {
        case .cpu: deviceFactor = 1.0
        case .gpu: deviceFactor = 1.2
        case .mps: deviceFactor = 1.1
        case .auto: deviceFactor = 1.1
        }
        
        let estimatedMemory = Int64(Double(baseMemory) * precisionFactor * deviceFactor)
        
        // Ajouter une marge de sécurité
        return estimatedMemory * 2
    }
    
    /// Estime la vitesse d'inférence
    private func estimateSpeed(for model: MLXModel) -> Double {
        let parameters = Double(model.parameters)
        
        // Vitesse de base basée sur le périphérique
        let baseSpeed: Double
        switch AppState.shared.settings.device {
        case .cpu: baseSpeed = 5.0
        case .gpu: baseSpeed = 20.0
        case .mps: baseSpeed = 30.0
        case .auto: baseSpeed = 25.0
        }
        
        // Ajustement basé sur la taille du modèle
        let sizeFactor = max(1.0 - (parameters / 10_000_000_000.0), 0.1)
        
        // Ajustement basé sur la précision
        let precisionFactor: Double
        switch AppState.shared.settings.precision {
        case .float32: precisionFactor = 1.0
        case .float16: precisionFactor = 1.5
        case .int8: precisionFactor = 2.0
        }
        
        return baseSpeed * sizeFactor * precisionFactor
    }
    
    /// Estime la température (chaleur générée)
    private func estimateTemperature(for model: MLXModel, memoryUsage: Int64) -> Double {
        let availableMemory = systemInfo.availableMemory
        let memoryRatio = Double(memoryUsage) / Double(availableMemory)
        
        let parameters = Double(model.parameters)
        let parameterFactor = min(parameters / 1_000_000_000.0, 1.0) // Normalisé à 1B
        
        // Estimation de la température basée sur l'utilisation mémoire et la taille du modèle
        let temperature = memoryRatio * 40 + parameterFactor * 30
        
        return min(temperature, 100)
    }
    
    /// Génère une raison pour la recommandation
    private func generateReason(for model: MLXModel, mode: LLMRecommendationMode) -> String {
        let memoryUsage = estimateMemoryUsage(for: model)
        let availableMemory = systemInfo.availableMemory
        let memoryRatio = Double(memoryUsage) / Double(availableMemory)
        
        let speed = estimateSpeed(for: model)
        let parameters = model.parameters
        
        switch mode {
        case .smart:
            if memoryRatio < 0.2 && speed > 20 {
                return "Modèle léger avec une bonne vitesse d'inférence. Parfait pour un usage quotidien sans surchauffe."
            } else if memoryRatio < 0.3 {
                return "Bon compromis entre taille et performance. Utilisation mémoire modérée."
            } else {
                return "Modèle un peu lourd pour le mode smart, mais reste gérable."
            }
        case .balanced:
            if memoryRatio > 0.3 && memoryRatio < 0.6 && parameters > 1_000_000_000 {
                return "Excellent équilibre entre capacité et consommation. Idéal pour la plupart des tâches."
            } else if memoryRatio < 0.3 {
                return "Modèle léger avec une bonne marge pour d'autres tâches."
            } else {
                return "Modèle puissant mais nécessite une bonne quantité de mémoire."
            }
        case .powerful:
            if parameters > 5_000_000_000 {
                return "Modèle très puissant avec des milliards de paramètres. Pour des tâches complexes."
            } else if parameters > 1_000_000_000 {
                return "Modèle performant avec un bon nombre de paramètres. Capable de gérer des tâches avancées."
            } else {
                return "Modèle capable mais pourrait être plus puissant. Considérer des modèles plus grands si possible."
            }
        }
    }
    
    /// Obtient la liste des LLM disponibles
    private func getAvailableLLMs() -> [MLXModel] {
        // Filtrer les modèles NLP (LLM) depuis les modèles intégrés
        return MLXModel.builtInModels.filter { $0.category == .nlp }
    }
    
    /// Obtient les informations système
    private func getSystemInfo() -> SystemInfo {
        return systemInfo
    }
}

/// Structure pour stocker les informations système
struct SystemInfo {
    let totalMemory: Int64
    let availableMemory: Int64
    let cpuCores: Int
    let cpuType: String
    let gpuName: String
    let isAppleSilicon: Bool
    let macOSVersion: String
    
    init() {
        // Obtenir la mémoire totale
        self.totalMemory = ProcessInfo.processInfo.physicalMemory
        
        // Estimer la mémoire disponible (simplification)
        self.availableMemory = Int64(Double(totalMemory) * 0.7)
        
        // Obtenir le nombre de cœurs CPU
        self.cpuCores = ProcessInfo.processInfo.processorCount
        
        // Obtenir le type de CPU
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        self.cpuType = String(cString: machine)
        
        // Vérifier si c'est Apple Silicon
        #if arch(arm64)
        self.isAppleSilicon = true
        self.gpuName = "Apple GPU (MPS)"
        #else
        self.isAppleSilicon = false
        self.gpuName = "Intel GPU"
        #endif
        
        // Obtenir la version de macOS
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        self.macOSVersion = "\(osVersion.major).\(osVersion.minor).\(osVersion.patch)"
    }
    
    var formattedTotalMemory: String {
        let gb = Double(totalMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
    
    var formattedAvailableMemory: String {
        let gb = Double(availableMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f Go", gb)
    }
}

/// Extension pour ajouter des méthodes utilitaires à AppState
extension AppState {
    func getLLMRecommendations(for mode: LLMRecommendationMode) -> [LLMRecommendation] {
        return LLMRecommender.shared.getRecommendations(for: mode)
    }
    
    func getBestLLMRecommendation(for mode: LLMRecommendationMode) -> LLMRecommendation? {
        return LLMRecommender.shared.getBestRecommendation(for: mode)
    }
    
    func getAllBestLLMRecommendations() -> [LLMRecommendationMode: LLMRecommendation] {
        return LLMRecommender.shared.getAllBestRecommendations()
    }
}
