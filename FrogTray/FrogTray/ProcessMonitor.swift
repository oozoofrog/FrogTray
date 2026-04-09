//
//  ProcessMonitor.swift
//  FrogTray
//
//  Created by Claude on 3/14/26.
//

import Combine
import Darwin
import Foundation

// MARK: - Data Models

struct ProcessGroup: Identifiable {
    let id: String
    let name: String
    let count: Int
    let totalCPUUsage: Double
    let totalMemoryBytes: UInt64
    let totalDiskIOBytes: UInt64

    var displayName: String {
        count > 1 ? "\(name) (×\(count))" : name
    }
}

// MARK: - ProcessMonitor

@MainActor
final class ProcessMonitor: ObservableObject {
    @Published private(set) var topCPUProcesses: [ProcessGroup] = []
    @Published private(set) var topMemoryProcesses: [ProcessGroup] = []
    @Published private(set) var topDiskIOProcesses: [ProcessGroup] = []
    @Published private(set) var isWarmedUp = false

    private var previousCPUTimes: [pid_t: (user: UInt64, system: UInt64)] = [:]
    private var previousDiskIO: [pid_t: UInt64] = [:]
    private var previousTimestamp: Date?
    private var timerCancellable: AnyCancellable?

    init(refreshInterval: TimeInterval = 2) {
        refresh()

        timerCancellable = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    func refresh() {
        let pids = listAllPIDs()
        guard !pids.isEmpty else { return }

        let now = Date()
        let elapsed = previousTimestamp.map { now.timeIntervalSince($0) } ?? 0

        struct RawInfo {
            let pid: pid_t
            let name: String
            let cpuUsage: Double
            let memoryBytes: UInt64
            let diskIOBytes: UInt64
        }

        var rawInfos: [RawInfo] = []
        var newCPUTimes: [pid_t: (user: UInt64, system: UInt64)] = [:]
        var newDiskIO: [pid_t: UInt64] = [:]

        for pid in pids {
            guard pid > 0 else { continue }

            let name = processName(for: pid)
            guard !name.isEmpty else { continue }

            var taskInfo = proc_taskinfo()
            let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.stride)
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)
            guard ret == taskInfoSize else { continue }

            let userTime = taskInfo.pti_total_user
            let systemTime = taskInfo.pti_total_system
            let memoryBytes = UInt64(taskInfo.pti_resident_size)

            newCPUTimes[pid] = (user: userTime, system: systemTime)

            var cpuUsage = 0.0
            if elapsed > 0, let prev = previousCPUTimes[pid],
               userTime >= prev.user, systemTime >= prev.system {
                let userDelta = Double(userTime - prev.user)
                let systemDelta = Double(systemTime - prev.system)
                // Mach time is in nanoseconds
                let totalCPUNs = userDelta + systemDelta
                let elapsedNs = elapsed * 1_000_000_000
                cpuUsage = totalCPUNs / elapsedNs * 100.0
            }

            var diskIOBytes: UInt64 = 0
            var rusage = rusage_info_v4()
            let rusageRet = withUnsafeMutablePointer(to: &rusage) { ptr in
                ptr.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { rusagePtr in
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, rusagePtr)
                }
            }
            if rusageRet == 0 {
                let totalIO = rusage.ri_diskio_bytesread + rusage.ri_diskio_byteswritten
                newDiskIO[pid] = totalIO
                if let prevIO = previousDiskIO[pid], totalIO >= prevIO {
                    diskIOBytes = totalIO - prevIO
                }
            }

            rawInfos.append(RawInfo(
                pid: pid,
                name: name,
                cpuUsage: cpuUsage,
                memoryBytes: memoryBytes,
                diskIOBytes: diskIOBytes
            ))
        }

        previousCPUTimes = newCPUTimes
        previousDiskIO = newDiskIO
        previousTimestamp = now

        if elapsed > 0 {
            isWarmedUp = true
        }

        // Group by name
        let grouped = Dictionary(grouping: rawInfos, by: \.name)

        let groups: [ProcessGroup] = grouped.map { name, infos in
            ProcessGroup(
                id: name,
                name: name,
                count: infos.count,
                totalCPUUsage: infos.reduce(0) { $0 + $1.cpuUsage },
                totalMemoryBytes: infos.reduce(0) { $0 + $1.memoryBytes },
                totalDiskIOBytes: infos.reduce(0) { $0 + $1.diskIOBytes }
            )
        }

        topCPUProcesses = groups
            .sorted { $0.totalCPUUsage > $1.totalCPUUsage }
            .prefix(5)
            .map { $0 }

        topMemoryProcesses = groups
            .sorted { $0.totalMemoryBytes > $1.totalMemoryBytes }
            .prefix(5)
            .map { $0 }

        topDiskIOProcesses = groups
            .sorted { $0.totalDiskIOBytes > $1.totalDiskIOBytes }
            .prefix(5)
            .filter { $0.totalDiskIOBytes > 0 }
            .map { $0 }
    }

    // MARK: - Private Helpers

    private func listAllPIDs() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: Int(count))
        let actualCount = proc_listallpids(&pids, Int32(MemoryLayout<pid_t>.stride * Int(count)))
        guard actualCount > 0 else { return [] }

        return Array(pids.prefix(Int(actualCount)))
    }

    private func processName(for pid: pid_t) -> String {
        // proc_name은 현재 사용자 프로세스만 반환하므로 proc_pidpath를 우선 사용
        var pathBuffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        if pathLength > 0 {
            let path = String(cString: pathBuffer)
            return (path as NSString).lastPathComponent
        }

        var nameBuffer = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
        let length = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
        guard length > 0 else { return "" }
        return String(cString: nameBuffer)
    }
}
