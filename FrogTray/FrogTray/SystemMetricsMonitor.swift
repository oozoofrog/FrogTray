//
//  SystemMetricsMonitor.swift
//  FrogTray
//
//  Created by Codex on 3/11/26.
//

import Combine
import Foundation
import Darwin

struct SystemSnapshot {
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let memoryUsedBytes: UInt64
    let memoryTotalBytes: UInt64
    let diskUsedBytes: Int64
    let diskTotalBytes: Int64
    let lastUpdated: Date

    static let placeholder = SystemSnapshot(
        cpuUsage: 0,
        memoryUsage: 0,
        diskUsage: 0,
        memoryUsedBytes: 0,
        memoryTotalBytes: ProcessInfo.processInfo.physicalMemory,
        diskUsedBytes: 0,
        diskTotalBytes: 0,
        lastUpdated: .now
    )

    var menuBarTitle: String {
        "C\(cpuUsage.percentText) M\(memoryUsage.percentText) D\(diskUsage.percentText)"
    }

    var memoryUsedText: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsedBytes), countStyle: .memory)
    }

    var memoryTotalText: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryTotalBytes), countStyle: .memory)
    }

    var diskUsedText: String {
        ByteCountFormatter.string(fromByteCount: diskUsedBytes, countStyle: .file)
    }

    var diskTotalText: String {
        ByteCountFormatter.string(fromByteCount: diskTotalBytes, countStyle: .file)
    }
}

@MainActor
final class SystemMetricsMonitor: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot.placeholder

    private var timerCancellable: AnyCancellable?
    private var previousCPUTicks: [UInt32]?

    init(refreshInterval: TimeInterval = 2) {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refresh()
        }

        timerCancellable = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    func refresh() {
        let cpuUsage = readCPUUsage() ?? snapshot.cpuUsage
        let memorySample = readMemorySample() ?? (snapshot.memoryUsage, snapshot.memoryUsedBytes, snapshot.memoryTotalBytes)
        let diskSample = readDiskSample() ?? (snapshot.diskUsage, snapshot.diskUsedBytes, snapshot.diskTotalBytes)

        snapshot = SystemSnapshot(
            cpuUsage: cpuUsage,
            memoryUsage: memorySample.0,
            diskUsage: diskSample.0,
            memoryUsedBytes: memorySample.1,
            memoryTotalBytes: memorySample.2,
            diskUsedBytes: diskSample.1,
            diskTotalBytes: diskSample.2,
            lastUpdated: .now
        )
    }

    private func readCPUUsage() -> Double? {
        var cpuInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &cpuInfo) { cpuInfoPointer in
            cpuInfoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        let currentTicks = [
            cpuInfo.cpu_ticks.0,
            cpuInfo.cpu_ticks.1,
            cpuInfo.cpu_ticks.2,
            cpuInfo.cpu_ticks.3,
        ]

        guard let previousCPUTicks else {
            self.previousCPUTicks = currentTicks
            return nil
        }

        self.previousCPUTicks = currentTicks

        let deltas = zip(currentTicks, previousCPUTicks).map { current, previous in
            Double(current) - Double(previous)
        }

        let totalTicks = deltas.reduce(0, +)
        guard totalTicks > 0 else {
            return nil
        }

        let busyTicks =
            deltas[Int(CPU_STATE_USER)] +
            deltas[Int(CPU_STATE_SYSTEM)] +
            deltas[Int(CPU_STATE_NICE)]

        return max(0, min(busyTicks / totalTicks, 1))
    }

    private func readMemorySample() -> (Double, UInt64, UInt64)? {
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &vmStats) { vmStatsPointer in
            vmStatsPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let usedBytes =
            (UInt64(vmStats.active_count) +
             UInt64(vmStats.wire_count) +
             UInt64(vmStats.compressor_page_count) +
             UInt64(vmStats.speculative_count)) * pageSize

        let totalBytes = ProcessInfo.processInfo.physicalMemory
        guard totalBytes > 0 else {
            return nil
        }

        let clampedUsedBytes = min(usedBytes, totalBytes)
        let usage = Double(clampedUsedBytes) / Double(totalBytes)

        return (usage, clampedUsedBytes, totalBytes)
    }

    private func readDiskSample() -> (Double, Int64, Int64)? {
        let volumeURL = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeTotalCapacityKey,
        ]

        guard let values = try? volumeURL.resourceValues(forKeys: keys),
              let totalCapacity = values.volumeTotalCapacity else {
            return nil
        }

        let totalBytes = Int64(totalCapacity)
        let preferredAvailableBytes = values.volumeAvailableCapacityForImportantUsage.map { Int64($0) }
        let fallbackAvailableBytes = values.volumeAvailableCapacity.map { Int64($0) }
        let availableBytes = preferredAvailableBytes ?? fallbackAvailableBytes ?? 0
        let usedBytes = max(totalBytes - availableBytes, 0)

        guard totalBytes > 0 else {
            return nil
        }

        let usage = Double(usedBytes) / Double(totalBytes)

        return (usage, usedBytes, totalBytes)
    }
}

extension Double {
    var percentText: String {
        let percentage = Int((max(0, min(self, 1)) * 100).rounded())
        return "\(percentage)%"
    }
}
