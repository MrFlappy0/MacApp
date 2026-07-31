import SwiftUI
import UniformTypeIdentifiers

struct InferenceView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    @StateObject private var inferenceViewModel = InferenceViewModel()
    
    @State private var selectedModel: MLXModel?
    @State private var inputText = ""
    @State private var selectedInputType: InferenceViewModel.InputType = .text
    @State private var showingImageImporter = false
    @State private var showingResultDetail = false
    @State private var selectedResult: InferenceResult?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ModelSelectorView(selectedModel: $selectedModel)
                
                Divider()
                
                InputView(selectedModel: selectedModel, 
                          inputText: $inputText,
                          selectedInputType: $selectedInputType,
                          showingImageImporter: $showingImageImporter)
                
                Divider()
                
                ActionButtonsView(selectedModel: selectedModel,
                                  inputText: inputText,
                                  selectedInputType: selectedInputType)
                
                Divider()
                
                ResultsView(results: inferenceViewModel.results,
                           selectedResult: $selectedResult,
                           showingResultDetail: $showingResultDetail)
            }
            .navigationTitle("Inference")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: inferenceViewModel.clearResults) {
                        Image(systemName: "trash")
                    }
                    .help("Clear Results")
                    .disabled(inferenceViewModel.results.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showingImageImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                handleImageImport(result: result)
            }
            .sheet(item: $selectedResult) { result in
                ResultDetailView(result: result)
            }
            .overlay {
                if inferenceViewModel.isRunning {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        if inferenceViewModel.totalBatches > 0 {
                            Text("Batch \(inferenceViewModel.currentBatch)/\(inferenceViewModel.totalBatches)")
                                .font(.caption)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                }
            }
        }
    }
    
    private func handleImageImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                Task {
                    if let imageData = try? Data(contentsOf: url) {
                        let input = inferenceViewModel.createImageInput(imageData)
                        await runInference(with: input)
                    }
                }
            }
        case .failure(let error):
            appState.showError(error.localizedDescription)
        }
    }
    
    private func runInference(with input: InferenceInput) async {
        guard let model = selectedModel else {
            appState.showError("Please select a model first")
            return
        }
        
        guard let loadedModel = modelViewModel.getLoadedModel(model) else {
            appState.showError("Model is not loaded. Please load the model first.")
            return
        }
        
        await inferenceViewModel.runInference(
            model: loadedModel,
            input: input,
            settings: appState.settings
        )
    }
}

struct ModelSelectorView: View {
    @EnvironmentObject var modelViewModel: ModelViewModel
    @Binding var selectedModel: MLXModel?
    
    var body: some View {
        HStack {
            Picker("Select Model", selection: $selectedModel) {
                Text("Select a model...").tag(nil as MLXModel?)
                
                ForEach(modelViewModel.getDownloadedModels()) { model in
                    Text(model.name).tag(model as MLXModel?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 300)
            
            if let model = selectedModel {
                if modelViewModel.isModelLoaded(model) {
                    Text("✓ Loaded")
                        .foregroundColor(.green)
                } else {
                    Button("Load") {
                        Task {
                            await modelViewModel.loadModel(model)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct InputView: View {
    let selectedModel: MLXModel?
    @Binding var inputText: String
    @Binding var selectedInputType: InferenceViewModel.InputType
    @Binding var showingImageImporter: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let model = selectedModel {
                let inputType = InferenceViewModel().getInputType(for: model)
                
                switch inputType {
                case .text:
                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Input Type: Text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                case .image:
                    VStack {
                        Button(action: { showingImageImporter = true }) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.accentColor)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.accentColor, lineWidth: 2)
                                        .frame(width: 100, height: 100)
                                )
                        }
                        
                        Text("Click to select image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    
                case .audio:
                    VStack {
                        Image(systemName: "mic")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor, lineWidth: 2)
                                    .frame(width: 100, height: 100)
                            )
                        
                        Text("Audio input not yet implemented")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    
                case .tensor:
                    Text("Tensor input not yet implemented")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                Text("Please select a model to see input options")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.vertical)
    }
}

struct ActionButtonsView: View {
    let selectedModel: MLXModel?
    let inputText: String
    let selectedInputType: InferenceViewModel.InputType
    
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    if let model = selectedModel {
                        let input = InferenceViewModel().createTextInput(inputText)
                        await inferenceViewModel.runInference(
                            model: modelViewModel.getLoadedModel(model)!,
                            input: input,
                            settings: AppState().settings
                        )
                    }
                }
            }) {
                Text("Run Inference")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut("R", modifiers: [.command])
            .disabled(selectedModel == nil || inputText.isEmpty)
            
            Button(action: {
                Task {
                    if let model = selectedModel {
                        let input = InferenceViewModel().createTextInput(inputText)
                        await inferenceViewModel.runBatchInference(
                            model: modelViewModel.getLoadedModel(model)!,
                            inputs: [input],
                            settings: AppState().settings
                        )
                    }
                }
            }) {
                Text("Batch Inference")
                    .frame(maxWidth: .infinity)
            }
            .disabled(selectedModel == nil || inputText.isEmpty)
        }
        .padding()
    }
}

struct ResultsView: View {
    let results: [InferenceResult]
    @Binding var selectedResult: InferenceResult?
    @Binding var showingResultDetail: Bool
    
    var body: some View {
        List(results) { result in
            ResultRow(result: result)
                .onTapGesture {
                    selectedResult = result
                    showingResultDetail = true
                }
        }
        .listStyle(.plain)
        .overlay {
            if results.isEmpty {
                Text("No inference results yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ResultRow: View {
    let result: InferenceResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.modelName)
                    .font(.headline)
                Spacer()
                Text(result.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.input)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(result.output)
                .font(.body)
                .padding(.top, 4)
            
            HStack {
                Text(result.formattedMemory)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(result.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
}

struct ResultDetailView: View {
    let result: InferenceResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    InfoRow(label: "Name", value: result.modelName)
                }
                
                Section("Input") {
                    Text(result.input)
                        .font(.body)
                        .textSelection(.enabled)
                }
                
                Section("Output") {
                    Text(result.output)
                        .font(.body)
                        .textSelection(.enabled)
                }
                
                Section("Performance") {
                    InfoRow(label: "Inference Time", value: result.formattedTime)
                    InfoRow(label: "Memory Used", value: result.formattedMemory)
                    InfoRow(label: "Timestamp", value: result.timestamp.formatted())
                }
                
                Section("Technical Details") {
                    InfoRow(label: "Layers Processed", value: String(result.layersProcessed))
                    InfoRow(label: "Parameters", value: String(result.parameters))
                    InfoRow(label: "Device", value: deviceName(result.device))
                    InfoRow(label: "Precision", value: precisionName(result.precision))
                }
            }
            .navigationTitle("Inference Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func deviceName(_ device: DeviceType) -> String {
        switch device {
        case .auto: return "Auto"
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .mps: return "MPS (Metal)"
        }
    }
    
    private func precisionName(_ precision: PrecisionType) -> String {
        switch precision {
        case .float32: return "Float 32"
        case .float16: return "Float 16"
        case .int8: return "Int 8"
        }
    }
}

#Preview {
    InferenceView()
        .environmentObject(AppState())
        .environmentObject(ModelViewModel())
}
