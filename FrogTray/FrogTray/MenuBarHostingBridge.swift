//
//  MenuBarHostingBridge.swift
//  FrogTray
//
//  AppKit bridge embedded in the menu bar label.
//  Provides hover detection, tooltip popover, and right-click context menu
//  by walking up to the NSStatusBarButton ancestor.
//

import AppKit
import SwiftUI

struct MenuBarHostingBridge: NSViewRepresentable {
    @ObservedObject var monitor: SystemMetricsMonitor
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @ObservedObject var processMonitor: ProcessMonitor

    func makeNSView(context: Context) -> BridgeAnchorView {
        let view = BridgeAnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: BridgeAnchorView, context: Context) {
        context.coordinator.monitor = monitor
        context.coordinator.launchAtLoginManager = launchAtLoginManager
        context.coordinator.processMonitor = processMonitor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            monitor: monitor,
            launchAtLoginManager: launchAtLoginManager,
            processMonitor: processMonitor
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSPopoverDelegate {
        var monitor: SystemMetricsMonitor
        var launchAtLoginManager: LaunchAtLoginManager
        var processMonitor: ProcessMonitor

        weak var statusBarButton: NSStatusBarButton?
        var popover: NSPopover?
        var contextMenuBuilder: MenuBarContextMenu?
        var isHovering = false

        init(
            monitor: SystemMetricsMonitor,
            launchAtLoginManager: LaunchAtLoginManager,
            processMonitor: ProcessMonitor
        ) {
            self.monitor = monitor
            self.launchAtLoginManager = launchAtLoginManager
            self.processMonitor = processMonitor
        }

        func setupOnButton(_ button: NSStatusBarButton) {
            self.statusBarButton = button

            contextMenuBuilder = MenuBarContextMenu(
                monitor: monitor,
                launchAtLoginManager: launchAtLoginManager,
                processMonitor: processMonitor,
                onRefresh: { [weak self] in
                    self?.monitor.refresh()
                    self?.processMonitor.refresh()
                    self?.launchAtLoginManager.refresh()
                }
            )

            // Add tracking area for hover
            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            button.addTrackingArea(trackingArea)
        }

        // MARK: - Mouse Events

        @objc func mouseEntered(with event: NSEvent) {
            isHovering = true
            showTooltipPopover()
        }

        @objc func mouseExited(with event: NSEvent) {
            isHovering = false
            dismissTooltipPopover()
        }

        func showRightClickMenu() {
            guard let button = statusBarButton,
                  let contextMenuBuilder else { return }

            let menu = contextMenuBuilder.buildMenu()

            // Standard pattern: temporarily set the menu, then remove it
            // so left-click still opens the SwiftUI window
            if let statusItem = button.statusItem {
                statusItem.menu = menu
                button.performClick(nil)
                // Remove menu after it closes so left-click works again
                DispatchQueue.main.async {
                    statusItem.menu = nil
                }
            }
        }

        // MARK: - Tooltip Popover

        private func showTooltipPopover() {
            guard let button = statusBarButton else { return }
            guard popover == nil else { return }

            let tooltipView = MenuBarTooltipView(
                snapshot: monitor.snapshot,
                state: PondState(snapshot: monitor.snapshot)
            )

            let popover = NSPopover()
            popover.contentViewController = NSHostingController(rootView: tooltipView)
            popover.behavior = .transient
            popover.delegate = self
            popover.animates = true

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            self.popover = popover
        }

        private func dismissTooltipPopover() {
            popover?.performClose(nil)
            popover = nil
        }

        // MARK: - NSPopoverDelegate

        nonisolated func popoverDidClose(_ notification: Notification) {
            Task { @MainActor in
                self.popover = nil
            }
        }
    }
}

// MARK: - BridgeAnchorView

final class BridgeAnchorView: NSView {
    weak var coordinator: MenuBarHostingBridge.Coordinator?
    private var didSetup = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !didSetup else { return }

        if let button = findStatusBarButton() {
            coordinator?.setupOnButton(button)
            didSetup = true
        }
    }

    private func findStatusBarButton() -> NSStatusBarButton? {
        var current: NSView? = self
        while let view = current {
            if let button = view as? NSStatusBarButton {
                return button
            }
            current = view.superview
        }
        return nil
    }

    override func rightMouseDown(with event: NSEvent) {
        coordinator?.showRightClickMenu()
    }
}

// MARK: - NSStatusBarButton Extension

private extension NSStatusBarButton {
    var statusItem: NSStatusItem? {
        // Walk up the responder chain to find the status item
        // The button's window is NSStatusBarWindow, which has a reference
        guard let window = self.window else { return nil }
        return window.value(forKey: "statusItem") as? NSStatusItem
    }
}
