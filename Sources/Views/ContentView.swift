import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            switch appState.currentTab {
            case .models:
                ModelSelectionView()
            case .inference:
                InferenceView()
            case .performance:
                PerformanceView()
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ToolbarButtons()
            }
        }
        .overlay {
            if let error = appState.errorMessage {
                ErrorMessageView(message: error)
            }
        }
        .onAppear {
            PerformanceMonitor.shared.startMonitoring()
        }
        .onDisappear {
            PerformanceMonitor.shared.stopMonitoring()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(selection: $appState.currentTab) {
            Section("Main") {
                NavigationLink(value: AppState.Tab.models) {
                    Label("Models", systemImage: "cube")
                }
                .tag(AppState.Tab.models)
                
                NavigationLink(value: AppState.Tab.inference) {
                    Label("Inference", systemImage: "bolt")
                }
                .tag(AppState.Tab.inference)
            }
            
            Section("Tools") {
                NavigationLink(value: AppState.Tab.performance) {
                    Label("Performance", systemImage: "chart.bar")
                }
                .tag(AppState.Tab.performance)
                
                NavigationLink(value: AppState.Tab.settings) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppState.Tab.settings)
            }
        }
        .navigationTitle("MLX Mac App")
        .listStyle(.sidebar)
    }
}

struct ToolbarButtons: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: "plus")
        }
        .help("Add Model")
        
        Button(action: {}) {
            Image(systemName: "folder")
        }
        .help("Open Model")
        
        Button(action: {
            modelViewModel.unloadAllModels()
        }) {
            Image(systemName: "trash")
        }
        .help("Clear Cache")
        .disabled(modelViewModel.loadedModels.isEmpty)
    }
}

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(message)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()
                .transition(.slide)
                .animation(.easeInOut, value: message)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ModelViewModel())
}
