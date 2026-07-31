import Foundation

class BatchProcessor {
    static let shared = BatchProcessor()
    
    private let inferenceEngine = InferenceEngine.shared
    private let memoryManager = MemoryManager.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    private let batchQueue = DispatchQueue(label: "com.mlxmacapp.batch", 
                                          qos: .userInitiated,
                                          attributes: .concurrent)
    
    private init() {}
    
    func processBatch(model: MLXLoadedModel, 
                      inputs: [InferenceInput],
                      settings: AppState.Settings) async throws -> [InferenceResult] {
        
        let batchSize = min(settings.batchSize, inputs.count)
        var allResults: [InferenceResult] = []
        
        performanceMonitor.startTracking(task: .batchProcessing)
        
        defer {
            performanceMonitor.stopTracking(task: .batchProcessing)
        }
        
        for batchStart in stride(from: 0, to: inputs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, inputs.count)
            let batchInputs = Array(inputs[batchStart..<batchEnd])
            
            let batchResults = try await processSingleBatch(
                model: model,
                inputs: batchInputs,
                settings: settings
            )
            
            allResults.append(contentsOf: batchResults)
            
            if settings.optimizeMemory {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        
        return allResults
    }
    
    private func processSingleBatch(model: MLXLoadedModel, 
                                    inputs: [InferenceInput],
                                    settings: AppState.Settings) async throws -> [InferenceResult] {
        
        var results: [InferenceResult] = []
        
        try await withThrowingTaskGroup(of: InferenceResult.self) { group in
            for input in inputs {
                group.addTask {
                    try await self.inferenceEngine.runInference(
                        model: model,
                        input: input,
                        settings: settings
                    )
                }
            }
            
            for try await result in group {
                results.append(result)
            }
        }
        
        return results
    }
    
    func processBatchWithProgress(model: MLXLoadedModel, 
                                   inputs: [InferenceInput],
                                   settings: AppState.Settings,
                                   progressHandler: @escaping (Double) -> Void) async throws -> [InferenceResult] {
        
        let totalCount = inputs.count
        var processedCount = 0
        var allResults: [InferenceResult] = []
        
        let batchSize = min(settings.batchSize, inputs.count)
        
        for batchStart in stride(from: 0, to: inputs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, inputs.count)
            let batchInputs = Array(inputs[batchStart..<batchEnd])
            
            let batchResults = try await processSingleBatch(
                model: model,
                inputs: batchInputs,
                settings: settings
            )
            
            allResults.append(contentsOf: batchResults)
            processedCount += batchResults.count
            
            let progress = Double(processedCount) / Double(totalCount)
            progressHandler(progress)
        }
        
        return allResults
    }
    
    func estimateBatchProcessingTime(model: MLXLoadedModel, 
                                     inputCount: Int,
                                     settings: AppState.Settings) -> TimeInterval {
        
        let avgInferenceTime: TimeInterval = 0.1
        let batchSize = min(settings.batchSize, inputCount)
        let batchCount = Int(ceil(Double(inputCount) / Double(batchSize)))
        
        let estimatedTime = TimeInterval(batchCount) * avgInferenceTime * TimeInterval(batchSize)
        
        return estimatedTime
    }
    
    func validateBatchSize(_ size: Int, for model: MLXLoadedModel) -> Int {
        let maxBatchSize = calculateMaxBatchSize(for: model)
        return min(size, maxBatchSize)
    }
    
    private func calculateMaxBatchSize(for model: MLXLoadedModel) -> Int {
        let availableMemory = memoryManager.getAvailableMemory()
        let modelMemory = model.memoryUsage
        
        let memoryPerInstance: Int64 = modelMemory * 2
        
        guard memoryPerInstance > 0 else { return 1 }
        
        let maxInstances = availableMemory / memoryPerInstance
        
        return max(1, min(Int(maxInstances), 32))
    }
    
    func getBatchProcessingRecommendations(for model: MLXLoadedModel, 
                                            inputCount: Int,
                                            settings: AppState.Settings) -> BatchRecommendations {
        
        let maxBatchSize = calculateMaxBatchSize(for: model)
        let recommendedBatchSize = min(maxBatchSize, settings.batchSize)
        
        let estimatedTime = estimateBatchProcessingTime(
            model: model,
            inputCount: inputCount,
            settings: settings
        )
        
        let memoryPerBatch = model.memoryUsage * Int64(recommendedBatchSize)
        let availableMemory = memoryManager.getAvailableMemory()
        let memoryUsagePercentage = Double(memoryPerBatch) / Double(availableMemory) * 100.0
        
        return BatchRecommendations(
            maxBatchSize: maxBatchSize,
            recommendedBatchSize: recommendedBatchSize,
            estimatedProcessingTime: estimatedTime,
            estimatedMemoryUsage: memoryPerBatch,
            memoryUsagePercentage: memoryUsagePercentage,
            totalBatches: Int(ceil(Double(inputCount) / Double(recommendedBatchSize)))
        )
    }
}

struct BatchRecommendations {
    let maxBatchSize: Int
    let recommendedBatchSize: Int
    let estimatedProcessingTime: TimeInterval
    let estimatedMemoryUsage: Int64
    let memoryUsagePercentage: Double
    let totalBatches: Int
    
    var formattedEstimatedTime: String {
        if estimatedProcessingTime < 60 {
            return String(format: "%.1f seconds", estimatedProcessingTime)
        } else {
            let minutes = Int(estimatedProcessingTime) / 60
            let seconds = Int(estimatedProcessingTime) % 60
            return String(format: "%d:%02d minutes", minutes, seconds)
        }
    }
    
    var formattedMemoryUsage: String {
        let mb = Double(estimatedMemoryUsage) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    var formattedMemoryPercentage: String {
        String(format: "%.1f%%", memoryUsagePercentage)
    }
}
