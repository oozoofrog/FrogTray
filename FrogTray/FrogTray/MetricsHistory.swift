//
//  MetricsHistory.swift
//  FrogTray
//
//  Bounded queue storing the last 3 metric readings for the history bar graph.
//

import Foundation

struct MetricsHistory: Sendable {
    struct Reading: Sendable {
        let cpu: Double
        let memory: Double
        let disk: Double
    }

    private var readings: [Reading] = []
    private let capacity = 3

    mutating func push(cpu: Double, memory: Double, disk: Double) {
        let clamped = Reading(
            cpu: min(max(cpu, 0), 1),
            memory: min(max(memory, 0), 1),
            disk: min(max(disk, 0), 1)
        )
        readings.append(clamped)
        if readings.count > capacity {
            readings.removeFirst()
        }
    }

    var cpuValues: [Double] { readings.map(\.cpu) }
    var memoryValues: [Double] { readings.map(\.memory) }
    var diskValues: [Double] { readings.map(\.disk) }
}
