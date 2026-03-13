//
//  FrogTrayApp.swift
//  FrogTray
//
//  Created by oozoofrog on 3/7/26.
//

import SwiftUI

@main
struct FrogTrayApp: App {
    @StateObject private var metricsMonitor = SystemMetricsMonitor()
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @StateObject private var processMonitor = ProcessMonitor()

    var body: some Scene {
        MenuBarExtra {
            ContentView(
                monitor: metricsMonitor,
                launchAtLoginManager: launchAtLoginManager,
                processMonitor: processMonitor
            )
        } label: {
            FrogMenuBarLabel(snapshot: metricsMonitor.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct FrogMenuBarLabel: View {
    let snapshot: SystemSnapshot

    var body: some View {
        HStack(spacing: 4) {
            FrogStatusIcon(state: snapshot.frogBellyState)

            Text(snapshot.menuBarMetricsText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.menuBarAccessibilityText)
    }
}

private struct FrogStatusIcon: View {
    let state: FrogBellyState

    private var bellySize: CGSize {
        switch state {
        case .calm:
            CGSize(width: 5, height: 3.5)
        case .normal:
            CGSize(width: 6.5, height: 5)
        case .warning:
            CGSize(width: 8, height: 6.5)
        case .critical:
            CGSize(width: 9.5, height: 8)
        }
    }

    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                Circle()
                    .frame(width: 4, height: 4)
                Circle()
                    .frame(width: 4, height: 4)
            }
            .offset(y: -4.5)

            Capsule(style: .continuous)
                .frame(width: 11, height: 8)
                .offset(y: 0.5)

            Ellipse()
                .frame(width: bellySize.width, height: bellySize.height)
                .offset(x: 1.5, y: 3.5)
        }
        .frame(width: 16, height: 14)
        .foregroundStyle(.primary)
        .accessibilityHidden(true)
    }
}
