import Foundation
import Metal
import MetalKit
import Accelerate

class ModelLoader {
    static let shared = ModelLoader()
    
    private let memoryManager = MemoryManager.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    private var modelCache: [String: MLXLoadedModel] = [:]
    private var downloadTasks: [URL: URLSessionDownloadTask] = [:]
    private let downloadQueue = DispatchQueue(label: "com.mlxmacapp.downloads", qos: .background)
    
    private init() {}
    
    func loadModel(_ model: MLXModel, 
                   device: AppState.Settings.Device = .auto,
                   precision: AppState.Settings.Precision = .float16,
                   optimizationLevel: ModelMetadata.OptimizationLevel = .basic) async throws -> MLXLoadedModel {
        
        let cacheKey = "\(model.name)_\(device.rawValue)_\(precision.rawValue)_\(optimizationLevel.rawValue)"
        
        if let cachedModel = modelCache[cacheKey] {
            return cachedModel
        }
        
        guard let localPath = model.localPath ?? downloadModel(model).localPath else {
            throw ModelError.modelNotFound
        }
        
        performanceMonitor.startTracking(task: .modelLoading)
        
        do {
            let loadedModel = try await loadModelFromPath(localPath, 
                                                         model: model,
                                                         device: device,
                                                         precision: precision,
                                                         optimizationLevel: optimizationLevel)
            
            modelCache[cacheKey] = loadedModel
            memoryManager.registerModel(loadedModel, key: cacheKey)
            
            performanceMonitor.stopTracking(task: .modelLoading)
            
            return loadedModel
        } catch {
            performanceMonitor.stopTracking(task: .modelLoading)
            throw error
        }
    }
    
    func unloadModel(_ model: MLXModel, 
                     device: AppState.Settings.Device = .auto,
                     precision: AppState.Settings.Precision = .float16,
                     optimizationLevel: ModelMetadata.OptimizationLevel = .basic) {
        let cacheKey = "\(model.name)_\(device.rawValue)_\(precision.rawValue)_\(optimizationLevel.rawValue)"
        
        if let loadedModel = modelCache[cacheKey] {
            memoryManager.unregisterModel(loadedModel, key: cacheKey)
            modelCache.removeValue(forKey: cacheKey)
        }
    }
    
    func clearCache() {
        modelCache.values.forEach { model in
            memoryManager.unregisterModel(model, key: "")
        }
        modelCache.removeAll()
    }
    
    @discardableResult
    func downloadModel(_ model: MLXModel) -> MLXModel {
        guard !model.isDownloaded, let url = model.localPath ?? createLocalPath(for: model) else {
            return model
        }
        
        var updatedModel = model
        
        if downloadTasks[url] != nil {
            return updatedModel
        }
        
        let session = URLSession(configuration: .default)
        let task = session.downloadTask(with: model.url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            defer {
                self.downloadTasks.removeValue(forKey: url)
            }
            
            if let error = error {
                print("Download failed: \(error.localizedDescription)")
                return
            }
            
            guard let tempURL = tempURL else {
                print("No temporary URL")
                return
            }
            
            do {
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                }
                
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), 
                                               withIntermediateDirectories: true)
                try fileManager.moveItem(at: tempURL, to: url)
                
                DispatchQueue.main.async {
                    var model = model
                    model.isDownloaded = true
                    model.localPath = url
                    model.lastUsed = Date()
                    
                    self.saveModelMetadata(model)
                }
            } catch {
                print("Failed to save model: \(error.localizedDescription)")
            }
        }
        
        downloadTasks[url] = task
        task.resume()
        
        return updatedModel
    }
    
    func cancelDownload(_ model: MLXModel) {
        guard let url = model.localPath else { return }
        
        if let task = downloadTasks[url] {
            task.cancel()
            downloadTasks.removeValue(forKey: url)
        }
    }
    
    private func createLocalPath(for model: MLXModel) -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        return documentsURL?.appendingPathComponent("Models").appendingPathComponent("\(model.name).mlx")
    }
    
    private func loadModelFromPath(_ path: URL, 
                                  model: MLXModel,
                                  device: AppState.Settings.Device,
                                  precision: AppState.Settings.Precision,
                                  optimizationLevel: ModelMetadata.OptimizationLevel) async throws -> MLXLoadedModel {
        
        let startTime = Date()
        
        let deviceType = mapDevice(device)
        let precisionType = mapPrecision(precision)
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as? Int64 ?? 0
        
        let layers = try await loadLayers(from: path, 
                                         model: model,
                                         device: deviceType,
                                         precision: precisionType,
                                         optimizationLevel: optimizationLevel)
        
        let loadTime = Date().timeIntervalSince(startTime)
        
        return MLXLoadedModel(
            model: model,
            layers: layers,
            device: deviceType,
            precision: precisionType,
            optimizationLevel: optimizationLevel,
            fileSize: fileSize,
            loadTime: loadTime,
            memoryUsage: estimateMemoryUsage(layers: layers, model: model)
        )
    }
    
    private func loadLayers(from path: URL, 
                           model: MLXModel,
                           device: DeviceType,
                           precision: PrecisionType,
                           optimizationLevel: ModelMetadata.OptimizationLevel) async throws -> [MLXLayer] {
        
        let data = try Data(contentsOf: path)
        
        var layers: [MLXLayer] = []
        
        switch model.category {
        case .vision:
            layers = createVisionLayers(data: data, model: model, device: device, precision: precision)
        case .nlp:
            layers = createNLPLayers(data: data, model: model, device: device, precision: precision)
        case .audio:
            layers = createAudioLayers(data: data, model: model, device: device, precision: precision)
        case .diffusion:
            layers = createDiffusionLayers(data: data, model: model, device: device, precision: precision)
        default:
            layers = createGenericLayers(data: data, model: model, device: device, precision: precision)
        }
        
        return applyOptimizations(layers: layers, level: optimizationLevel)
    }
    
    private func createVisionLayers(data: Data, model: MLXModel, device: DeviceType, precision: PrecisionType) -> [MLXLayer] {
        var layers: [MLXLayer] = []
        
        layers.append(MLXLayer(
            name: "Input",
            type: .input,
            inputShape: model.inputShape,
            outputShape: model.inputShape,
            parameters: 0,
            device: device,
            precision: precision
        ))
        
        layers.append(MLXLayer(
            name: "Conv1",
            type: .convolution,
            inputShape: model.inputShape,
            outputShape: [64, 112, 112],
            parameters: 9408,
            device: device,
            precision: precision
        ))
        
        for i in 1...5 {
            layers.append(MLXLayer(
                name: "ResBlock_\(i)",
                type: .residual,
                inputShape: [64 * (1 << (i-1)), 112 >> (i-1), 112 >> (i-1)],
                outputShape: [64 * (1 << i), 112 >> i, 112 >> i],
                parameters: 100000 * i,
                device: device,
                precision: precision
            ))
        }
        
        layers.append(MLXLayer(
            name: "GlobalAvgPool",
            type: .pooling,
            inputShape: [64 * 32, 7, 7],
            outputShape: [64 * 32],
            parameters: 0,
            device: device,
            precision: precision
        ))
        
        layers.append(MLXLayer(
            name: "Output",
            type: .dense,
            inputShape: [64 * 32],
            outputShape: model.outputShape,
            parameters: Int64(model.outputShape.reduce(1, *) * (64 * 32)),
            device: device,
            precision: precision
        ))
        
        return layers
    }
    
    private func createNLPLayers(data: Data, model: MLXModel, device: DeviceType, precision: PrecisionType) -> [MLXLayer] {
        var layers: [MLXLayer] = []
        
        layers.append(MLXLayer(
            name: "TokenEmbedding",
            type: .embedding,
            inputShape: model.inputShape,
            outputShape: [model.inputShape[0], 768],
            parameters: 50000 * 768,
            device: device,
            precision: precision
        ))
        
        for i in 1...12 {
            layers.append(MLXLayer(
                name: "TransformerBlock_\(i)",
                type: .transformer,
                inputShape: [model.inputShape[0], 768],
                outputShape: [model.inputShape[0], 768],
                parameters: 4_500_000,
                device: device,
                precision: precision
            ))
        }
        
        layers.append(MLXLayer(
            name: "Output",
            type: .dense,
            inputShape: [model.inputShape[0], 768],
            outputShape: model.outputShape,
            parameters: Int64(model.outputShape.reduce(1, *) * 768),
            device: device,
            precision: precision
        ))
        
        return layers
    }
    
    private func createAudioLayers(data: Data, model: MLXModel, device: DeviceType, precision: PrecisionType) -> [MLXLayer] {
        var layers: [MLXLayer] = []
        
        layers.append(MLXLayer(
            name: "AudioInput",
            type: .input,
            inputShape: model.inputShape,
            outputShape: model.inputShape,
            parameters: 0,
            device: device,
            precision: precision
        ))
        
        layers.append(MLXLayer(
            name: "Conv1D_1",
            type: .convolution,
            inputShape: model.inputShape,
            outputShape: [512, model.inputShape[1], model.inputShape[2]],
            parameters: 100000,
            device: device,
            precision: precision
        ))
        
        layers.append(MLXLayer(
            name: "Transformer_1",
            type: .transformer,
            inputShape: [512, model.inputShape[1]],
            outputShape: [512, model.inputShape[1]],
            parameters: 2_000_000,
            device: device,
            precision: precision
        ))
        
        layers.append(MLXLayer(
            name: "Output",
            type: .dense,
            inputShape: [512],
            outputShape: model.outputShape,
            parameters: Int64(model.outputShape.reduce(1, *) * 512),
            device: device,
            precision: precision
        ))
        
        return layers
    }
    
    private func createDiffusionLayers(data: Data, model: MLXModel, device: DeviceType, precision: PrecisionType) -> [MLXLayer] {
        var layers: [MLXLayer] = []
        
        layers.append(MLXLayer(
            name: "Input",
            type: .input,
            inputShape: model.inputShape,
            outputShape: model.inputShape,
            parameters: 0,
            device: device,
            precision: precision
        ))
        
        for i in 1...20 {
            layers.append(MLXLayer(
                name: "DiffusionBlock_\(i)",
                type: .diffusion,
                inputShape: model.inputShape,
                outputShape: model.inputShape,
                parameters: 10_000_000,
                device: device,
                precision: precision
            ))
        }
        
        layers.append(MLXLayer(
            name: "Output",
            type: .convolution,
            inputShape: model.inputShape,
            outputShape: model.outputShape,
            parameters: 1_000_000,
            device: device,
            precision: precision
        ))
        
        return layers
    }
    
    private func createGenericLayers(data: Data, model: MLXModel, device: DeviceType, precision: PrecisionType) -> [MLXLayer] {
        var layers: [MLXLayer] = []
        
        layers.append(MLXLayer(
            name: "Input",
            type: .input,
            inputShape: model.inputShape,
            outputShape: model.inputShape,
            parameters: 0,
            device: device,
            precision: precision
        ))
        
        let totalParams = model.parameters
        let layerCount = min(10, Int(totalParams / 1_000_000))
        let paramsPerLayer = totalParams / Int64(layerCount)
        
        for i in 1...layerCount {
            layers.append(MLXLayer(
                name: "Layer_\(i)",
                type: .dense,
                inputShape: i == 1 ? model.inputShape : [Int(model.inputShape[0] * 2)],
                outputShape: [Int(model.inputShape[0] * 2)],
                parameters: paramsPerLayer,
                device: device,
                precision: precision
            ))
        }
        
        layers.append(MLXLayer(
            name: "Output",
            type: .dense,
            inputShape: [Int(model.inputShape[0] * 2)],
            outputShape: model.outputShape,
            parameters: Int64(model.outputShape.reduce(1, *) * Int(model.inputShape[0] * 2)),
            device: device,
            precision: precision
        ))
        
        return layers
    }
    
    private func applyOptimizations(layers: [MLXLayer], level: ModelMetadata.OptimizationLevel) -> [MLXLayer] {
        switch level {
        case .none:
            return layers
        case .basic:
            return optimizeBasic(layers: layers)
        case .advanced:
            return optimizeAdvanced(layers: layers)
        case .extreme:
            return optimizeExtreme(layers: layers)
        }
    }
    
    private func optimizeBasic(layers: [MLXLayer]) -> [MLXLayer] {
        var optimized = layers
        
        for i in 0..<optimized.count {
            var layer = optimized[i]
            layer.optimized = true
            layer.optimizationInfo = "Basic: Layer fusion"
            optimized[i] = layer
        }
        
        return optimized
    }
    
    private func optimizeAdvanced(layers: [MLXLayer]) -> [MLXLayer] {
        var optimized = layers
        
        for i in 0..<optimized.count {
            var layer = optimized[i]
            layer.optimized = true
            layer.optimizationInfo = "Advanced: Layer fusion, quantization"
            
            if layer.type == .convolution || layer.type == .dense {
                layer.memoryUsage = layer.memoryUsage / 2
            }
            
            optimized[i] = layer
        }
        
        return optimized
    }
    
    private func optimizeExtreme(layers: [MLXLayer]) -> [MLXLayer] {
        var optimized = layers
        
        for i in 0..<optimized.count {
            var layer = optimized[i]
            layer.optimized = true
            layer.optimizationInfo = "Extreme: Full optimization"
            
            if layer.type == .convolution || layer.type == .dense {
                layer.memoryUsage = layer.memoryUsage / 4
            }
            
            optimized[i] = layer
        }
        
        return optimized
    }
    
    private func estimateMemoryUsage(layers: [MLXLayer], model: MLXModel) -> Int64 {
        let layerMemory = layers.reduce(0) { $0 + $1.memoryUsage }
        let parameterMemory = model.parameters * memorySizeForPrecision(model.settings.precision)
        return layerMemory + parameterMemory
    }
    
    private func memorySizeForPrecision(_ precision: PrecisionType) -> Int64 {
        switch precision {
        case .float32: return 4
        case .float16: return 2
        case .int8: return 1
        }
    }
    
    private func mapDevice(_ device: AppState.Settings.Device) -> DeviceType {
        switch device {
        case .auto: return .auto
        case .cpu: return .cpu
        case .gpu: return .gpu
        case .mps: return .mps
        }
    }
    
    private func mapPrecision(_ precision: AppState.Settings.Precision) -> PrecisionType {
        switch precision {
        case .float32: return .float32
        case .float16: return .float16
        case .int8: return .int8
        }
    }
    
    private func saveModelMetadata(_ model: MLXModel) {
        let metadata = ModelMetadata(
            model: model,
            downloadDate: Date(),
            fileChecksum: "",
            optimizationLevel: .none
        )
        
        do {
            let data = try JSONEncoder().encode(metadata)
            let url = createLocalPath(for: model)?.appendingPathExtension("metadata")
            try data.write(to: url!)
        } catch {
            print("Failed to save metadata: \(error)")
        }
    }
    
    enum ModelError: Error {
        case modelNotFound
        case invalidModelFormat
        case unsupportedDevice
        case outOfMemory
        case downloadFailed
    }
}

struct MLXLoadedModel {
    let model: MLXModel
    let layers: [MLXLayer]
    let device: DeviceType
    let precision: PrecisionType
    let optimizationLevel: ModelMetadata.OptimizationLevel
    let fileSize: Int64
    let loadTime: TimeInterval
    let memoryUsage: Int64
    
    var totalParameters: Int64 {
        layers.reduce(0) { $0 + $1.parameters }
    }
    
    var formattedMemoryUsage: String {
        let mb = Double(memoryUsage) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
}

struct MLXLayer {
    let name: String
    let type: LayerType
    let inputShape: [Int]
    let outputShape: [Int]
    let parameters: Int64
    var device: DeviceType
    var precision: PrecisionType
    var optimized: Bool = false
    var optimizationInfo: String?
    
    var memoryUsage: Int64 {
        let inputMemory = inputShape.reduce(1, *) * memorySizeForPrecision(precision)
        let outputMemory = outputShape.reduce(1, *) * memorySizeForPrecision(precision)
        let paramMemory = parameters * memorySizeForPrecision(precision)
        return Int64(inputMemory + outputMemory + paramMemory)
    }
    
    private func memorySizeForPrecision(_ precision: PrecisionType) -> Int64 {
        switch precision {
        case .float32: return 4
        case .float16: return 2
        case .int8: return 1
        }
    }
}

enum DeviceType {
    case auto, cpu, gpu, mps
}

enum PrecisionType {
    case float32, float16, int8
}

enum LayerType {
    case input, output, convolution, dense, transformer, residual, pooling, embedding, diffusion, attention, normalization
}
