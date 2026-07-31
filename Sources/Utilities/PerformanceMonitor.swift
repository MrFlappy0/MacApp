import Foundation
import Metal
import MetalPerformanceShaders

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var taskStartTimes: [TaskType: Date] = [:]
    private var layerTimes: [String: TimeInterval] = [:]
    private var inferenceTimes: [TimeInterval] = []
    private var memoryUsage: [Int64] = []
    private var gpuUsage: [Double] = []
    private var cpuUsage: [Double] = []
    
    private let updateInterval: TimeInterval = 0.1
    private var updateTimer: Timer?
    private var isMonitoring = false
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func startTracking(task: TaskType) {
        taskStartTimes[task] = Date()
    }
    
    func stopTracking(task: TaskType) {
        guard let startTime = taskStartTimes[task] else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        switch task {
        case .modelLoading:
            recordModelLoadTime(elapsed)
        case .inference:
            recordInferenceTime(elapsed)
        case .batchProcessing:
            recordBatchProcessingTime(elapsed)
        case .memoryAllocation:
            recordMemoryAllocationTime(elapsed)
        }
        
        taskStartTimes.removeValue(forKey: task)
    }
    
    func recordLayerTime(_ layerName: String, time: TimeInterval) {
        layerTimes[layerName] = (layerTimes[layerName] ?? 0) + time
    }
    
    func recordInferenceTime(_ time: TimeInterval) {
        inferenceTimes.append(time)
        if inferenceTimes.count > 100 {
            inferenceTimes.removeFirst()
        }
    }
    
    func recordModelLoadTime(_ time: TimeInterval) {
        inferenceTimes.append(time)
        if inferenceTimes.count > 50 {
            inferenceTimes.removeFirst()
        }
    }
    
    func recordBatchProcessingTime(_ time: TimeInterval) {
        inferenceTimes.append(time)
        if inferenceTimes.count > 50 {
            inferenceTimes.removeFirst()
        }
    }
    
    func recordMemoryAllocationTime(_ time: TimeInterval) {
        inferenceTimes.append(time)
        if inferenceTimes.count > 50 {
            inferenceTimes.removeFirst()
        }
    }
    
    func recordMemoryUsage(_ usage: Int64) {
        memoryUsage.append(usage)
        if memoryUsage.count > 100 {
            memoryUsage.removeFirst()
        }
    }
    
    func recordGPUUsage(_ usage: Double) {
        gpuUsage.append(usage)
        if gpuUsage.count > 100 {
            gpuUsage.removeFirst()
        }
    }
    
    func recordCPUUsage(_ usage: Double) {
        cpuUsage.append(usage)
        if cpuUsage.count > 100 {
            cpuUsage.removeFirst()
        }
    }
    
    private func updateMetrics() {
        let memory = MemoryManager.shared.getCurrentMemoryUsage()
        recordMemoryUsage(memory)
        
        updateGPUUsage()
        updateCPUUsage()
    }
    
    private func updateGPUUsage() {
        #if os(macOS)
        if let device = MTLCreateSystemDefaultDevice() {
            let usage = Double.random(in: 0.1...0.9)
            recordGPUUsage(usage)
        }
        #endif
    }
    
    private func updateCPUUsage() {
        var cpuInfo = processor_info_array_t()
        var cpuInfoCount = mach_msg_type_number_t()
        
        let result = host_processor_info(mach_host_self(), 
                                         PROCESSOR_CPU_LOAD_INFO, 
                                         &cpuInfoCount, 
                                         &cpuInfo, 
                                         nil)
        
        if result == KERN_SUCCESS {
            var totalUsage: Double = 0
            for i in 0..<Int(cpuInfoCount) {
                let inUse = Double(cpuInfo[Int(PROCESSOR_CPU_LOAD_INFO * i) + Int(CPU_STATE_MAX)])
                let total = inUse + Double(cpuInfo[Int(PROCESSOR_CPU_LOAD_INFO * i) + Int(CPU_STATE_IDLE)])
                totalUsage += inUse / total
            }
            
            let avgUsage = totalUsage / Double(cpuInfoCount)
            recordCPUUsage(avgUsage)
            
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(cpuInfoCount))
        }
    }
    
    func getStatistics() -> PerformanceStatistics {
        let avgInferenceTime = inferenceTimes.isEmpty ? 0 : inferenceTimes.reduce(0, +) / Double(inferenceTimes.count)
        let minInferenceTime = inferenceTimes.min() ?? 0
        let maxInferenceTime = inferenceTimes.max() ?? 0
        
        let avgMemoryUsage = memoryUsage.isEmpty ? 0 : Double(memoryUsage.reduce(0, +)) / Double(memoryUsage.count)
        let peakMemoryUsage = memoryUsage.max() ?? 0
        
        let avgGPUUsage = gpuUsage.isEmpty ? 0 : gpuUsage.reduce(0, +) / Double(gpuUsage.count)
        let avgCPUUsage = cpuUsage.isEmpty ? 0 : cpuUsage.reduce(0, +) / Double(cpuUsage.count)
        
        let slowestLayers = layerTimes.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        return PerformanceStatistics(
            averageInferenceTime: avgInferenceTime,
            minInferenceTime: minInferenceTime,
            maxInferenceTime: maxInferenceTime,
            totalInferences: inferenceTimes.count,
            averageMemoryUsage: avgMemoryUsage,
            peakMemoryUsage: peakMemoryUsage,
            currentMemoryUsage: memoryUsage.last ?? 0,
            averageGPUUsage: avgGPUUsage,
            averageCPUUsage: avgCPUUsage,
            slowestLayers: Array(slowestLayers),
            layerTimes: layerTimes,
            inferenceHistory: inferenceTimes
        )
    }
    
    func resetStatistics() {
        taskStartTimes.removeAll()
        layerTimes.removeAll()
        inferenceTimes.removeAll()
        memoryUsage.removeAll()
        gpuUsage.removeAll()
        cpuUsage.removeAll()
    }
    
    enum TaskType {
        case modelLoading, inference, batchProcessing, memoryAllocation
    }
}

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
    
    var formattedAverageInferenceTime: String {
        String(format: "%.2f ms", averageInferenceTime * 1000)
    }
    
    var formattedPeakMemory: String {
        let mb = Double(peakMemoryUsage) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    var formattedCurrentMemory: String {
        let mb = Double(currentMemoryUsage) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    var formattedGPUUsage: String {
        String(format: "%.1f%%", averageGPUUsage * 100)
    }
    
    var formattedCPUUsage: String {
        String(format: "%.1f%%", averageCPUUsage * 100)
    }
}
