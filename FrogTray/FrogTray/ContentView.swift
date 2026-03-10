//
//  ContentView.swift
//  FrogTray
//
//  Created by oozoofrog on 3/7/26.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var monitor: SystemMetricsMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            MetricRow(
                title: "CPU",
                value: monitor.snapshot.cpuUsage,
                details: "전체 CPU 사용률"
            )

            MetricRow(
                title: "Memory",
                value: monitor.snapshot.memoryUsage,
                details: "\(monitor.snapshot.memoryUsedText) / \(monitor.snapshot.memoryTotalText)"
            )

            MetricRow(
                title: "Disk",
                value: monitor.snapshot.diskUsage,
                details: "\(monitor.snapshot.diskUsedText) / \(monitor.snapshot.diskTotalText)"
            )

            Divider()

            HStack {
                Button("새로고침") {
                    monitor.refresh()
                }

                Spacer()

                Button("종료") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("FrogTray")
                    .font(.headline)
                Spacer()
            }

            Text("마지막 갱신 \(monitor.snapshot.lastUpdated.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: Double
    let details: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value.percentText)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }

            Gauge(value: value, in: 0...1) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)

            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView(monitor: SystemMetricsMonitor(refreshInterval: 60))
}
