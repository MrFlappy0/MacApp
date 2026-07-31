import SwiftUI
import Charts

struct PerformanceView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var modelViewModel: ModelViewModel
    
    @StateObject private var inferenceViewModel = InferenceViewModel()
    
    @State private var selectedTimeRange: TimeRange = .lastMinute
    @State private var refreshInterval: TimeInterval = 1.0
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SummaryCards()
                    
                    Divider()
                    
                    ChartsSection()
                    
                    Divider()
                    
                    DetailedStats()
                }
                .padding()
            }
            .navigationTitle("Performance")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        
                        Divider()
                        
                        Button("Reset Statistics") {
                            PerformanceMonitor.shared.resetStatistics()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .onAppear {
                startRefreshTimer()
            }
            .onDisappear {
                stopRefreshTimer()
            }
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            // Refresh data
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

struct SummaryCards: View {
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    
    var body: some View {
        let stats = inferenceViewModel.getPerformanceStatistics()
        let memoryReport = inferenceViewModel.getMemoryReport()
        
        HStack(spacing: 20) {
            CardView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inference Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(stats.formattedAverageInferenceTime)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            CardView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(memoryReport.formattedCurrentMemory)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(memoryReport.formattedUsagePercentage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            CardView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Inferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(stats.totalInferences))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Count")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            CardView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GPU Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(stats.formattedGPUUsage)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
    }
}

struct ChartsSection: View {
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            ChartCard {
                InferenceTimeChart()
            } title: {
                Text("Inference Time History")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                ChartCard {
                    MemoryUsageChart()
                } title: {
                    Text("Memory Usage")
                        .font(.headline)
                }
                
                ChartCard {
                    CPUUsageChart()
                } title: {
                    Text("CPU/GPU Usage")
                        .font(.headline)
                }
            }
        }
    }
}

struct ChartCard<Content: View>: View {
    let content: Content
    let title: AnyView
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder title: () -> some View) {
        self.content = content()
        self.title = AnyView(title())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            title
            
            content
                .frame(height: 200)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct InferenceTimeChart: View {
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    
    var body: some View {
        let stats = inferenceViewModel.getPerformanceStatistics()
        
        Chart {
            ForEach(Array(stats.inferenceHistory.enumerated()), id: \.offset) { index, time in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Time (ms)", time * 1000)
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }
}

struct MemoryUsageChart: View {
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    
    var body: some View {
        let memoryReport = inferenceViewModel.getMemoryReport()
        
        Chart {
            BarMark(
                x: .value("Usage", "Current"),
                y: .value("MB", Double(memoryReport.usedMemory) / (1024 * 1024))
            )
            
            BarMark(
                x: .value("Usage", "Peak"),
                y: .value("MB", Double(memoryReport.peakMemory) / (1024 * 1024))
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

struct CPUUsageChart: View {
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    
    var body: some View {
        let stats = inferenceViewModel.getPerformanceStatistics()
        
        Chart {
            BarMark(
                x: .value("Device", "CPU"),
                y: .value("%", stats.averageCPUUsage * 100)
            )
            
            BarMark(
                x: .value("Device", "GPU"),
                y: .value("%", stats.averageGPUUsage * 100)
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

struct DetailedStats: View {
    @EnvironmentObject var inferenceViewModel: InferenceViewModel
    
    var body: some View {
        let stats = inferenceViewModel.getPerformanceStatistics()
        let memoryReport = inferenceViewModel.getMemoryReport()
        
        VStack(spacing: 20) {
            SectionView(title: "Inference Statistics") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        StatRow(label: "Average Time", value: stats.formattedAverageInferenceTime)
                        StatRow(label: "Min Time", value: String(format: "%.2f ms", stats.minInferenceTime * 1000))
                    }
                    
                    GridRow {
                        StatRow(label: "Max Time", value: String(format: "%.2f ms", stats.maxInferenceTime * 1000))
                        StatRow(label: "Total Inferences", value: String(stats.totalInferences))
                    }
                }
            }
            
            SectionView(title: "Memory Statistics") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        StatRow(label: "Current Usage", value: memoryReport.formattedCurrentMemory)
                        StatRow(label: "Peak Usage", value: memoryReport.formattedPeakMemory)
                    }
                    
                    GridRow {
                        StatRow(label: "Usage Percentage", value: memoryReport.formattedUsagePercentage)
                        StatRow(label: "Registered Models", value: String(memoryReport.registeredModels))
                    }
                }
            }
            
            SectionView(title: "System Statistics") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        StatRow(label: "CPU Usage", value: stats.formattedCPUUsage)
                        StatRow(label: "GPU Usage", value: stats.formattedGPUUsage)
                    }
                }
            }
            
            if !stats.slowestLayers.isEmpty {
                SectionView(title: "Slowest Layers") {
                    ForEach(stats.slowestLayers, id: \.self) { layerName in
                        if let time = stats.layerTimes[layerName] {
                            HStack {
                                Text(layerName)
                                Spacer()
                                Text(String(format: "%.2f ms", time * 1000))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatRow: View {
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

enum TimeRange: String, CaseIterable {
    case lastMinute = "Last Minute"
    case last5Minutes = "Last 5 Minutes"
    case lastHour = "Last Hour"
    case allTime = "All Time"
}

#Preview {
    PerformanceView()
        .environmentObject(AppState())
        .environmentObject(ModelViewModel())
}
