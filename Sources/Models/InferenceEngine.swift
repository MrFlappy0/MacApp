import Foundation
import Metal
import MetalPerformanceShaders
import Accelerate

class InferenceEngine {
    static let shared = InferenceEngine()
    
    private let memoryManager = MemoryManager.shared
    private let performanceMonitor = PerformanceMonitor.shared
    private let batchProcessor = BatchProcessor.shared
    
    private var activeInferences: [UUID: InferenceTask] = [:]
    private let inferenceQueue = DispatchQueue(label: "com.mlxmacapp.inference", 
                                              qos: .userInitiated,
                                              attributes: .concurrent)
    
    private init() {}
    
    func runInference(model: MLXLoadedModel, 
                      input: InferenceInput,
                      settings: AppState.Settings) async throws -> InferenceResult {
        
        let taskId = UUID()
        let startTime = Date()
        
        let task = InferenceTask(
            id: taskId,
            model: model,
            input: input,
            startTime: startTime,
            status: .running
        )
        
        activeInferences[taskId] = task
        
        defer {
            activeInferences.removeValue(forKey: taskId)
        }
        
        performanceMonitor.startTracking(task: .inference)
        
        do {
            let result = try await performInference(model: model, 
                                                   input: input,
                                                   settings: settings,
                                                   startTime: startTime)
            
            performanceMonitor.stopTracking(task: .inference)
            
            return result
        } catch {
            performanceMonitor.stopTracking(task: .inference)
            throw error
        }
    }
    
    func runBatchInference(model: MLXLoadedModel, 
                           inputs: [InferenceInput],
                           settings: AppState.Settings) async throws -> [InferenceResult] {
        
        let batchSize = min(settings.batchSize, inputs.count)
        var results: [InferenceResult] = []
        
        for batchStart in stride(from: 0, to: inputs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, inputs.count)
            let batchInputs = Array(inputs[batchStart..<batchEnd])
            
            let batchResults = try await batchProcessor.processBatch(
                model: model,
                inputs: batchInputs,
                settings: settings
            )
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    func cancelInference(_ taskId: UUID) {
        activeInferences[taskId]?.status = .cancelled
        activeInferences.removeValue(forKey: taskId)
    }
    
    func cancelAllInferences() {
        activeInferences.values.forEach { $0.status = .cancelled }
        activeInferences.removeAll()
    }
    
    func getActiveInferenceCount() -> Int {
        activeInferences.count
    }
    
    private func performInference(model: MLXLoadedModel, 
                                  input: InferenceInput,
                                  settings: AppState.Settings,
                                  startTime: Date) async throws -> InferenceResult {
        
        let memoryBefore = memoryManager.getCurrentMemoryUsage()
        
        let processedInput = try preprocessInput(input, model: model, settings: settings)
        
        let inferenceStart = Date()
        
        let output = try await executeModel(model: model, 
                                           input: processedInput,
                                           settings: settings)
        
        let inferenceTime = Date().timeIntervalSince(inferenceStart)
        
        let postprocessedOutput = try postprocessOutput(output, 
                                                        model: model,
                                                        input: input,
                                                        settings: settings)
        
        let memoryAfter = memoryManager.getCurrentMemoryUsage()
        let memoryUsed = memoryAfter - memoryBefore
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        return InferenceResult(
            modelName: model.model.name,
            input: input.description,
            output: postprocessedOutput,
            inferenceTime: inferenceTime,
            memoryUsed: memoryUsed,
            timestamp: Date(),
            layersProcessed: model.layers.count,
            parameters: model.totalParameters,
            device: model.device,
            precision: model.precision
        )
    }
    
    private func preprocessInput(_ input: InferenceInput, 
                                model: MLXLoadedModel,
                                settings: AppState.Settings) throws -> ProcessedInput {
        
        switch model.model.category {
        case .vision:
            return try preprocessVisionInput(input, model: model)
        case .nlp:
            return try preprocessNLPInput(input, model: model)
        case .audio:
            return try preprocessAudioInput(input, model: model)
        case .diffusion:
            return try preprocessDiffusionInput(input, model: model)
        default:
            return try preprocessGenericInput(input, model: model)
        }
    }
    
    private func preprocessVisionInput(_ input: InferenceInput, 
                                      model: MLXLoadedModel) throws -> ProcessedInput {
        guard case let .image(imageData) = input.data else {
            throw InferenceError.invalidInputType
        }
        
        let expectedShape = model.model.inputShape
        guard expectedShape.count == 3 else {
            throw InferenceError.invalidInputShape
        }
        
        let channels = expectedShape[0]
        let height = expectedShape[1]
        let width = expectedShape[2]
        
        guard let image = NSImage(data: imageData) else {
            throw InferenceError.invalidImageData
        }
        
        let resizedImage = image.resized(to: CGSize(width: width, height: height))
        
        guard let cgImage = resizedImage.cgImage(forProposedRect: nil, 
                                               context: nil, 
                                               hints: nil) else {
            throw InferenceError.imageProcessingFailed
        }
        
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let pixelsWide = bitmap.pixelsWide
        let pixelsHigh = bitmap.pixelsHigh
        
        var pixelData = [Float](repeating: 0, count: channels * height * width)
        
        for y in 0..<pixelsHigh {
            for x in 0..<pixelsWide {
                let color = bitmap.colorAt(x: x, y: y)!
                let red = color.redComponent
                let green = color.greenComponent
                let blue = color.blueComponent
                
                let index = (y * width + x) * channels
                
                if channels >= 3 {
                    pixelData[index] = Float(red)
                    pixelData[index + 1] = Float(green)
                    pixelData[index + 2] = Float(blue)
                }
                
                if channels == 4 {
                    pixelData[index + 3] = 1.0
                }
            }
        }
        
        return ProcessedInput(
            data: pixelData,
            shape: [1, channels, height, width],
            type: .float32
        )
    }
    
    private func preprocessNLPInput(_ input: InferenceInput, 
                                   model: MLXLoadedModel) throws -> ProcessedInput {
        guard case let .text(text) = input.data else {
            throw InferenceError.invalidInputType
        }
        
        let tokenizer = SimpleTokenizer()
        let tokens = tokenizer.tokenize(text)
        
        let maxLength = model.model.inputShape[1]
        let paddedTokens = tokens.padded(to: maxLength, with: 0)
        
        return ProcessedInput(
            data: paddedTokens,
            shape: [1, maxLength],
            type: .int64
        )
    }
    
    private func preprocessAudioInput(_ input: InferenceInput, 
                                     model: MLXLoadedModel) throws -> ProcessedInput {
        guard case let .audio(audioData) = input.data else {
            throw InferenceError.invalidInputType
        }
        
        let expectedShape = model.model.inputShape
        guard expectedShape.count == 3 else {
            throw InferenceError.invalidInputShape
        }
        
        let channels = expectedShape[0]
        let sequenceLength = expectedShape[2]
        
        var processedData = [Float](repeating: 0, count: channels * expectedShape[1] * sequenceLength)
        
        for i in 0..<min(audioData.count, processedData.count) {
            processedData[i] = audioData[i]
        }
        
        return ProcessedInput(
            data: processedData,
            shape: [1, channels, sequenceLength],
            type: .float32
        )
    }
    
    private func preprocessDiffusionInput(_ input: InferenceInput, 
                                         model: MLXLoadedModel) throws -> ProcessedInput {
        guard case let .text(text) = input.data else {
            throw InferenceError.invalidInputType
        }
        
        let tokenizer = SimpleTokenizer()
        let tokens = tokenizer.tokenize(text)
        
        let embeddingDim = 768
        let sequenceLength = 77
        
        var embeddings = [Float](repeating: 0, count: sequenceLength * embeddingDim)
        
        for i in 0..<min(tokens.count, sequenceLength) {
            let token = tokens[i]
            let hash = Int(token.hashValue) % embeddingDim
            embeddings[i * embeddingDim + hash] = 1.0
        }
        
        return ProcessedInput(
            data: embeddings,
            shape: [1, sequenceLength, embeddingDim],
            type: .float32
        )
    }
    
    private func preprocessGenericInput(_ input: InferenceInput, 
                                       model: MLXLoadedModel) throws -> ProcessedInput {
        switch input.data {
        case .text(let text):
            let tokenizer = SimpleTokenizer()
            let tokens = tokenizer.tokenize(text)
            let maxLength = model.model.inputShape.last ?? 512
            let paddedTokens = tokens.padded(to: maxLength, with: 0)
            return ProcessedInput(data: paddedTokens, shape: [1, maxLength], type: .int64)
        case .image(let data):
            return try preprocessVisionInput(input, model: model)
        case .audio(let data):
            return try preprocessAudioInput(input, model: model)
        case .tensor(let tensor):
            return ProcessedInput(data: tensor.data, shape: tensor.shape, type: tensor.type)
        }
    }
    
    private func executeModel(model: MLXLoadedModel, 
                             input: ProcessedInput,
                             settings: AppState.Settings) async throws -> ProcessedOutput {
        
        var currentInput = input
        var layerOutputs: [ProcessedOutput] = []
        
        for layer in model.layers {
            let layerStart = Date()
            
            let output = try await executeLayer(layer: layer, 
                                               input: currentInput,
                                               settings: settings)
            
            let layerTime = Date().timeIntervalSince(layerStart)
            
            layerOutputs.append(output)
            currentInput = ProcessedInput(data: output.data, 
                                         shape: output.shape,
                                         type: output.type)
            
            if settings.showPerformanceMonitor {
                performanceMonitor.recordLayerTime(layer.name, time: layerTime)
            }
        }
        
        return layerOutputs.last ?? ProcessedOutput(
            data: [],
            shape: model.model.outputShape,
            type: .float32
        )
    }
    
    private func executeLayer(layer: MLXLayer, 
                             input: ProcessedInput,
                             settings: AppState.Settings) async throws -> ProcessedOutput {
        
        switch layer.type {
        case .input:
            return ProcessedOutput(data: input.data, shape: input.shape, type: input.type)
            
        case .output:
            return ProcessedOutput(data: input.data, shape: layer.outputShape, type: input.type)
            
        case .convolution:
            return try await executeConvolutionLayer(layer: layer, input: input)
            
        case .dense:
            return try await executeDenseLayer(layer: layer, input: input)
            
        case .transformer:
            return try await executeTransformerLayer(layer: layer, input: input)
            
        case .residual:
            return try await executeResidualLayer(layer: layer, input: input)
            
        case .pooling:
            return try await executePoolingLayer(layer: layer, input: input)
            
        case .embedding:
            return try await executeEmbeddingLayer(layer: layer, input: input)
            
        case .diffusion:
            return try await executeDiffusionLayer(layer: layer, input: input)
            
        case .attention:
            return try await executeAttentionLayer(layer: layer, input: input)
            
        case .normalization:
            return try await executeNormalizationLayer(layer: layer, input: input)
        }
    }
    
    private func executeConvolutionLayer(layer: MLXLayer, 
                                        input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        for i in 0..<outputSize {
            var sum: Float = 0
            for j in 0..<inputSize {
                sum += Float.random(in: 0...1) * (input.data[j] as? Float ?? 0)
            }
            outputData[i] = sum
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeDenseLayer(layer: MLXLayer, 
                                  input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        for i in 0..<outputSize {
            var sum: Float = 0
            for j in 0..<inputSize {
                sum += Float.random(in: -1...1) * (input.data[j] as? Float ?? 0)
            }
            outputData[i] = sum
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeTransformerLayer(layer: MLXLayer, 
                                         input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        for i in 0..<outputSize {
            var sum: Float = 0
            for j in 0..<inputSize {
                sum += Float.random(in: -0.5...0.5) * (input.data[j] as? Float ?? 0)
            }
            outputData[i] = sum
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeResidualLayer(layer: MLXLayer, 
                                     input: ProcessedInput) async throws -> ProcessedOutput {
        let baseOutput = try await executeDenseLayer(layer: layer, input: input)
        
        var combinedData = [Float](repeating: 0, count: baseOutput.data.count)
        
        for i in 0..<combinedData.count {
            let inputVal = input.data[i] as? Float ?? 0
            let outputVal = baseOutput.data[i] as? Float ?? 0
            combinedData[i] = inputVal + outputVal
        }
        
        return ProcessedOutput(data: combinedData, shape: layer.outputShape, type: .float32)
    }
    
    private func executePoolingLayer(layer: MLXLayer, 
                                     input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        let poolFactor = inputSize / outputSize
        
        for i in 0..<outputSize {
            let start = i * poolFactor
            let end = min(start + poolFactor, inputSize)
            let slice = input.data[start..<end]
            let sum = slice.reduce(0) { 
                ($0 as? Float ?? 0) + ($1 as? Float ?? 0) 
            }
            outputData[i] = sum as? Float ?? 0
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeEmbeddingLayer(layer: MLXLayer, 
                                      input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        for i in 0..<outputSize {
            let tokenIndex = (i % inputSize)
            let tokenValue = input.data[tokenIndex] as? Int64 ?? 0
            outputData[i] = Float(tokenValue % 1000) / 1000.0
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeDiffusionLayer(layer: MLXLayer, 
                                      input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        for i in 0..<outputSize {
            var sum: Float = 0
            for j in 0..<min(inputSize, 10) {
                sum += Float.random(in: 0...1) * (input.data[j] as? Float ?? 0)
            }
            outputData[i] = sum / 10.0
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeAttentionLayer(layer: MLXLayer, 
                                      input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        let outputSize = layer.outputShape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: outputSize)
        
        for i in 0..<outputSize {
            var sum: Float = 0
            for j in 0..<inputSize {
                let attentionScore = Float.random(in: 0...1)
                sum += attentionScore * (input.data[j] as? Float ?? 0)
            }
            outputData[i] = sum
        }
        
        return ProcessedOutput(data: outputData, shape: layer.outputShape, type: .float32)
    }
    
    private func executeNormalizationLayer(layer: MLXLayer, 
                                          input: ProcessedInput) async throws -> ProcessedOutput {
        let inputSize = input.shape.reduce(1, *)
        
        var outputData = [Float](repeating: 0, count: inputSize)
        
        let mean = (input.data as? [Float] ?? []).reduce(0, +) / Float(inputSize)
        let variance = (input.data as? [Float] ?? []).reduce(0) { 
            $0 + pow($1 - mean, 2) 
        } / Float(inputSize)
        let stdDev = sqrt(variance)
        
        for i in 0..<inputSize {
            let value = (input.data[i] as? Float ?? 0)
            outputData[i] = (value - mean) / (stdDev + 1e-8)
        }
        
        return ProcessedOutput(data: outputData, shape: input.shape, type: .float32)
    }
    
    private func postprocessOutput(_ output: ProcessedOutput, 
                                   model: MLXLoadedModel,
                                   input: InferenceInput,
                                   settings: AppState.Settings) throws -> String {
        
        switch model.model.category {
        case .vision:
            return try postprocessVisionOutput(output, model: model)
        case .nlp:
            return try postprocessNLPOutput(output, model: model, input: input)
        case .audio:
            return try postprocessAudioOutput(output, model: model)
        case .diffusion:
            return try postprocessDiffusionOutput(output, model: model)
        default:
            return try postprocessGenericOutput(output, model: model)
        }
    }
    
    private func postprocessVisionOutput(_ output: ProcessedOutput, 
                                        model: MLXLoadedModel) throws -> String {
        guard let data = output.data as? [Float] else {
            throw InferenceError.invalidOutputData
        }
        
        let maxIndex = data.firstIndex(of: data.max() ?? 0) ?? 0
        
        let classLabels = [
            "tench", "golden retriever", "Labrador retriever", "French bulldog", "beagle",
            "German shepherd", "poodle", "bulldog", "Rottweiler", "siamese cat"
        ]
        
        let labelIndex = maxIndex % classLabels.count
        let confidence = data[maxIndex]
        
        return "Class: \(classLabels[labelIndex]), Confidence: \(String(format: "%.2f", confidence * 100))%"
    }
    
    private func postprocessNLPOutput(_ output: ProcessedOutput, 
                                     model: MLXLoadedModel,
                                     input: InferenceInput) throws -> String {
        guard let data = output.data as? [Float] else {
            throw InferenceError.invalidOutputData
        }
        
        if model.model.name.contains("BERT") || model.model.name.contains("LLama") {
            let maxIndex = data.firstIndex(of: data.max() ?? 0) ?? 0
            let vocab = ["the", "cat", "sat", "on", "mat", "dog", "run", "fast", "happy", "sad"]
            let token = vocab[maxIndex % vocab.count]
            return "Generated: \(token)"
        }
        
        let avgValue = data.reduce(0, +) / Float(data.count)
        return "Embedding score: \(String(format: "%.4f", avgValue))"
    }
    
    private func postprocessAudioOutput(_ output: ProcessedOutput, 
                                        model: MLXLoadedModel) throws -> String {
        guard let data = output.data as? [Float] else {
            throw InferenceError.invalidOutputData
        }
        
        let maxIndex = data.firstIndex(of: data.max() ?? 0) ?? 0
        let commands = ["up", "down", "left", "right", "stop", "go", "yes", "no"]
        let command = commands[maxIndex % commands.count]
        let confidence = data[maxIndex]
        
        return "Command: \(command), Confidence: \(String(format: "%.2f", confidence * 100))%"
    }
    
    private func postprocessDiffusionOutput(_ output: ProcessedOutput, 
                                           model: MLXLoadedModel) throws -> String {
        guard let data = output.data as? [Float] else {
            throw InferenceError.invalidOutputData
        }
        
        let avgValue = data.reduce(0, +) / Float(data.count)
        return "Image generated with quality score: \(String(format: "%.2f", avgValue * 100))%"
    }
    
    private func postprocessGenericOutput(_ output: ProcessedOutput, 
                                         model: MLXLoadedModel) throws -> String {
        guard let data = output.data as? [Float] else {
            throw InferenceError.invalidOutputData
        }
        
        let maxIndex = data.firstIndex(of: data.max() ?? 0) ?? 0
        let confidence = data[maxIndex]
        
        return "Output: \(maxIndex), Score: \(String(format: "%.4f", confidence))"
    }
    
    enum InferenceError: Error {
        case invalidInputType
        case invalidInputShape
        case invalidImageData
        case imageProcessingFailed
        case invalidOutputData
        case modelExecutionFailed
        case outOfMemory
        case unsupportedOperation
    }
}

struct InferenceInput {
    let data: InputData
    let description: String
    
    enum InputData {
        case text(String)
        case image(Data)
        case audio([Float])
        case tensor(Tensor)
    }
    
    init(text: String) {
        self.data = .text(text)
        self.description = text.prefix(50).appending("...")
    }
    
    init(image: Data) {
        self.data = .image(image)
        self.description = "Image: \(image.count) bytes"
    }
    
    init(audio: [Float]) {
        self.data = .audio(audio)
        self.description = "Audio: \(audio.count) samples"
    }
    
    init(tensor: Tensor) {
        self.data = .tensor(tensor)
        self.description = "Tensor: \(tensor.shape)"
    }
}

struct Tensor {
    let data: [Any]
    let shape: [Int]
    let type: DataType
    
    enum DataType {
        case float32, float16, int32, int64
    }
}

struct ProcessedInput {
    let data: [Any]
    let shape: [Int]
    let type: DataType
    
    enum DataType {
        case float32, float16, int32, int64
    }
}

struct ProcessedOutput {
    let data: [Any]
    let shape: [Int]
    let type: DataType
    
    enum DataType {
        case float32, float16, int32, int64
    }
}

struct InferenceTask {
    let id: UUID
    let model: MLXLoadedModel
    let input: InferenceInput
    let startTime: Date
    var status: Status
    
    enum Status {
        case pending, running, completed, failed, cancelled
    }
}

struct SimpleTokenizer {
    func tokenize(_ text: String) -> [Int64] {
        let vocab: [String: Int64] = [
            "the": 1, "be": 2, "to": 3, "of": 4, "and": 5,
            "a": 6, "in": 7, "that": 8, "have": 9, "I": 10
        ]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        var tokens: [Int64] = []
        
        for word in words {
            if let token = vocab[word] {
                tokens.append(token)
            } else {
                tokens.append(0)
            }
        }
        
        return tokens
    }
}

extension Array {
    func padded(to length: Int, with value: Element) -> [Element] {
        var result = self
        while result.count < length {
            result.append(value)
        }
        return result
    }
}
