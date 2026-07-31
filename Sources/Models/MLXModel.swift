import Foundation
import Metal
import MetalPerformanceShaders

struct MLXModel: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let category: Category
    let fileSize: Int64
    let parameters: Int64
    let inputShape: [Int]
    let outputShape: [Int]
    let supportedDevices: [Device]
    let version: String
    let author: String
    let license: String
    let url: URL
    var isDownloaded: Bool = false
    var localPath: URL?
    var lastUsed: Date?
    
    enum Category: String, Codable, CaseIterable {
        case vision = "Vision"
        case nlp = "NLP"
        case audio = "Audio"
        case multimodal = "Multimodal"
        case diffusion = "Diffusion"
        case classifier = "Classifier"
        case generator = "Generator"
    }
    
    enum Device: String, Codable, CaseIterable {
        case cpu = "CPU"
        case gpu = "GPU"
        case mps = "MPS"
    }
    
    var formattedSize: String {
        let mb = Double(fileSize) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    var formattedParameters: String {
        if parameters >= 1_000_000_000 {
            return String(format: "%.2f B", Double(parameters) / 1_000_000_000)
        } else if parameters >= 1_000_000 {
            return String(format: "%.2f M", Double(parameters) / 1_000_000)
        } else {
            return "$parameters K"
        }
    }
    
    static let builtInModels: [MLXModel] = [
        MLXModel(
            name: "ResNet-50",
            description: "Deep residual network for image classification",
            category: .vision,
            fileSize: 98_000_000,
            parameters: 25_500_000,
            inputShape: [3, 224, 224],
            outputShape: [1000],
            supportedDevices: [.cpu, .gpu, .mps],
            version: "1.0.0",
            author: "Microsoft Research",
            license: "MIT",
            url: URL(string: "https://github.com/ml-explore/mlx-examples")!
        ),
        MLXModel(
            name: "BERT Base",
            description: "Bidirectional Encoder Representations from Transformers",
            category: .nlp,
            fileSize: 420_000_000,
            parameters: 110_000_000,
            inputShape: [1, 512],
            outputShape: [768],
            supportedDevices: [.cpu, .gpu, .mps],
            version: "1.0.0",
            author: "Google Research",
            license: "Apache 2.0",
            url: URL(string: "https://github.com/ml-explore/mlx-examples")!
        ),
        MLXModel(
            name: "Stable Diffusion",
            description: "Text-to-image diffusion model",
            category: .diffusion,
            fileSize: 2_100_000_000,
            parameters: 860_000_000,
            inputShape: [1, 4, 64, 64],
            outputShape: [3, 512, 512],
            supportedDevices: [.gpu, .mps],
            version: "1.5",
            author: "Stability AI",
            license: "CreativeML",
            url: URL(string: "https://github.com/ml-explore/mlx-examples")!
        ),
        MLXModel(
            name: "Whisper Tiny",
            description: "Automatic speech recognition model",
            category: .audio,
            fileSize: 39_000_000,
            parameters: 39_000_000,
            inputShape: [1, 80, 3000],
            outputShape: [1, 512],
            supportedDevices: [.cpu, .gpu, .mps],
            version: "1.0.0",
            author: "OpenAI",
            license: "MIT",
            url: URL(string: "https://github.com/ml-explore/mlx-examples")!
        ),
        MLXModel(
            name: "LLama-2-7B",
            description: "Large language model with 7 billion parameters",
            category: .nlp,
            fileSize: 14_000_000_000,
            parameters: 7_000_000_000,
            inputShape: [1, 4096],
            outputShape: [4096],
            supportedDevices: [.gpu, .mps],
            version: "2.0.0",
            author: "Meta",
            license: "LLama 2",
            url: URL(string: "https://github.com/ml-explore/mlx-examples")!
        ),
        MLXModel(
            name: "ViT Base",
            description: "Vision Transformer for image classification",
            category: .vision,
            fileSize: 350_000_000,
            parameters: 86_000_000,
            inputShape: [3, 224, 224],
            outputShape: [1000],
            supportedDevices: [.cpu, .gpu, .mps],
            version: "1.0.0",
            author: "Google Research",
            license: "Apache 2.0",
            url: URL(string: "https://github.com/ml-explore/mlx-examples")!
        )
    ]
}

struct ModelMetadata: Codable {
    let model: MLXModel
    let downloadDate: Date
    let fileChecksum: String
    let optimizationLevel: OptimizationLevel
    
    enum OptimizationLevel: String, Codable {
        case none = "None"
        case basic = "Basic"
        case advanced = "Advanced"
        case extreme = "Extreme"
    }
}
