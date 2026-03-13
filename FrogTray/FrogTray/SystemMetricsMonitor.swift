//
//  SystemMetricsMonitor.swift
//  FrogTray
//
//  Created by Codex on 3/11/26.
//

import Combine
import Foundation
import Darwin

// MARK: - Detail Data Models

struct CPUDetail {
    let userUsage: Double
    let systemUsage: Double
    let idleUsage: Double
    let coreUsages: [Double]
}

struct MemoryDetail {
    let activeBytes: UInt64
    let wiredBytes: UInt64
    let compressedBytes: UInt64
    let inactiveBytes: UInt64
    let freeBytes: UInt64
}

struct DiskDetail {
    let usedBytes: Int64
    let freeBytes: Int64
    let totalBytes: Int64
    let purgeableBytes: Int64
}

// MARK: - SystemSnapshot

struct SystemSnapshot {
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let memoryUsedBytes: UInt64
    let memoryTotalBytes: UInt64
    let diskUsedBytes: Int64
    let diskTotalBytes: Int64
    let lastUpdated: Date

    let cpuDetail: CPUDetail?
    let memoryDetail: MemoryDetail?
    let diskDetail: DiskDetail?

    static let placeholder = SystemSnapshot(
        cpuUsage: 0,
        memoryUsage: 0,
        diskUsage: 0,
        memoryUsedBytes: 0,
        memoryTotalBytes: ProcessInfo.processInfo.physicalMemory,
        diskUsedBytes: 0,
        diskTotalBytes: 0,
        lastUpdated: .now,
        cpuDetail: nil,
        memoryDetail: nil,
        diskDetail: nil
    )

    var menuBarMetricsText: String {
        "C\(cpuUsage.percentValueText) M\(memoryUsage.percentValueText) D\(diskUsage.percentValueText)"
    }

    var menuBarAccessibilityText: String {
        "CPU \(cpuUsage.percentText), Memory \(memoryUsage.percentText), Disk \(diskUsage.percentText)"
    }

    var worstUsage: Double {
        max(cpuUsage, memoryUsage, diskUsage)
    }

    var frogBellyState: FrogBellyState {
        FrogBellyState(usage: worstUsage)
    }

    var memoryUsedText: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsedBytes), countStyle: .memory)
    }

    var memoryTotalText: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryTotalBytes), countStyle: .memory)
    }

    var memoryFreeText: String {
        guard let detail = memoryDetail else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(detail.freeBytes), countStyle: .memory)
    }

    var diskUsedText: String {
        ByteCountFormatter.string(fromByteCount: diskUsedBytes, countStyle: .file)
    }

    var diskTotalText: String {
        ByteCountFormatter.string(fromByteCount: diskTotalBytes, countStyle: .file)
    }

    var diskFreeText: String {
        guard let detail = diskDetail else { return "—" }
        return ByteCountFormatter.string(fromByteCount: detail.freeBytes, countStyle: .file)
    }
}

// MARK: - SystemMetricsMonitor

@MainActor
final class SystemMetricsMonitor: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot.placeholder

    private var timerCancellable: AnyCancellable?
    private var previousCPUTicks: [UInt32]?
    private var previousPerCoreTicks: [[UInt32]]?

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
        let cpuResult = readCPUUsage()
        let cpuUsage = cpuResult?.usage ?? snapshot.cpuUsage
        let cpuDetail = cpuResult.map { result in
            CPUDetail(
                userUsage: result.user,
                systemUsage: result.system,
                idleUsage: result.idle,
                coreUsages: readPerCoreCPUUsage() ?? []
            )
        }

        let memResult = readMemorySample()
        let memorySample = memResult ?? (usage: snapshot.memoryUsage, used: snapshot.memoryUsedBytes, total: snapshot.memoryTotalBytes, detail: snapshot.memoryDetail)
        let diskResult = readDiskSample()
        let diskSample = diskResult ?? (usage: snapshot.diskUsage, used: snapshot.diskUsedBytes, total: snapshot.diskTotalBytes, detail: snapshot.diskDetail)

        snapshot = SystemSnapshot(
            cpuUsage: cpuUsage,
            memoryUsage: memorySample.usage,
            diskUsage: diskSample.usage,
            memoryUsedBytes: memorySample.used,
            memoryTotalBytes: memorySample.total,
            diskUsedBytes: diskSample.used,
            diskTotalBytes: diskSample.total,
            lastUpdated: .now,
            cpuDetail: cpuDetail,
            memoryDetail: memorySample.detail,
            diskDetail: diskSample.detail
        )
    }

    private func readCPUUsage() -> (usage: Double, user: Double, system: Double, idle: Double)? {
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

        let userDelta = deltas[Int(CPU_STATE_USER)] + deltas[Int(CPU_STATE_NICE)]
        let systemDelta = deltas[Int(CPU_STATE_SYSTEM)]
        let idleDelta = deltas[Int(CPU_STATE_IDLE)]

        let usage = max(0, min((userDelta + systemDelta) / totalTicks, 1))
        let user = userDelta / totalTicks
        let system = systemDelta / totalTicks
        let idle = idleDelta / totalTicks

        return (usage, user, system, idle)
    }

    private func readPerCoreCPUUsage() -> [Double]? {
        var processorInfo: processor_info_array_t?
        var processorMsgCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &processorMsgCount
        )

        guard result == KERN_SUCCESS, let processorInfo else {
            return nil
        }

        defer {
            let size = vm_size_t(processorMsgCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: processorInfo), size)
        }

        let coreCount = Int(processorCount)
        var currentPerCoreTicks: [[UInt32]] = []

        for i in 0..<coreCount {
            let offset = Int(CPU_STATE_MAX) * i
            let ticks: [UInt32] = [
                UInt32(bitPattern: processorInfo[offset + Int(CPU_STATE_USER)]),
                UInt32(bitPattern: processorInfo[offset + Int(CPU_STATE_SYSTEM)]),
                UInt32(bitPattern: processorInfo[offset + Int(CPU_STATE_IDLE)]),
                UInt32(bitPattern: processorInfo[offset + Int(CPU_STATE_NICE)]),
            ]
            currentPerCoreTicks.append(ticks)
        }

        guard let previousPerCoreTicks, previousPerCoreTicks.count == coreCount else {
            self.previousPerCoreTicks = currentPerCoreTicks
            return nil
        }

        self.previousPerCoreTicks = currentPerCoreTicks

        var coreUsages: [Double] = []
        for i in 0..<coreCount {
            let cur = currentPerCoreTicks[i]
            let prev = previousPerCoreTicks[i]
            let deltas = zip(cur, prev).map { Double($0) - Double($1) }
            let total = deltas.reduce(0, +)
            guard total > 0 else {
                coreUsages.append(0)
                continue
            }
            let busy = deltas[0] + deltas[1] + deltas[3] // user + system + nice
            coreUsages.append(max(0, min(busy / total, 1)))
        }

        return coreUsages
    }

    private func readMemorySample() -> (usage: Double, used: UInt64, total: UInt64, detail: MemoryDetail?)? {
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
        let activeBytes = UInt64(vmStats.active_count) * pageSize
        let wiredBytes = UInt64(vmStats.wire_count) * pageSize
        let compressedBytes = UInt64(vmStats.compressor_page_count) * pageSize
        let inactiveBytes = UInt64(vmStats.inactive_count) * pageSize
        let speculativeBytes = UInt64(vmStats.speculative_count) * pageSize
        let freeBytes = UInt64(vmStats.free_count) * pageSize

        let usedBytes = activeBytes + wiredBytes + compressedBytes + speculativeBytes
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        guard totalBytes > 0 else {
            return nil
        }

        let clampedUsedBytes = min(usedBytes, totalBytes)
        let usage = Double(clampedUsedBytes) / Double(totalBytes)

        let detail = MemoryDetail(
            activeBytes: activeBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            inactiveBytes: inactiveBytes,
            freeBytes: freeBytes
        )

        return (usage, clampedUsedBytes, totalBytes, detail)
    }

    private func readDiskSample() -> (usage: Double, used: Int64, total: Int64, detail: DiskDetail?)? {
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
        let availableForImportant = preferredAvailableBytes ?? fallbackAvailableBytes ?? 0
        let availableBytes = fallbackAvailableBytes ?? 0
        let usedBytes = max(totalBytes - availableForImportant, 0)
        let purgeableBytes = max(availableForImportant - availableBytes, 0)

        guard totalBytes > 0 else {
            return nil
        }

        let usage = Double(usedBytes) / Double(totalBytes)

        let detail = DiskDetail(
            usedBytes: usedBytes,
            freeBytes: availableForImportant,
            totalBytes: totalBytes,
            purgeableBytes: purgeableBytes
        )

        return (usage, usedBytes, totalBytes, detail)
    }
}

// MARK: - FrogBellyState

enum FrogBellyState: String {
    case calm
    case normal
    case warning
    case critical

    init(usage: Double) {
        switch usage {
        case 0.85...:
            self = .critical
        case 0.65...:
            self = .warning
        case 0.40...:
            self = .normal
        default:
            self = .calm
        }
    }
}

// MARK: - Double Extensions

extension Double {
    var percentValueText: String {
        let percentage = Int((max(0, min(self, 1)) * 100).rounded())
        return "\(percentage)"
    }

    var percentText: String {
        "\(percentValueText)%"
    }
}
