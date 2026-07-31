import SwiftUI
import Combine

class ModelViewModel: ObservableObject {
    @Published var models: [MLXModel] = []
    @Published var loadedModels: [MLXLoadedModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: MLXModel.Category?
    @Published var selectedModel: MLXModel?
    @Published var modelConfigs: [String: ModelConfig] = [:]
    
    private let modelLoader = ModelLoader.shared
    private let memoryManager = MemoryManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadModels()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterModels()
            }
            .store(in: &cancellables)
    }
    
    func loadModels() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let builtInModels = MLXModel.builtInModels
            
            DispatchQueue.main.async {
                self?.models = builtInModels
                self?.filterModels()
                self?.isLoading = false
            }
        }
    }
    
    func filterModels() {
        var filtered = models
        
        if !searchText.isEmpty {
            filtered = filtered.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.description.localizedCaseInsensitiveContains(searchText) ||
                model.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        models = filtered
    }
    
    func loadModel(_ model: MLXModel, 
                   device: AppState.Settings.Device = .auto,
                   precision: AppState.Settings.Precision = .float16) async {
        
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedModel = try await modelLoader.loadModel(
                model,
                device: device,
                precision: precision
            )
            
            DispatchQueue.main.async {
                self.loadedModels.append(loadedModel)
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func unloadModel(_ model: MLXLoadedModel) {
        modelLoader.unloadModel(model.model)
        loadedModels.removeAll { $0.model.id == model.model.id }
    }
    
    func unloadAllModels() {
        modelLoader.clearCache()
        loadedModels.removeAll()
    }
    
    func downloadModel(_ model: MLXModel) {
        var updatedModel = model
        updatedModel.isDownloaded = true
        
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            models[index] = updatedModel
        }
        
        modelLoader.downloadModel(model)
    }
    
    func cancelDownload(_ model: MLXModel) {
        modelLoader.cancelDownload(model)
    }
    
    func getModelConfig(for model: MLXModel) -> ModelConfig {
        if let config = modelConfigs[model.name] {
            return config
        }
        
        let config = ModelConfigManager.shared.createDefaultConfig(for: model)
        modelConfigs[model.name] = config
        return config
    }
    
    func saveModelConfig(_ config: ModelConfig) {
        modelConfigs[config.name] = config
        try? ModelConfigManager.shared.saveConfig(config)
    }
    
    func deleteModelConfig(for modelName: String) {
        modelConfigs.removeValue(forKey: modelName)
        try? ModelConfigManager.shared.deleteConfig(for: modelName)
    }
    
    func getAvailableCategories() -> [MLXModel.Category] {
        return MLXModel.Category.allCases
    }
    
    func getModelsByCategory(_ category: MLXModel.Category) -> [MLXModel] {
        return models.filter { $0.category == category }
    }
    
    func getDownloadedModels() -> [MLXModel] {
        return models.filter { $0.isDownloaded }
    }
    
    func getLoadedModel(_ model: MLXModel) -> MLXLoadedModel? {
        return loadedModels.first { $0.model.id == model.id }
    }
    
    func isModelLoaded(_ model: MLXModel) -> Bool {
        return loadedModels.contains { $0.model.id == model.id }
    }
    
    func isModelDownloaded(_ model: MLXModel) -> Bool {
        return model.isDownloaded
    }
    
    func getModelMemoryUsage(_ model: MLXModel) -> Int64? {
        return memoryManager.getModelMemoryUsage(model.name)
    }
    
    func getTotalMemoryUsage() -> Int64 {
        return memoryManager.getCurrentMemoryUsage()
    }
    
    func cleanupUnusedModels() {
        memoryManager.cleanupUnusedModels()
    }
    
    func optimizeMemory() {
        memoryManager.optimizeMemoryUsage()
    }
}
