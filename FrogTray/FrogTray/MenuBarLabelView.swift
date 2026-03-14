//
//  MenuBarLabelView.swift
//  FrogTray
//
//  Combined menu bar label: animated character + history bars + AppKit bridge.
//

import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var monitor: SystemMetricsMonitor
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @ObservedObject var processMonitor: ProcessMonitor

    var body: some View {
        HStack(spacing: 4) {
            MenuBarCharacterView(state: monitor.pondState)

            MenuBarHistoryBarsView(history: monitor.metricsHistory)

            MenuBarHostingBridge(
                monitor: monitor,
                launchAtLoginManager: launchAtLoginManager,
                processMonitor: processMonitor
            )
            .frame(width: 0, height: 0)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityValue(monitor.pondState.accessibilityDescription)
    }

    private var accessibilityText: String {
        monitor.snapshot.menuBarAccessibilityText
    }
}
