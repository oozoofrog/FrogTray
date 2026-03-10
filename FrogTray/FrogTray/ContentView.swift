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
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager

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

            settingsSection

            Divider()

            HStack {
                Button("새로고침") {
                    monitor.refresh()
                    launchAtLoginManager.refresh()
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
        .onAppear {
            launchAtLoginManager.refresh()
        }
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

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("설정")
                .font(.headline)

            Toggle(
                "로그인 시 자동 실행",
                isOn: Binding(
                    get: { launchAtLoginManager.isEnabled },
                    set: { launchAtLoginManager.setLaunchAtLoginEnabled($0) }
                )
            )
            .disabled(launchAtLoginManager.isUpdating)

            if launchAtLoginManager.isUpdating {
                Text("설정을 적용하는 중입니다…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(launchAtLoginManager.errorMessage ?? launchAtLoginManager.statusMessage)
                    .font(.caption)
                    .foregroundStyle(
                        launchAtLoginManager.errorMessage == nil
                        ? AnyShapeStyle(.secondary)
                        : AnyShapeStyle(.red)
                    )
            }

            if launchAtLoginManager.shouldShowSystemSettingsButton {
                Button("시스템 설정 열기") {
                    launchAtLoginManager.openSystemSettingsLoginItems()
                }
                .font(.caption)
            }
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
    ContentView(
        monitor: SystemMetricsMonitor(refreshInterval: 60),
        launchAtLoginManager: LaunchAtLoginManager(
            controller: PreviewLaunchAtLoginController(status: .requiresApproval)
        )
    )
}

private struct PreviewLaunchAtLoginController: LaunchAtLoginControlling {
    let status: LaunchAtLoginStatus

    func register() throws {}
    func unregister() throws {}
    func openSystemSettingsLoginItems() {}
}
