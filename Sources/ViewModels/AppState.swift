import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentTab: Tab = .models
    @Published var isLoading = false
    @Published var showPerformanceMonitor = false
    @Published var showMemoryStats = false
    @Published var selectedModel: MLXModel?
    @Published var inferenceResults: [InferenceResult] = []
    @Published var errorMessage: String?
    
    @Published var settings = Settings()
    
    enum Tab {
        case models, inference, performance, settings
    }
    
    struct Settings {
        var autoLoadModels = false
        var optimizeMemory = true
        var useMetalAcceleration = true
        var batchSize = 1
        var precision: Precision = .float16
        var device: Device = .auto
        
        enum Precision: String, CaseIterable {
            case float32 = "Float 32"
            case float16 = "Float 16"
            case int8 = "Int 8"
        }
        
        enum Device: String, CaseIterable {
            case auto = "Auto"
            case cpu = "CPU"
            case gpu = "GPU"
            case mps = "MPS (Metal)"
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.errorMessage = nil
        }
    }
    
    func addInferenceResult(_ result: InferenceResult) {
        inferenceResults.insert(result, at: 0)
        if inferenceResults.count > 100 {
            inferenceResults.removeLast()
        }
    }
}

struct InferenceResult: Identifiable {
    let id = UUID()
    let modelName: String
    let input: String
    let output: String
    let inferenceTime: TimeInterval
    let memoryUsed: Int64
    let timestamp: Date
    
    var formattedTime: String {
        String(format: "%.3f ms", inferenceTime * 1000)
    }
    
    var formattedMemory: String {
        let mb = Double(memoryUsed) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
}
