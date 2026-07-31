# MLX Mac App

A powerful and highly optimized Mac application for running MLX (Machine Learning eXploration) models. Built with SwiftUI and designed for maximum performance on Apple Silicon.

## Features

### 🚀 Core Capabilities
- **Model Management**: Load, unload, and manage multiple MLX models
- **Inference Engine**: Run inference on various model types (Vision, NLP, Audio, Diffusion)
- **Batch Processing**: Process multiple inputs efficiently
- **Performance Monitoring**: Real-time tracking of inference times, memory usage, and system resources

### 🎯 Model Support
- **Vision Models**: ResNet, ViT, and custom vision models
- **NLP Models**: BERT, LLama, and other transformer models
- **Audio Models**: Whisper and other speech recognition models
- **Diffusion Models**: Stable Diffusion and other generative models
- **Custom Models**: Support for loading custom MLX models

### ⚡ Performance Optimizations
- **Metal Acceleration**: Full support for Apple's Metal framework
- **Memory Management**: Intelligent memory allocation and cleanup
- **Batch Processing**: Optimized batch inference with configurable batch sizes
- **Precision Control**: Support for Float32, Float16, and Int8 precision
- **Device Selection**: Automatic or manual device selection (CPU, GPU, MPS)

### 📊 Monitoring & Analytics
- **Real-time Performance Metrics**: Track inference times, memory usage, and system resources
- **Detailed Statistics**: View historical performance data and identify bottlenecks
- **Layer-level Profiling**: Analyze performance at the layer level
- **Memory Usage Tracking**: Monitor memory consumption per model and overall

### 🎨 User Interface
- **Modern SwiftUI Design**: Clean, intuitive interface optimized for macOS
- **Model Browser**: Easy discovery and management of available models
- **Inference Playground**: Interactive interface for testing models
- **Performance Dashboard**: Visual charts and graphs for monitoring
- **Settings & Configuration**: Fine-tune app behavior and model parameters

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Apple Silicon** (M1, M2, or later recommended)
- **Xcode 15.0+** (for development)
- **Metal-compatible GPU** (for hardware acceleration)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/MrFlappy0/MacApp.git
cd MacApp
```

2. Open the project in Xcode:
```bash
open MLXMacApp.xcodeproj
```

3. Build and run the application (⌘ + R)

### Using Swift Package Manager

1. Add the package dependency to your project
2. Import the MLXMacApp module

## Usage

### Loading a Model

1. Open the MLX Mac App
2. Navigate to the "Models" tab
3. Select a model from the list
4. Click "Download" if the model is not already downloaded
5. Click "Load" to load the model into memory

### Running Inference

1. Go to the "Inference" tab
2. Select a loaded model
3. Enter your input (text, image, or audio depending on model type)
4. Click "Run Inference"
5. View the results in the results panel

### Batch Processing

1. Prepare multiple inputs
2. Select batch mode
3. Configure batch size in settings
4. Run batch inference
5. Monitor progress and results

### Performance Monitoring

1. Navigate to the "Performance" tab
2. View real-time metrics and charts
3. Analyze historical performance data
4. Identify slowest layers and bottlenecks

## Configuration

### Settings

- **Device**: Choose between Auto, CPU, GPU, or MPS (Metal)
- **Precision**: Select Float32, Float16, or Int8
- **Batch Size**: Configure the number of inputs to process simultaneously
- **Memory Optimization**: Enable automatic memory management
- **Metal Acceleration**: Toggle hardware acceleration

### Model Presets

- **High Performance**: Optimized for maximum speed
- **Memory Efficient**: Optimized for low memory usage
- **Balanced**: Balanced performance and memory usage
- **High Precision**: Maximum precision for accurate results

## Architecture

### Project Structure

```
MLXMacApp/
├── Sources/
│   ├── Main/
│   │   └── main.swift
│   ├── App/
│   │   └── MLXMacAppApp.swift
│   ├── Models/
│   │   ├── MLXModel.swift
│   │   ├── ModelLoader.swift
│   │   └── InferenceEngine.swift
│   ├── Utilities/
│   │   ├── PerformanceMonitor.swift
│   │   ├── MemoryManager.swift
│   │   ├── BatchProcessor.swift
│   │   └── ModelConfig.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── ModelSelectionView.swift
│   │   ├── InferenceView.swift
│   │   ├── PerformanceView.swift
│   │   └── SettingsView.swift
│   └── ViewModels/
│       ├── AppState.swift
│       ├── ModelViewModel.swift
│       └── InferenceViewModel.swift
├── Resources/
│   ├── Info.plist
│   └── Assets.xcassets/
├── Config/
│   ├── Debug.xcconfig
│   └── Release.xcconfig
├── MLXMacApp.xcodeproj/
└── Package.swift
```

### Key Components

- **ModelLoader**: Handles loading, unloading, and caching of MLX models
- **InferenceEngine**: Executes inference operations with various optimizations
- **PerformanceMonitor**: Tracks and reports performance metrics
- **MemoryManager**: Manages memory allocation and cleanup
- **BatchProcessor**: Handles batch processing of multiple inputs

## Performance Tips

1. **Use Metal Acceleration**: Enable MPS device for best performance on Apple Silicon
2. **Choose Appropriate Precision**: Use Float16 for a balance between speed and accuracy
3. **Optimize Batch Size**: Larger batches improve throughput but increase memory usage
4. **Monitor Memory Usage**: Keep an eye on memory consumption to avoid out-of-memory errors
5. **Use Model Presets**: Apply presets optimized for your specific use case

## Troubleshooting

### Common Issues

- **Model Loading Failed**: Ensure the model file is downloaded and accessible
- **Out of Memory**: Reduce batch size or use lower precision
- **Slow Performance**: Enable Metal acceleration and use appropriate device
- **Unsupported Model**: Check if the model type is supported by the app

### Debug Mode

Enable debug mode in the app settings to see detailed error messages and debugging information.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [MLX Framework](https://github.com/ml-explore/mlx) - Machine Learning eXploration framework
- [SwiftUI](https://developer.apple.com/documentation/swiftui) - Apple's declarative UI framework
- [Metal](https://developer.apple.com/metal/) - Apple's graphics and compute framework

## Contact

For questions, issues, or feedback, please open an issue on GitHub or contact the project maintainer.

---

**MLX Mac App** - Powerful MLX model inference on macOS

*Built with ❤️ for the machine learning community*
