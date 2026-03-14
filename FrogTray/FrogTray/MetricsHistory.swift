//
//  MetricsHistory.swift
//  FrogTray
//
//  Circular buffer storing the last 3 metric readings for the history bar graph.
//

import Foundation

struct MetricsHistory: Sendable {
    struct Reading: Sendable {
        let cpu: Double
        let memory: Double
        let disk: Double
    }

    private(set) var readings: [Reading] = []
    private let capacity = 3

    mutating func push(cpu: Double, memory: Double, disk: Double) {
        readings.append(Reading(cpu: cpu, memory: memory, disk: disk))
        if readings.count > capacity {
            readings.removeFirst()
        }
    }

    var cpuValues: [Double] { readings.map(\.cpu) }
    var memoryValues: [Double] { readings.map(\.memory) }
    var diskValues: [Double] { readings.map(\.disk) }
}
