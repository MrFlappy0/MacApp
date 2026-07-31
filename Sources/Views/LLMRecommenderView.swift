import SwiftUI

struct LLMRecommenderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    @State private var selectedMode: LLMRecommendationMode = .smart
    @State private var recommendations: [LLMRecommendation] = []
    @State private var systemInfo: SystemInfo = SystemInfo()
    @State private var isLoading: Bool = true
    @State private var selectedRecommendation: LLMRecommendation?
    @State private var showDetailView: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête
                headerSection
                
                // Sélecteur de mode
                modeSelectorSection
                
                // Informations système
                systemInfoSection
                
                // Recommandations
                if isLoading {
                    loadingView
                } else if recommendations.isEmpty {
                    emptyView
                } else {
                    recommendationsSection
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recommandation LLM")
        .navigationSubtitle("Trouvez le meilleur modèle pour votre Mac")
        .sheet(item: $selectedRecommendation) { recommendation in
            LLMRecommendationDetailView(recommendation: recommendation, systemInfo: systemInfo)
        }
        .onAppear {
            loadRecommendations()
        }
        .onChange(of: selectedMode) { _ in
            loadRecommendations()
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🤖 Recommandation LLM")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Découvrez les meilleurs modèles de langage pour votre configuration matérielle.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var modeSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mode de recommandation")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(LLMRecommendationMode.allCases) { mode in
                    ModeSelectionCard(mode: mode, isSelected: selectedMode == mode) {
                        selectedMode = mode
                    }
                }
            }
            
            // Description du mode sélectionné
            Text(selectedMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Votre configuration")
                .font(.headline)
            
            HStack(spacing: 16) {
                SystemInfoCard(icon: "memorychip", title: "Mémoire", value: systemInfo.formattedTotalMemory, subtitle: "Disponible: \(systemInfo.formattedAvailableMemory)")
                
                SystemInfoCard(icon: "cpu", title: "CPU", value: "\(systemInfo.cpuCores) cœurs", subtitle: systemInfo.cpuType)
                
                SystemInfoCard(icon: "gpu", title: "GPU", value: systemInfo.gpuName, subtitle: systemInfo.isAppleSilicon ? "Apple Silicon" : "Intel")
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommandations (\(recommendations.count))")
                .font(.headline)
            
            ForEach(recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation, systemInfo: systemInfo)
                    .onTapGesture {
                        selectedRecommendation = recommendation
                    }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            Text("Analyse de votre configuration...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(40)
    }
    
    private var emptyView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Aucune recommandation disponible")
                .font(.headline)
                .padding(.top, 8)
            
            Text("Aucun modèle LLM compatible n'a été trouvé pour votre configuration.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(40)
    }
    
    // MARK: - Methods
    
    private func loadRecommendations() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recommendations = LLMRecommender.shared.getRecommendations(for: selectedMode)
            isLoading = false
        }
    }
}

// MARK: - Subviews

struct ModeSelectionCard: View {
    let mode: LLMRecommendationMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: modeIcon(for: mode))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 100, height: 80)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.displayName)
    }
    
    private func modeIcon(for mode: LLMRecommendationMode) -> String {
        switch mode {
        case .smart: return "bolt.fill"
        case .balanced: return "scale.2d"
        case .powerful: return "flame.fill"
        }
    }
}

struct SystemInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(value)
                .font(.headline)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(minWidth: 120)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct RecommendationCard: View {
    let recommendation: LLMRecommendation
    let systemInfo: SystemInfo
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icône et rang
            VStack(alignment: .center, spacing: 4) {
                Text("#1")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Informations du modèle
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(recommendation.model.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(recommendation.temperatureDescription)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(recommendation.estimatedTemperature < 30 ? Color.green.opacity(0.2) : 
                                   recommendation.estimatedTemperature < 50 ? Color.yellow.opacity(0.2) : 
                                   Color.red.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(recommendation.model.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Métriques
                HStack(spacing: 16) {
                    MetricView(icon: "memorychip", value: recommendation.formattedMemoryUsage, label: "Mémoire")
                    MetricView(icon: "speedometer", value: recommendation.formattedSpeed, label: "Vitesse")
                    MetricView(icon: "number", value: recommendation.model.formattedParameters, label: "Params")
                }
                .padding(.top, 4)
                
                // Raison
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .hoverEffect(.highlight)
        .transition(.opacity)
    }
}

struct MetricView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Detail View

struct LLMRecommendationDetailView: View {
    let recommendation: LLMRecommendation
    let systemInfo: SystemInfo
    
    @Environment(\dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // En-tête
                    headerSection
                    
                    // Informations du modèle
                    modelInfoSection
                    
                    // Métriques détaillées
                    metricsSection
                    
                    // Comparaison avec d'autres modes
                    comparisonSection
                    
                    // Actions
                    actionsSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(recommendation.model.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "server.rack")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(width: 48, height: 48)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.model.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(recommendation.mode.displayName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(recommendation.temperatureDescription)
                    .font(.title2)
            }
            
            Text(recommendation.model.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informations du modèle")
                .font(.headline)
            
            InfoRow(icon: "doc.text", label: "Catégorie", value: recommendation.model.category.rawValue)
            InfoRow(icon: "person", label: "Auteur", value: recommendation.model.author)
            InfoRow(icon: "tag", label: "Version", value: recommendation.model.version)
            InfoRow(icon: "doc.text", label: "Licence", value: recommendation.model.license)
        }
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Métriques de performance")
                .font(.headline)
            
            HStack(spacing: 16) {
                MetricCard(icon: "memorychip", title: "Mémoire estimée", value: recommendation.formattedMemoryUsage, color: .blue)
                MetricCard(icon: "speedometer", title: "Vitesse estimée", value: recommendation.formattedSpeed, color: .green)
                MetricCard(icon: "thermometer", title: "Température", value: String(format: "%.0f°C", recommendation.estimatedTemperature), color: temperatureColor)
            }
            
            HStack(spacing: 16) {
                MetricCard(icon: "number", title: "Paramètres", value: recommendation.model.formattedParameters, color: .purple)
                MetricCard(icon: "clock", title: "Score", value: String(format: "%.1f/10", recommendation.score * 10), color: .orange)
            }
        }
    }
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comparaison avec d'autres modes")
                .font(.headline)
            
            let allRecommendations = LLMRecommender.shared.getAllBestRecommendations()
            
            ForEach(LLMRecommendationMode.allCases) { mode in
                if let rec = allRecommendations[mode] {
                    ComparisonRow(
                        mode: mode,
                        isCurrent: mode == recommendation.mode,
                        modelName: rec.model.name,
                        memory: rec.formattedMemoryUsage,
                        speed: rec.formattedSpeed,
                        score: String(format: "%.1f", rec.score * 10)
                    )
                }
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button(action: {
                    // Charger le modèle
                    modelViewModel.loadModel(recommendation.model)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                        Text("Charger le modèle")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button(action: {
                    // Voir les détails du modèle
                    modelViewModel.selectedModel = recommendation.model
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                        Text("Plus d'infos")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
    
    private var temperatureColor: Color {
        if recommendation.estimatedTemperature < 30 {
            return .green
        } else if recommendation.estimatedTemperature < 50 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ComparisonRow: View {
    let mode: LLMRecommendationMode
    let isCurrent: Bool
    let modelName: String
    let memory: String
    let speed: String
    let score: String
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(modelName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(memory)
                .font(.subheadline)
                .frame(width: 80, alignment: .trailing)
            
            Text(speed)
                .font(.subheadline)
                .frame(width: 80, alignment: .trailing)
            
            Text(score)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(12)
        .background(isCurrent ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            isCurrent ?
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2) : nil
        )
    }
}

// MARK: - Preview

#Preview {
    LLMRecommenderView()
        .environmentObject(AppState())
        .environmentObject(ModelViewModel())
}
