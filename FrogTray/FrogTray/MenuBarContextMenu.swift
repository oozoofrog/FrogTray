//
//  MenuBarContextMenu.swift
//  FrogTray
//
//  NSMenu builder for right-click on the menu bar item.
//

import AppKit

final class MenuBarContextMenu {
    private let monitor: SystemMetricsMonitor
    private let launchAtLoginManager: LaunchAtLoginManager
    private let processMonitor: ProcessMonitor
    private let onRefresh: () -> Void

    init(
        monitor: SystemMetricsMonitor,
        launchAtLoginManager: LaunchAtLoginManager,
        processMonitor: ProcessMonitor,
        onRefresh: @escaping () -> Void
    ) {
        self.monitor = monitor
        self.launchAtLoginManager = launchAtLoginManager
        self.processMonitor = processMonitor
        self.onRefresh = onRefresh
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Summary header
        let snapshot = monitor.snapshot
        let state = PondState(snapshot: snapshot)
        let headerItem = NSMenuItem(title: "\(state.storyTitle) — \(snapshot.menuBarMetricsText)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(.separator())

        // Metrics summary
        addMetricItem(to: menu, label: "CPU", value: snapshot.cpuUsage)
        addMetricItem(to: menu, label: "Memory", value: snapshot.memoryUsage)
        addMetricItem(to: menu, label: "Disk", value: snapshot.diskUsage)

        menu.addItem(.separator())

        // Top processes
        let processesItem = NSMenuItem(title: "주요 프로세스", action: nil, keyEquivalent: "")
        processesItem.isEnabled = false
        menu.addItem(processesItem)

        for process in processMonitor.topCPUProcesses.prefix(3) {
            let item = NSMenuItem(
                title: "  \(process.displayName) — CPU \(String(format: "%.1f%%", process.totalCPUUsage))",
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Launch at login toggle
        let loginItem = NSMenuItem(
            title: "로그인 시 자동 실행",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = launchAtLoginManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        // System settings
        let settingsItem = NSMenuItem(
            title: "시스템 설정…",
            action: #selector(openSystemSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // Refresh
        let refreshItem = NSMenuItem(
            title: "새로고침",
            action: #selector(handleRefresh),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        // Quit
        let quitItem = NSMenuItem(
            title: "종료",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func addMetricItem(to menu: NSMenu, label: String, value: Double) {
        let tone = UsageTone(value: value)
        let percentage = Int((max(0, min(value, 1)) * 100).rounded())
        let item = NSMenuItem(
            title: "\(label): \(percentage)% — \(tone.badgeTitle)",
            action: nil,
            keyEquivalent: ""
        )
        item.isEnabled = false
        menu.addItem(item)
    }

    @objc private func toggleLaunchAtLogin() {
        launchAtLoginManager.setLaunchAtLoginEnabled(!launchAtLoginManager.isEnabled)
    }

    @objc private func openSystemSettings() {
        launchAtLoginManager.openSystemSettingsLoginItems()
    }

    @objc private func handleRefresh() {
        onRefresh()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
