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
            MenuBarLabelView(
                monitor: metricsMonitor,
                launchAtLoginManager: launchAtLoginManager,
                processMonitor: processMonitor
            )
        }
        .menuBarExtraStyle(.window)
    }
}
