import Foundation

struct ModelConfig: Codable {
    var name: String
    var version: String
    var description: String
    var author: String
    var license: String
    var category: MLXModel.Category
    var parameters: Int64
    var fileSize: Int64
    var inputShape: [Int]
    var outputShape: [Int]
    var supportedDevices: [MLXModel.Device]
    var precision: AppState.Settings.Precision
    var device: AppState.Settings.Device
    var optimizationLevel: ModelMetadata.OptimizationLevel
    var batchSize: Int
    var enableCaching: Bool
    var maxMemoryUsage: Int64
    var timeout: TimeInterval
    var warmupRuns: Int
    var customSettings: [String: String]
    
    init(model: MLXModel) {
        self.name = model.name
        self.version = model.version
        self.description = model.description
        self.author = model.author
        self.license = model.license
        self.category = model.category
        self.parameters = model.parameters
        self.fileSize = model.fileSize
        self.inputShape = model.inputShape
        self.outputShape = model.outputShape
        self.supportedDevices = model.supportedDevices
        self.precision = .float16
        self.device = .auto
        self.optimizationLevel = .basic
        self.batchSize = 1
        self.enableCaching = true
        self.maxMemoryUsage = 0
        self.timeout = 30.0
        self.warmupRuns = 0
        self.customSettings = [:]
    }
    
    static func `default`() -> ModelConfig {
        ModelConfig(model: MLXModel.builtInModels[0])
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "version": version,
            "description": description,
            "author": author,
            "license": license,
            "category": category.rawValue,
            "parameters": parameters,
            "fileSize": fileSize,
            "inputShape": inputShape,
            "outputShape": outputShape,
            "supportedDevices": supportedDevices.map { $0.rawValue },
            "precision": precision.rawValue,
            "device": device.rawValue,
            "optimizationLevel": optimizationLevel.rawValue,
            "batchSize": batchSize,
            "enableCaching": enableCaching,
            "maxMemoryUsage": maxMemoryUsage,
            "timeout": timeout,
            "warmupRuns": warmupRuns,
            "customSettings": customSettings
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> ModelConfig? {
        guard let name = dict["name"] as? String else { return nil }
        
        let config = ModelConfig(
            name: name,
            version: dict["version"] as? String ?? "1.0.0",
            description: dict["description"] as? String ?? "",
            author: dict["author"] as? String ?? "Unknown",
            license: dict["license"] as? String ?? "MIT",
            category: MLXModel.Category(rawValue: dict["category"] as? String ?? "vision") ?? .vision,
            parameters: dict["parameters"] as? Int64 ?? 0,
            fileSize: dict["fileSize"] as? Int64 ?? 0,
            inputShape: dict["inputShape"] as? [Int] ?? [1, 224, 224],
            outputShape: dict["outputShape"] as? [Int] ?? [1000],
            supportedDevices: (dict["supportedDevices"] as? [String] ?? []).compactMap { 
                MLXModel.Device(rawValue: $0) 
            },
            precision: AppState.Settings.Precision(rawValue: dict["precision"] as? String ?? "float16") ?? .float16,
            device: AppState.Settings.Device(rawValue: dict["device"] as? String ?? "auto") ?? .auto,
            optimizationLevel: ModelMetadata.OptimizationLevel(rawValue: dict["optimizationLevel"] as? String ?? "basic") ?? .basic,
            batchSize: dict["batchSize"] as? Int ?? 1,
            enableCaching: dict["enableCaching"] as? Bool ?? true,
            maxMemoryUsage: dict["maxMemoryUsage"] as? Int64 ?? 0,
            timeout: dict["timeout"] as? TimeInterval ?? 30.0,
            warmupRuns: dict["warmupRuns"] as? Int ?? 0,
            customSettings: dict["customSettings"] as? [String: String] ?? [:]
        )
        
        return config
    }
}

class ModelConfigManager {
    static let shared = ModelConfigManager()
    
    private let configsDirectory: URL
    private var cachedConfigs: [String: ModelConfig] = [:]
    
    private init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        configsDirectory = documentsURL.appendingPathComponent("ModelConfigs")
        
        createConfigsDirectoryIfNeeded()
    }
    
    private func createConfigsDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: configsDirectory.path) {
            try? fileManager.createDirectory(at: configsDirectory, 
                                            withIntermediateDirectories: true)
        }
    }
    
    func saveConfig(_ config: ModelConfig) throws {
        let configURL = configsDirectory.appendingPathComponent("\(config.name).json")
        let data = try JSONEncoder().encode(config)
        try data.write(to: configURL)
        cachedConfigs[config.name] = config
    }
    
    func loadConfig(for modelName: String) -> ModelConfig? {
        if let cached = cachedConfigs[modelName] {
            return cached
        }
        
        let configURL = configsDirectory.appendingPathComponent("\(modelName).json")
        
        guard let data = try? Data(contentsOf: configURL) else {
            return nil
        }
        
        let config = try? JSONDecoder().decode(ModelConfig.self, from: data)
        
        if let config = config {
            cachedConfigs[modelName] = config
        }
        
        return config
    }
    
    func deleteConfig(for modelName: String) throws {
        let configURL = configsDirectory.appendingPathComponent("\(modelName).json")
        try FileManager.default.removeItem(at: configURL)
        cachedConfigs.removeValue(forKey: modelName)
    }
    
    func listAllConfigs() -> [ModelConfig] {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(at: configsDirectory, 
                                                             includingPropertiesForKeys: nil) else {
            return []
        }
        
        var configs: [ModelConfig] = []
        
        for file in files {
            if file.pathExtension == "json" {
                let modelName = file.deletingPathExtension().lastPathComponent
                if let config = loadConfig(for: modelName) {
                    configs.append(config)
                }
            }
        }
        
        return configs
    }
    
    func createDefaultConfig(for model: MLXModel) -> ModelConfig {
        let config = ModelConfig(model: model)
        return config
    }
    
    func updateConfig(_ config: ModelConfig, with updates: (inout ModelConfig) -> Void) -> ModelConfig {
        var updatedConfig = config
        updates(&updatedConfig)
        return updatedConfig
    }
}

struct ModelConfigPreset {
    let name: String
    let description: String
    let config: ModelConfig
    
    static let presets: [ModelConfigPreset] = [
        ModelConfigPreset(
            name: "High Performance",
            description: "Optimized for maximum speed",
            config: {
                var config = ModelConfig.default()
                config.precision = .float16
                config.device = .mps
                config.optimizationLevel = .advanced
                config.batchSize = 4
                config.enableCaching = true
                return config
            }()
        ),
        ModelConfigPreset(
            name: "Memory Efficient",
            description: "Optimized for low memory usage",
            config: {
                var config = ModelConfig.default()
                config.precision = .int8
                config.device = .cpu
                config.optimizationLevel = .extreme
                config.batchSize = 1
                config.enableCaching = false
                return config
            }()
        ),
        ModelConfigPreset(
            name: "Balanced",
            description: "Balanced performance and memory usage",
            config: {
                var config = ModelConfig.default()
                config.precision = .float16
                config.device = .auto
                config.optimizationLevel = .basic
                config.batchSize = 2
                config.enableCaching = true
                return config
            }()
        ),
        ModelConfigPreset(
            name: "High Precision",
            description: "Maximum precision for accurate results",
            config: {
                var config = ModelConfig.default()
                config.precision = .float32
                config.device = .mps
                config.optimizationLevel = .none
                config.batchSize = 1
                config.enableCaching = true
                return config
            }()
        )
    ]
}
