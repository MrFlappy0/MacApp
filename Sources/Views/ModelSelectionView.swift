import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    @State private var selectedModel: MLXModel?
    @State private var showingModelDetail = false
    @State private var showingDownloadAlert = false
    @State private var downloadModel: MLXModel?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $modelViewModel.searchText, 
                         placeholder: "Search models...")
                
                CategoryFilterView(selectedCategory: $modelViewModel.selectedCategory)
                
                ModelListView(selectedModel: $selectedModel)
            }
            .navigationTitle("Models")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Refresh", action: modelViewModel.loadModels)
                        Button("Clear Cache", action: modelViewModel.unloadAllModels)
                        Divider()
                        Button("Optimize Memory", action: modelViewModel.optimizeMemory)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(item: $selectedModel) { model in
                ModelDetailView(model: model)
                    .environmentObject(modelViewModel)
            }
            .alert("Download Model", isPresented: $showingDownloadAlert) {
                Button("Download", role: .destructive) {
                    if let model = downloadModel {
                        modelViewModel.downloadModel(model)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to download \(downloadModel?.name ?? "this model")?")
            }
            .overlay {
                if modelViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(8)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .padding()
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: MLXModel.Category?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryButton(category: nil, selectedCategory: $selectedCategory)
                
                ForEach(MLXModel.Category.allCases, id: \.self) { category in
                    CategoryButton(category: category, selectedCategory: $selectedCategory)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

struct CategoryButton: View {
    let category: MLXModel.Category?
    @Binding var selectedCategory: MLXModel.Category?
    
    var body: some View {
        Button(action: { selectedCategory = category }) {
            Text(category?.rawValue ?? "All")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedCategory == category ?
                    Color.accentColor :
                    Color(.controlBackgroundColor)
                )
                .foregroundColor(
                    selectedCategory == category ?
                    .white :
                    .primary
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ModelListView: View {
    @EnvironmentObject var modelViewModel: ModelViewModel
    @Binding var selectedModel: MLXModel?
    
    var body: some View {
        List(selection: $selectedModel) {
            ForEach(modelViewModel.models) { model in
                ModelRow(model: model)
                    .tag(model)
                    .onTapGesture {
                        selectedModel = model
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            modelViewModel.loadModels()
        }
    }
}

struct ModelRow: View {
    let model: MLXModel
    
    var body: some View {
        HStack(spacing: 12) {
            ModelIcon(category: model.category)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                
                Text(model.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(model.formattedParameters)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(model.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if model.isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Text(model.formattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

struct ModelIcon: View {
    let category: MLXModel.Category
    
    var body: some View {
        ZStack {
            Circle()
                .fill(categoryColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: categoryIcon)
                .foregroundColor(.white)
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .vision: return .blue
        case .nlp: return .green
        case .audio: return .orange
        case .multimodal: return .purple
        case .diffusion: return .pink
        case .classifier: return .yellow
        case .generator: return .red
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .vision: return "eye"
        case .nlp: return "text.bubble"
        case .audio: return "mic"
        case .multimodal: return "photo.on.rectangle"
        case .diffusion: return "paintpalette"
        case .classifier: return "list.bullet"
        case .generator: return "sparkles"
        }
    }
}

struct ModelDetailView: View {
    let model: MLXModel
    @EnvironmentObject var modelViewModel: ModelViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = false
    @State private var showConfig = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    InfoRow(label: "Name", value: model.name)
                    InfoRow(label: "Version", value: model.version)
                    InfoRow(label: "Author", value: model.author)
                    InfoRow(label: "License", value: model.license)
                    InfoRow(label: "Category", value: model.category.rawValue)
                }
                
                Section("Specifications") {
                    InfoRow(label: "Parameters", value: model.formattedParameters)
                    InfoRow(label: "File Size", value: model.formattedSize)
                    InfoRow(label: "Input Shape", value: formatShape(model.inputShape))
                    InfoRow(label: "Output Shape", value: formatShape(model.outputShape))
                }
                
                Section("Status") {
                    HStack {
                        Text("Downloaded")
                        Spacer()
                        Image(systemName: model.isDownloaded ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(model.isDownloaded ? .green : .red)
                    }
                    
                    HStack {
                        Text("Loaded")
                        Spacer()
                        Image(systemName: modelViewModel.isModelLoaded(model) ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(modelViewModel.isModelLoaded(model) ? .green : .red)
                    }
                }
                
                Section("Actions") {
                    if !model.isDownloaded {
                        Button(action: {
                            modelViewModel.downloadModel(model)
                        }) {
                            HStack {
                                Spacer()
                                Text("Download Model")
                                Spacer()
                            }
                        }
                    } else if !modelViewModel.isModelLoaded(model) {
                        Button(action: {
                            Task {
                                await modelViewModel.loadModel(model)
                            }
                        }) {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                } else {
                                    Text("Load Model")
                                }
                                Spacer()
                            }
                        }
                        .disabled(isLoading)
                    } else {
                        Button(action: {
                            modelViewModel.unloadModel(modelViewModel.getLoadedModel(model)!)
                        }) {
                            HStack {
                                Spacer()
                                Text("Unload Model")
                                Spacer()
                            }
                        }
                    }
                    
                    Button(action: { showConfig = true }) {
                        HStack {
                            Spacer()
                            Text("Configuration")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(model.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showConfig) {
                ModelConfigView(model: model)
                    .environmentObject(modelViewModel)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func formatShape(_ shape: [Int]) -> String {
        return shape.map { String($0) }.joined(separator: "x")
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

struct ModelConfigView: View {
    let model: MLXModel
    @EnvironmentObject var modelViewModel: ModelViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var config: ModelConfig
    
    init(model: MLXModel) {
        self.model = model
        _config = State(initialValue: modelViewModel.getModelConfig(for: model))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Device Settings") {
                    Picker("Device", selection: $config.device) {
                        ForEach(AppState.Settings.Device.allCases, id: \.self) { device in
                            Text(device.rawValue).tag(device)
                        }
                    }
                    
                    Picker("Precision", selection: $config.precision) {
                        ForEach(AppState.Settings.Precision.allCases, id: \.self) { precision in
                            Text(precision.rawValue).tag(precision)
                        }
                    }
                }
                
                Section("Performance") {
                    Picker("Optimization Level", selection: $config.optimizationLevel) {
                        ForEach(ModelMetadata.OptimizationLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    Stepper("Batch Size: \(config.batchSize)", value: $config.batchSize, in: 1...32)
                    
                    Toggle("Enable Caching", isOn: $config.enableCaching)
                }
                
                Section("Advanced") {
                    TextField("Timeout (seconds)", value: $config.timeout, format: .number)
                    
                    Stepper("Warmup Runs: \(config.warmupRuns)", value: $config.warmupRuns, in: 0...10)
                }
            }
            .navigationTitle("Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        modelViewModel.saveModelConfig(config)
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}

#Preview {
    ModelSelectionView()
        .environmentObject(AppState())
        .environmentObject(ModelViewModel())
}
