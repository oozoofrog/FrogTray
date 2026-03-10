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

    var body: some Scene {
        MenuBarExtra {
            ContentView(
                monitor: metricsMonitor,
                launchAtLoginManager: launchAtLoginManager
            )
        } label: {
            Text(metricsMonitor.snapshot.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
