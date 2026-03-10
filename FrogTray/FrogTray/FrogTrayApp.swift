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

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: metricsMonitor)
        } label: {
            Text(metricsMonitor.snapshot.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
