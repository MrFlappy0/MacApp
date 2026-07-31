import SwiftUI
import Combine

class InferenceViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var progress: Double = 0
    @Published var currentResult: InferenceResult?
    @Published var results: [InferenceResult] = []
    @Published var errorMessage: String?
    @Published var inferenceTime: TimeInterval = 0
    @Published var memoryUsed: Int64 = 0
    @Published var batchProgress: Double = 0
    @Published var currentBatch: Int = 0
    @Published var totalBatches: Int = 0
    
    private let inferenceEngine = InferenceEngine.shared
    private let batchProcessor = BatchProcessor.shared
    private let memoryManager = MemoryManager.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    private var currentTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    func runInference(model: MLXLoadedModel, 
                      input: InferenceInput,
                      settings: AppState.Settings) async {
        
        isRunning = true
        errorMessage = nil
        progress = 0
        
        do {
            let result = try await inferenceEngine.runInference(
                model: model,
                input: input,
                settings: settings
            )
            
            DispatchQueue.main.async {
                self.currentResult = result
                self.results.insert(result, at: 0)
                self.inferenceTime = result.inferenceTime
                self.memoryUsed = result.memoryUsed
                self.isRunning = false
                self.progress = 1.0
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isRunning = false
            }
        }
    }
    
    func runBatchInference(model: MLXLoadedModel, 
                           inputs: [InferenceInput],
                           settings: AppState.Settings) async {
        
        isRunning = true
        errorMessage = nil
        progress = 0
        currentBatch = 0
        
        let recommendations = batchProcessor.getBatchProcessingRecommendations(
            for: model,
            inputCount: inputs.count,
            settings: settings
        )
        
        totalBatches = recommendations.totalBatches
        
        do {
            let results = try await batchProcessor.processBatchWithProgress(
                model: model,
                inputs: inputs,
                settings: settings
            ) { [weak self] progress in
                DispatchQueue.main.async {
                    self?.batchProgress = progress
                    self?.progress = progress
                }
            }
            
            DispatchQueue.main.async {
                self.results.insert(contentsOf: results, at: 0)
                self.isRunning = false
                self.progress = 1.0
                self.batchProgress = 1.0
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isRunning = false
            }
        }
    }
    
    func cancelInference() {
        currentTask?.cancel()
        inferenceEngine.cancelAllInferences()
        isRunning = false
    }
    
    func clearResults() {
        results.removeAll()
        currentResult = nil
    }
    
    func getPerformanceStatistics() -> PerformanceStatistics {
        return performanceMonitor.getStatistics()
    }
    
    func getMemoryReport() -> MemoryReport {
        return memoryManager.getMemoryReport()
    }
    
    func getBatchRecommendations(for model: MLXLoadedModel, 
                                  inputCount: Int,
                                  settings: AppState.Settings) -> BatchRecommendations {
        return batchProcessor.getBatchProcessingRecommendations(
            for: model,
            inputCount: inputCount,
            settings: settings
        )
    }
    
    func validateInput(_ input: InferenceInput, for model: MLXLoadedModel) -> Bool {
        switch model.model.category {
        case .vision:
            if case .image = input.data {
                return true
            }
        case .nlp:
            if case .text = input.data {
                return true
            }
        case .audio:
            if case .audio = input.data {
                return true
            }
        default:
            return true
        }
        
        return false
    }
    
    func createTextInput(_ text: String) -> InferenceInput {
        return InferenceInput(text: text)
    }
    
    func createImageInput(_ imageData: Data) -> InferenceInput {
        return InferenceInput(image: imageData)
    }
    
    func createAudioInput(_ audioData: [Float]) -> InferenceInput {
        return InferenceInput(audio: audioData)
    }
    
    func getInputType(for model: MLXModel) -> InputType {
        switch model.category {
        case .vision: return .image
        case .nlp: return .text
        case .audio: return .audio
        default: return .text
        }
    }
    
    enum InputType {
        case text, image, audio, tensor
    }
}
