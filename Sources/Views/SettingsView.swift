import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Form {
                GeneralSettings()
                
                Divider()
                
                PerformanceSettings()
                
                Divider()
                
                AdvancedSettings()
                
                Divider()
                
                AboutSection()
            }
            .navigationTitle("Settings")
            .frame(minWidth: 600, minHeight: 500)
        }
    }
}

struct GeneralSettings: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Section("General") {
            Toggle("Auto Load Models", isOn: $appState.settings.autoLoadModels)
                .help("Automatically load models when the app starts")
            
            Toggle("Show Performance Monitor", isOn: $appState.settings.showPerformanceMonitor)
                .help("Show performance monitoring in the status bar")
        }
    }
}

struct PerformanceSettings: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Section("Performance") {
            Picker("Device", selection: $appState.settings.device) {
                ForEach(AppState.Settings.Device.allCases, id: \.self) { device in
                    Text(device.rawValue).tag(device)
                }
            }
            .help("Select the device to use for inference")
            
            Picker("Precision", selection: $appState.settings.precision) {
                ForEach(AppState.Settings.Precision.allCases, id: \.self) { precision in
                    Text(precision.rawValue).tag(precision)
                }
            }
            .help("Select the precision for inference")
            
            Stepper("Batch Size: \(appState.settings.batchSize)", 
                   value: $appState.settings.batchSize, 
                   in: 1...32)
            .help("Number of inputs to process in each batch")
            
            Toggle("Optimize Memory", isOn: $appState.settings.optimizeMemory)
                .help("Automatically optimize memory usage")
            
            Toggle("Use Metal Acceleration", isOn: $appState.settings.useMetalAcceleration)
                .help("Use Metal for hardware acceleration")
        }
    }
}

struct AdvancedSettings: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Section("Advanced") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Presets")
                    .font(.headline)
                
                ForEach(ModelConfigPreset.presets, id: \.name) { preset in
                    Button(action: {
                        applyPreset(preset)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .font(.subheadline)
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .help("Reset all settings to default values")
        }
    }
    
    private func applyPreset(_ preset: ModelConfigPreset) {
        appState.settings.device = preset.config.device
        appState.settings.precision = preset.config.precision
        appState.settings.batchSize = preset.config.batchSize
        appState.settings.optimizeMemory = preset.config.enableCaching
        appState.settings.useMetalAcceleration = (preset.config.device == .mps || preset.config.device == .gpu)
    }
    
    private func resetToDefaults() {
        appState.settings = AppState.Settings()
    }
}

struct AboutSection: View {
    var body: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                Text("MLX Mac App")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("A powerful Mac application for running MLX models with optimization and performance monitoring.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/MrFlappy0/MacApp")!)
                
                Text("Built with SwiftUI and MLX")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
