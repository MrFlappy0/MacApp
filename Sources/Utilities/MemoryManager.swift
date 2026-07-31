import Foundation
import Metal

class MemoryManager {
    static let shared = MemoryManager()
    
    private var registeredModels: [String: MLXLoadedModel] = [:]
    private var memoryUsage: [String: Int64] = [:]
    private var totalAllocated: Int64 = 0
    private var peakMemory: Int64 = 0
    
    private let memoryWarningThreshold: Int64 = 8 * 1024 * 1024 * 1024
    private let memoryCriticalThreshold: Int64 = 12 * 1024 * 1024 * 1024
    
    private var memoryWarningHandler: (() -> Void)?
    private var memoryCriticalHandler: (() -> Void)?
    
    private init() {}
    
    func registerModel(_ model: MLXLoadedModel, key: String) {
        registeredModels[key] = model
        memoryUsage[key] = model.memoryUsage
        totalAllocated += model.memoryUsage
        
        updatePeakMemory()
        checkMemoryThresholds()
    }
    
    func unregisterModel(_ model: MLXLoadedModel, key: String) {
        if let usage = memoryUsage[key] {
            totalAllocated -= usage
            memoryUsage.removeValue(forKey: key)
            registeredModels.removeValue(forKey: key)
        }
    }
    
    func getCurrentMemoryUsage() -> Int64 {
        return totalAllocated
    }
    
    func getPeakMemoryUsage() -> Int64 {
        return peakMemory
    }
    
    func getModelMemoryUsage(_ key: String) -> Int64? {
        return memoryUsage[key]
    }
    
    func getAllModelsMemoryUsage() -> [String: Int64] {
        return memoryUsage
    }
    
    func getAvailableMemory() -> Int64 {
        #if os(macOS)
        var size: vm_size_t = 0
        var address: vm_address_t = 0
        var count: mach_msg_type_number_t = 0
        var object_name: vm_region_basic_info_data_64_t = vm_region_basic_info_data_64_t()
        var object_count = mach_msg_type_number_t(MemoryLayout<vm_region_basic_info_data_64_t>.stride / MemoryLayout<integer_t>.stride)
        
        var result = vm_region_64(vm_map_t(mach_task_self_), 
                                 &address, 
                                 &size, 
                                 VM_REGION_BASIC_INFO_64, 
                                 &object_name, 
                                 &object_count, 
                                 &count)
        
        var freeMemory: Int64 = 0
        while result == KERN_SUCCESS {
            if object_name.protection == VM_PROT_NONE {
                freeMemory += Int64(size)
            }
            address += size
            result = vm_region_64(vm_map_t(mach_task_self_), 
                                 &address, 
                                 &size, 
                                 VM_REGION_BASIC_INFO_64, 
                                 &object_name, 
                                 &object_count, 
                                 &count)
        }
        
        return freeMemory
        #else
        return 0
        #endif
    }
    
    func getTotalSystemMemory() -> Int64 {
        #if os(macOS)
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return Int64(totalMemory)
        #else
        return 0
        #endif
    }
    
    func getMemoryUsagePercentage() -> Double {
        let total = getTotalSystemMemory()
        guard total > 0 else { return 0 }
        return Double(totalAllocated) / Double(total) * 100.0
    }
    
    func cleanupUnusedModels() {
        let modelsToRemove = registeredModels.filter { key, model in
            model.model.lastUsed == nil || 
            Date().timeIntervalSince(model.model.lastUsed!) > 3600
        }
        
        for (key, model) in modelsToRemove {
            unregisterModel(model, key: key)
        }
    }
    
    func cleanupAllModels() {
        for (key, model) in registeredModels {
            unregisterModel(model, key: key)
        }
        registeredModels.removeAll()
        memoryUsage.removeAll()
        totalAllocated = 0
    }
    
    func optimizeMemoryUsage() {
        let sortedModels = registeredModels.sorted { $0.value.memoryUsage < $1.value.memoryUsage }
        
        var modelsToUnload: [String] = []
        var currentUsage = totalAllocated
        
        for (key, model) in sortedModels {
            if currentUsage < memoryWarningThreshold {
                break
            }
            
            modelsToUnload.append(key)
            currentUsage -= model.memoryUsage
        }
        
        for key in modelsToUnload {
            if let model = registeredModels[key] {
                unregisterModel(model, key: key)
            }
        }
    }
    
    func setMemoryWarningHandler(_ handler: @escaping () -> Void) {
        memoryWarningHandler = handler
    }
    
    func setMemoryCriticalHandler(_ handler: @escaping () -> Void) {
        memoryCriticalHandler = handler
    }
    
    private func updatePeakMemory() {
        peakMemory = max(peakMemory, totalAllocated)
    }
    
    private func checkMemoryThresholds() {
        if totalAllocated > memoryCriticalThreshold {
            memoryCriticalHandler?()
        } else if totalAllocated > memoryWarningThreshold {
            memoryWarningHandler?()
        }
    }
    
    func getMemoryReport() -> MemoryReport {
        let total = getTotalSystemMemory()
        let available = getAvailableMemory()
        let used = totalAllocated
        let percentage = getMemoryUsagePercentage()
        
        return MemoryReport(
            totalSystemMemory: total,
            availableMemory: available,
            usedMemory: used,
            peakMemory: peakMemory,
            usagePercentage: percentage,
            registeredModels: registeredModels.count,
            modelDetails: registeredModels.mapValues { model in
                ModelMemoryInfo(
                    name: model.model.name,
                    memoryUsage: model.memoryUsage,
                    lastUsed: model.model.lastUsed
                )
            }
        )
    }
}

struct MemoryReport {
    let totalSystemMemory: Int64
    let availableMemory: Int64
    let usedMemory: Int64
    let peakMemory: Int64
    let usagePercentage: Double
    let registeredModels: Int
    let modelDetails: [String: ModelMemoryInfo]
    
    var formattedTotalMemory: String {
        let gb = Double(totalSystemMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f GB", gb)
    }
    
    var formattedUsedMemory: String {
        let mb = Double(usedMemory) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    var formattedPeakMemory: String {
        let mb = Double(peakMemory) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    var formattedUsagePercentage: String {
        String(format: "%.1f%%", usagePercentage)
    }
}

struct ModelMemoryInfo {
    let name: String
    let memoryUsage: Int64
    let lastUsed: Date?
    
    var formattedMemoryUsage: String {
        let mb = Double(memoryUsage) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
}
