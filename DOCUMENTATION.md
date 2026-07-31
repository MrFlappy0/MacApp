# MLX Mac App - Technical Documentation

## Overview

The MLX Mac App is a comprehensive macOS application designed for running MLX (Machine Learning eXploration) models with high performance and optimization. This document provides detailed technical information about the application's architecture, components, and usage.

## Table of Contents

1. [Architecture](#architecture)
2. [Core Components](#core-components)
3. [Model Management](#model-management)
4. [Inference Engine](#inference-engine)
5. [Performance Optimization](#performance-optimization)
6. [Memory Management](#memory-management)
7. [Batch Processing](#batch-processing)
8. [User Interface](#user-interface)
9. [Configuration](#configuration)
10. [Integration Guide](#integration-guide)

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        MLX Mac App                              │
├─────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   SwiftUI    │    │   MLX Core   │    │  Utilities   │    │
│  │   Views      │◄───►│   Models     │◄───►│  & Services  │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│           ▲                  ▲                  ▲            │
│           │                  │                  │            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    ViewModels                           │   │
│  │  (AppState, ModelViewModel, InferenceViewModel)        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns

1. **MVVM (Model-View-ViewModel)**: Primary pattern for UI organization
2. **Singleton**: Used for shared services (ModelLoader, InferenceEngine, etc.)
3. **Observer**: ObservableObject for state management
4. **Strategy**: Different inference and optimization strategies
5. **Factory**: Model creation and layer generation

## Core Components

### 1. ModelLoader

**Purpose**: Loads, manages, and caches MLX models

**Key Features**:
- Model downloading and caching
- Device-specific loading (CPU, GPU, MPS)
- Precision control (Float32, Float16, Int8)
- Optimization level support
- Memory management integration

**Usage**:
```swift
let modelLoader = ModelLoader.shared
let model = MLXModel.builtInModels[0]

// Load a model
let loadedModel = try await modelLoader.loadModel(
    model,
    device: .mps,
    precision: .float16
)

// Unload a model
modelLoader.unloadModel(model)

// Clear all cached models
modelLoader.clearCache()
```

### 2. InferenceEngine

**Purpose**: Executes inference operations on loaded models

**Key Features**:
- Single and batch inference
- Input preprocessing (text, image, audio)
- Output postprocessing
- Layer-by-layer execution
- Performance tracking
- Error handling

**Supported Input Types**:
- Text (for NLP models)
- Images (for vision models)
- Audio (for speech models)
- Tensors (for custom inputs)

**Usage**:
```swift
let inferenceEngine = InferenceEngine.shared
let input = InferenceInput(text: "Hello, world!")

// Run inference
let result = try await inferenceEngine.runInference(
    model: loadedModel,
    input: input,
    settings: appState.settings
)

// Run batch inference
let results = try await inferenceEngine.runBatchInference(
    model: loadedModel,
    inputs: [input1, input2, input3],
    settings: appState.settings
)
```

### 3. PerformanceMonitor

**Purpose**: Tracks and reports performance metrics

**Key Features**:
- Real-time performance tracking
- Historical data collection
- Layer-level timing
- Memory usage monitoring
- CPU/GPU usage tracking
- Statistical analysis

**Metrics Tracked**:
- Inference times (average, min, max)
- Memory usage (current, peak, average)
- CPU/GPU utilization
- Layer execution times
- Batch processing times

**Usage**:
```swift
let monitor = PerformanceMonitor.shared

// Start monitoring
monitor.startMonitoring()

// Get statistics
let stats = monitor.getStatistics()
print("Average inference time: \(stats.formattedAverageInferenceTime)")

// Stop monitoring
monitor.stopMonitoring()
```

### 4. MemoryManager

**Purpose**: Manages memory allocation and usage

**Key Features**:
- Model memory tracking
- Memory usage warnings
- Automatic cleanup
- Memory optimization
- System memory monitoring

**Usage**:
```swift
let memoryManager = MemoryManager.shared

// Get current memory usage
let currentUsage = memoryManager.getCurrentMemoryUsage()

// Get memory report
let report = memoryManager.getMemoryReport()
print("Memory usage: \(report.formattedUsagePercentage)")

// Cleanup unused models
memoryManager.cleanupUnusedModels()

// Optimize memory usage
memoryManager.optimizeMemoryUsage()
```

### 5. BatchProcessor

**Purpose**: Handles batch processing of multiple inputs

**Key Features**:
- Configurable batch sizes
- Progress tracking
- Memory-aware processing
- Parallel execution
- Performance estimation

**Usage**:
```swift
let batchProcessor = BatchProcessor.shared

// Process a batch
let results = try await batchProcessor.processBatch(
    model: loadedModel,
    inputs: inputs,
    settings: appState.settings
)

// Process with progress
let results = try await batchProcessor.processBatchWithProgress(
    model: loadedModel,
    inputs: inputs,
    settings: appState.settings
) { progress in
    print("Progress: \(progress * 100)%")
}

// Get recommendations
let recommendations = batchProcessor.getBatchProcessingRecommendations(
    for: loadedModel,
    inputCount: 100,
    settings: appState.settings
)
```

## Model Management

### Model Types

The app supports several categories of MLX models:

1. **Vision Models**: Image classification, object detection, segmentation
2. **NLP Models**: Text classification, language generation, embeddings
3. **Audio Models**: Speech recognition, audio classification
4. **Diffusion Models**: Image generation, text-to-image
5. **Multimodal Models**: Combined vision and language models
6. **Classifier Models**: General classification tasks
7. **Generator Models**: Generative models for various outputs

### Built-in Models

The app includes several pre-configured models:

- **ResNet-50**: Deep residual network for image classification
- **BERT Base**: Bidirectional transformer for NLP tasks
- **Stable Diffusion**: Text-to-image diffusion model
- **Whisper Tiny**: Automatic speech recognition model
- **LLama-2-7B**: Large language model with 7B parameters
- **ViT Base**: Vision transformer for image classification

### Custom Models

To add a custom model:

1. Create a `MLXModel` instance with the model's metadata
2. Add it to the `builtInModels` array or load it dynamically
3. Ensure the model file is in the correct format

```swift
let customModel = MLXModel(
    name: "My Custom Model",
    description: "A custom MLX model",
    category: .vision,
    fileSize: 100_000_000,
    parameters: 50_000_000,
    inputShape: [3, 224, 224],
    outputShape: [1000],
    supportedDevices: [.cpu, .gpu, .mps],
    version: "1.0.0",
    author: "My Name",
    license: "MIT",
    url: URL(string: "https://example.com/model")!
)
```

### Model Configuration

Each model can be configured with various settings:

- **Device**: CPU, GPU, MPS, or Auto
- **Precision**: Float32, Float16, or Int8
- **Optimization Level**: None, Basic, Advanced, or Extreme
- **Batch Size**: Number of inputs to process simultaneously
- **Caching**: Enable or disable model caching
- **Timeout**: Maximum inference time
- **Warmup Runs**: Number of warmup runs before actual inference

## Inference Engine

### Input Processing

The inference engine automatically preprocesses inputs based on the model type:

1. **Vision Models**:
   - Resize images to the expected dimensions
   - Convert to the appropriate color space
   - Normalize pixel values

2. **NLP Models**:
   - Tokenize text input
   - Pad sequences to the expected length
   - Convert tokens to embeddings

3. **Audio Models**:
   - Resample audio to the expected rate
   - Convert to the appropriate format
   - Normalize audio values

4. **Diffusion Models**:
   - Process text prompts
   - Generate embeddings
   - Prepare diffusion inputs

### Layer Execution

The inference engine executes models layer by layer:

1. **Input Layer**: Accepts the preprocessed input
2. **Hidden Layers**: Various types (convolution, dense, transformer, etc.)
3. **Output Layer**: Produces the final output

Each layer type has its own execution logic optimized for performance.

### Output Processing

The engine postprocesses outputs based on the model type:

1. **Vision Models**: Convert to class probabilities and labels
2. **NLP Models**: Convert to text or embeddings
3. **Audio Models**: Convert to transcriptions or classifications
4. **Diffusion Models**: Convert to generated images

## Performance Optimization

### Device Selection

The app supports multiple devices for inference:

- **CPU**: Standard CPU execution
- **GPU**: GPU-accelerated execution
- **MPS**: Metal Performance Shaders (Apple's GPU framework)
- **Auto**: Automatic device selection based on availability

**Recommendation**: Use MPS for best performance on Apple Silicon.

### Precision Control

Different precision levels affect performance and memory usage:

- **Float32**: Highest precision, highest memory usage, slowest
- **Float16**: Balanced precision and performance, recommended for most use cases
- **Int8**: Lowest precision, lowest memory usage, fastest

### Optimization Levels

The app supports multiple optimization levels:

1. **None**: No optimization, original model
2. **Basic**: Layer fusion and basic optimizations
3. **Advanced**: Layer fusion, quantization, and other optimizations
4. **Extreme**: Full optimization including aggressive quantization

### Memory Optimization

The app includes several memory optimization techniques:

1. **Automatic Cleanup**: Removes unused models from memory
2. **Memory Warnings**: Alerts when memory usage exceeds thresholds
3. **Batch Size Adjustment**: Automatically adjusts batch size based on available memory
4. **Precision Reduction**: Uses lower precision when memory is constrained

## Memory Management

### Memory Tracking

The app tracks memory usage at multiple levels:

1. **Per-Model Memory**: Memory used by each loaded model
2. **Total Memory**: Total memory used by all models
3. **Peak Memory**: Highest memory usage during the session
4. **System Memory**: Available system memory

### Memory Thresholds

- **Warning Threshold**: 8GB (configurable)
- **Critical Threshold**: 12GB (configurable)

When thresholds are exceeded, the app can:
- Show warnings to the user
- Automatically unload unused models
- Reduce batch sizes
- Switch to lower precision

### Memory Reports

The app provides detailed memory reports including:

- Total system memory
- Available memory
- Used memory
- Peak memory usage
- Memory usage percentage
- Per-model memory breakdown

## Batch Processing

### Batch Configuration

Batch processing allows efficient handling of multiple inputs:

- **Batch Size**: Number of inputs to process simultaneously (1-32)
- **Total Batches**: Number of batches to process all inputs
- **Progress Tracking**: Real-time progress updates
- **Memory Management**: Memory-aware batch processing

### Batch Recommendations

The app provides recommendations for batch processing:

- **Max Batch Size**: Maximum batch size based on available memory
- **Recommended Batch Size**: Optimal batch size for the current configuration
- **Estimated Processing Time**: Expected time to process all inputs
- **Estimated Memory Usage**: Memory required for the recommended batch size

### Parallel Execution

The app uses Swift's structured concurrency for parallel execution:

```swift
try await withThrowingTaskGroup(of: InferenceResult.self) { group in
    for input in inputs {
        group.addTask {
            try await inferenceEngine.runInference(
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
```

## User Interface

### Main Components

1. **Sidebar**: Navigation between different sections
2. **Model Selection**: Browse and manage available models
3. **Inference**: Run inference on selected models
4. **Performance**: View performance metrics and charts
5. **Settings**: Configure app behavior

### Model Selection View

- **Search**: Filter models by name, description, or category
- **Categories**: Filter by model category
- **Model List**: View available models with metadata
- **Model Details**: View detailed information about a specific model
- **Actions**: Download, load, unload, and configure models

### Inference View

- **Model Selection**: Choose a loaded model
- **Input**: Enter text, select images, or provide other inputs
- **Actions**: Run single or batch inference
- **Results**: View inference results with performance metrics

### Performance View

- **Summary Cards**: Quick overview of key metrics
- **Charts**: Visual representation of performance data
- **Detailed Stats**: Comprehensive statistics and analysis
- **Layer Analysis**: Performance breakdown by layer

### Settings View

- **General Settings**: Auto-load models, performance monitoring
- **Performance Settings**: Device, precision, batch size, optimizations
- **Advanced Settings**: Model presets, defaults
- **About**: App information and links

## Configuration

### App Settings

The app provides several configurable settings:

```swift
struct Settings {
    var autoLoadModels = false
    var optimizeMemory = true
    var useMetalAcceleration = true
    var batchSize = 1
    var precision: Precision = .float16
    var device: Device = .auto
}
```

### Model Presets

The app includes several predefined configuration presets:

1. **High Performance**: Optimized for maximum speed
   - Device: MPS
   - Precision: Float16
   - Optimization: Advanced
   - Batch Size: 4

2. **Memory Efficient**: Optimized for low memory usage
   - Device: CPU
   - Precision: Int8
   - Optimization: Extreme
   - Batch Size: 1

3. **Balanced**: Balanced performance and memory usage
   - Device: Auto
   - Precision: Float16
   - Optimization: Basic
   - Batch Size: 2

4. **High Precision**: Maximum precision for accurate results
   - Device: MPS
   - Precision: Float32
   - Optimization: None
   - Batch Size: 1

### Custom Configuration

Users can create custom configurations for specific models:

```swift
let config = ModelConfig(model: myModel)
config.device = .mps
config.precision = .float16
config.optimizationLevel = .advanced
config.batchSize = 4
config.enableCaching = true

ModelConfigManager.shared.saveConfig(config)
```

## Integration Guide

### Adding MLX Mac App to Your Project

1. **As a Subproject**:
   - Add the MLXMacApp.xcodeproj to your Xcode project
   - Link against the MLXMacApp framework

2. **As a Swift Package**:
   - Add the package dependency to your Package.swift
   - Import the MLXMacApp module

### Using the Inference Engine in Your App

```swift
import MLXMacApp

// Initialize the inference engine
let inferenceEngine = InferenceEngine.shared

// Load a model
let model = MLXModel.builtInModels[0]
let loadedModel = try await ModelLoader.shared.loadModel(model)

// Create input
let input = InferenceInput(text: "Your input text")

// Run inference
let result = try await inferenceEngine.runInference(
    model: loadedModel,
    input: input,
    settings: AppState.Settings()
)

// Process the result
print("Output: \(result.output)")
print("Time: \(result.formattedTime)")
```

### Custom Model Integration

To integrate a custom MLX model:

1. **Define the Model**:
```swift
let customModel = MLXModel(
    name: "My Model",
    description: "My custom MLX model",
    category: .nlp,
    fileSize: 500_000_000,
    parameters: 125_000_000,
    inputShape: [1, 512],
    outputShape: [768],
    supportedDevices: [.cpu, .gpu, .mps],
    version: "1.0.0",
    author: "My Name",
    license: "MIT",
    url: URL(string: "https://example.com/my-model")!
)
```

2. **Load the Model**:
```swift
let loadedModel = try await ModelLoader.shared.loadModel(
    customModel,
    device: .mps,
    precision: .float16
)
```

3. **Run Inference**:
```swift
let result = try await InferenceEngine.shared.runInference(
    model: loadedModel,
    input: input,
    settings: settings
)
```

## Best Practices

### Performance Optimization

1. **Use Metal Acceleration**: Enable MPS device for best performance on Apple Silicon
2. **Choose Appropriate Precision**: Use Float16 for a balance between speed and accuracy
3. **Optimize Batch Size**: Larger batches improve throughput but increase memory usage
4. **Monitor Memory Usage**: Keep an eye on memory consumption to avoid out-of-memory errors
5. **Use Model Presets**: Apply presets optimized for your specific use case

### Memory Management

1. **Unload Unused Models**: Regularly unload models that are not in use
2. **Monitor Memory Usage**: Use the performance monitoring tools to track memory
3. **Adjust Batch Sizes**: Reduce batch sizes when memory is constrained
4. **Use Lower Precision**: Switch to Float16 or Int8 when memory is limited
5. **Enable Automatic Cleanup**: Turn on automatic memory optimization in settings

### Error Handling

1. **Check Model Availability**: Ensure models are downloaded and loaded before inference
2. **Validate Inputs**: Verify that inputs match the expected format for the model
3. **Monitor Performance**: Watch for performance degradation that might indicate issues
4. **Handle Errors Gracefully**: Use try-catch blocks for async operations

## Troubleshooting

### Common Issues and Solutions

1. **Model Loading Failed**:
   - Ensure the model file is downloaded
   - Check that the model file is accessible
   - Verify the model format is supported

2. **Out of Memory**:
   - Reduce batch size
   - Use lower precision
   - Unload unused models
   - Close other memory-intensive applications

3. **Slow Performance**:
   - Enable Metal acceleration
   - Use appropriate device (MPS for Apple Silicon)
   - Reduce model complexity
   - Check for background processes consuming resources

4. **Unsupported Model**:
   - Verify the model type is supported
   - Check the model's input/output shapes
   - Ensure the model is compatible with MLX

5. **Inference Errors**:
   - Validate input data format
   - Check that the model is properly loaded
   - Verify device compatibility
   - Check for sufficient memory

### Debugging Tools

The app includes several debugging tools:

1. **Performance Monitor**: Track inference times and memory usage
2. **Memory Reports**: Detailed memory usage breakdown
3. **Layer Timing**: Identify slow layers in the model
4. **Error Logging**: View detailed error messages

### Enabling Debug Mode

To enable debug mode, add the following to your app's configuration:

```swift
// In your app's initialization
PerformanceMonitor.shared.startMonitoring()
MemoryManager.shared.setMemoryWarningHandler {
    print("Memory warning: Usage exceeds threshold")
}
MemoryManager.shared.setMemoryCriticalHandler {
    print("Memory critical: Usage exceeds critical threshold")
}
```

## API Reference

### ModelLoader

```swift
class ModelLoader {
    static let shared = ModelLoader()
    
    func loadModel(_ model: MLXModel, 
                   device: AppState.Settings.Device, 
                   precision: AppState.Settings.Precision) async throws -> MLXLoadedModel
    
    func unloadModel(_ model: MLXModel, 
                     device: AppState.Settings.Device, 
                     precision: AppState.Settings.Precision)
    
    func clearCache()
    
    func downloadModel(_ model: MLXModel) -> MLXModel
    
    func cancelDownload(_ model: MLXModel)
}
```

### InferenceEngine

```swift
class InferenceEngine {
    static let shared = InferenceEngine()
    
    func runInference(model: MLXLoadedModel, 
                      input: InferenceInput,
                      settings: AppState.Settings) async throws -> InferenceResult
    
    func runBatchInference(model: MLXLoadedModel, 
                           inputs: [InferenceInput],
                           settings: AppState.Settings) async throws -> [InferenceResult]
    
    func cancelInference(_ taskId: UUID)
    
    func cancelAllInferences()
}
```

### PerformanceMonitor

```swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    func startMonitoring()
    
    func stopMonitoring()
    
    func startTracking(task: TaskType)
    
    func stopTracking(task: TaskType)
    
    func getStatistics() -> PerformanceStatistics
    
    func resetStatistics()
}
```

### MemoryManager

```swift
class MemoryManager {
    static let shared = MemoryManager()
    
    func registerModel(_ model: MLXLoadedModel, key: String)
    
    func unregisterModel(_ model: MLXLoadedModel, key: String)
    
    func getCurrentMemoryUsage() -> Int64
    
    func getPeakMemoryUsage() -> Int64
    
    func getMemoryReport() -> MemoryReport
    
    func cleanupUnusedModels()
    
    func optimizeMemoryUsage()
}
```

### BatchProcessor

```swift
class BatchProcessor {
    static let shared = BatchProcessor()
    
    func processBatch(model: MLXLoadedModel, 
                      inputs: [InferenceInput],
                      settings: AppState.Settings) async throws -> [InferenceResult]
    
    func processBatchWithProgress(model: MLXLoadedModel, 
                                   inputs: [InferenceInput],
                                   settings: AppState.Settings,
                                   progressHandler: @escaping (Double) -> Void) async throws -> [InferenceResult]
    
    func getBatchProcessingRecommendations(for model: MLXLoadedModel, 
                                            inputCount: Int,
                                            settings: AppState.Settings) -> BatchRecommendations
}
```

## Data Structures

### MLXModel

```swift
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
    var isDownloaded: Bool
    var localPath: URL?
    var lastUsed: Date?
    
    enum Category: String, Codable, CaseIterable {
        case vision, nlp, audio, multimodal, diffusion, classifier, generator
    }
    
    enum Device: String, Codable, CaseIterable {
        case cpu, gpu, mps
    }
}
```

### MLXLoadedModel

```swift
struct MLXLoadedModel {
    let model: MLXModel
    let layers: [MLXLayer]
    let device: DeviceType
    let precision: PrecisionType
    let optimizationLevel: ModelMetadata.OptimizationLevel
    let fileSize: Int64
    let loadTime: TimeInterval
    let memoryUsage: Int64
    
    var totalParameters: Int64
    var formattedMemoryUsage: String
}
```

### InferenceResult

```swift
struct InferenceResult: Identifiable {
    let id = UUID()
    let modelName: String
    let input: String
    let output: String
    let inferenceTime: TimeInterval
    let memoryUsed: Int64
    let timestamp: Date
    let layersProcessed: Int
    let parameters: Int64
    let device: DeviceType
    let precision: PrecisionType
    
    var formattedTime: String
    var formattedMemory: String
}
```

### PerformanceStatistics

```swift
struct PerformanceStatistics {
    let averageInferenceTime: TimeInterval
    let minInferenceTime: TimeInterval
    let maxInferenceTime: TimeInterval
    let totalInferences: Int
    let averageMemoryUsage: Double
    let peakMemoryUsage: Int64
    let currentMemoryUsage: Int64
    let averageGPUUsage: Double
    let averageCPUUsage: Double
    let slowestLayers: [String]
    let layerTimes: [String: TimeInterval]
    let inferenceHistory: [TimeInterval]
    
    var formattedAverageInferenceTime: String
    var formattedPeakMemory: String
    var formattedCurrentMemory: String
    var formattedGPUUsage: String
    var formattedCPUUsage: String
}
```

## Conclusion

The MLX Mac App provides a comprehensive solution for running MLX models on macOS with high performance and optimization. This documentation covers the key aspects of the application's architecture, components, and usage. For more information, refer to the source code and the README file.

For questions, issues, or feedback, please open an issue on the GitHub repository.
