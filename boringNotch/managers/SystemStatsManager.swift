//
//  SystemStatsManager.swift
//  boringNotch
//

import Combine
import Darwin
import Foundation
import SwiftUI

public class SystemStatsManager: ObservableObject {
    public static let shared = SystemStatsManager()

    @Published public var cpuUsage: Double = 0.0
    @Published public var userCpuUsage: Double = 0.0
    @Published public var systemCpuUsage: Double = 0.0

    @Published public var memoryUsedPercentage: Double = 0.0
    @Published public var memoryUsedBytes: UInt64 = 0
    @Published public var memoryTotalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory

    @Published public var chipName: String = "Apple Silicon"
    @Published public var coreCount: Int = ProcessInfo.processInfo.activeProcessorCount
    @Published public var uptimeString: String = ""

    private var previousCpuTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    private var timer: AnyCancellable?
    private var isMonitoring: Bool = false

    private init() {
        fetchChipName()
        refreshStats()
        startMonitoring()
    }

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        refreshStats()
        timer = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshStats()
            }
    }

    public func stopMonitoring() {
        isMonitoring = false
        timer?.cancel()
        timer = nil
    }

    public func refreshStats() {
        updateCpuUsage()
        updateMemoryUsage()
        updateUptime()
    }

    private func updateCpuUsage() {
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let userTicks = cpuLoadInfo.cpu_ticks.0
        let systemTicks = cpuLoadInfo.cpu_ticks.1
        let idleTicks = cpuLoadInfo.cpu_ticks.2
        let niceTicks = cpuLoadInfo.cpu_ticks.3

        if let prev = previousCpuTicks {
            let userDiff = Double(userTicks >= prev.user ? userTicks - prev.user : 0)
            let systemDiff = Double(systemTicks >= prev.system ? systemTicks - prev.system : 0)
            let idleDiff = Double(idleTicks >= prev.idle ? idleTicks - prev.idle : 0)
            let niceDiff = Double(niceTicks >= prev.nice ? niceTicks - prev.nice : 0)

            let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
            if totalTicks > 0 {
                let currentCpu = ((userDiff + systemDiff + niceDiff) / totalTicks) * 100.0
                let currentUser = (userDiff / totalTicks) * 100.0
                let currentSystem = (systemDiff / totalTicks) * 100.0

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.cpuUsage = min(100.0, max(0.0, currentCpu))
                    self.userCpuUsage = min(100.0, max(0.0, currentUser))
                    self.systemCpuUsage = min(100.0, max(0.0, currentSystem))
                }
            }
        }

        previousCpuTicks = (user: userTicks, system: systemTicks, idle: idleTicks, nice: niceTicks)
    }

    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        let active = UInt64(stats.active_count) * UInt64(pageSize)
        let wired = UInt64(stats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(stats.compressor_page_count) * UInt64(pageSize)

        let used = active + wired + compressed
        let total = ProcessInfo.processInfo.physicalMemory

        let percentage = total > 0 ? (Double(used) / Double(total)) * 100.0 : 0.0

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.memoryUsedBytes = used
            self.memoryTotalBytes = total
            self.memoryUsedPercentage = min(100.0, max(0.0, percentage))
        }
    }

    private func updateUptime() {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60

        if days > 0 {
            uptimeString = "\(days)d \(hours)h"
        } else if hours > 0 {
            uptimeString = "\(hours)h \(minutes)m"
        } else {
            uptimeString = "\(minutes)m"
        }
    }

    private func fetchChipName() {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        if size > 0 {
            var machine = [CChar](repeating: 0, count: size)
            if sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0) == 0 {
                let name = String(cString: machine).trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    self.chipName = name
                    return
                }
            }
        }
        self.chipName = "Apple Silicon"
    }

    public var formattedMemoryString: String {
        let usedGB = Double(memoryUsedBytes) / (1024 * 1024 * 1024)
        let totalGB = Double(memoryTotalBytes) / (1024 * 1024 * 1024)
        return String(format: "%.1f / %.0f GB", usedGB, totalGB)
    }
}
