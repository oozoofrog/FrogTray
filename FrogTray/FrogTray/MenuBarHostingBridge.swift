//
//  MenuBarHostingBridge.swift
//  FrogTray
//
//  AppKit bridge embedded in the menu bar label.
//  Provides hover detection, tooltip popover, and right-click context menu
//  by walking up to the NSStatusBarButton ancestor.
//

import AppKit
import os
import SwiftUI

private let logger = Logger(subsystem: "com.oozoofrog.FrogTray", category: "MenuBarHostingBridge")

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
        private var hoverTimer: Timer?

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
            hoverTimer?.invalidate()
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                guard let self, self.isHovering else { return }
                self.showTooltipPopover()
            }
        }

        @objc func mouseExited(with event: NSEvent) {
            isHovering = false
            hoverTimer?.invalidate()
            hoverTimer = nil
            dismissTooltipPopover()
        }

        func showRightClickMenu() {
            guard let button = statusBarButton,
                  let contextMenuBuilder else { return }

            let menu = contextMenuBuilder.buildMenu()

            // Temporarily assign the menu to the status item so NSStatusBarButton
            // presents it on the next performClick. Clear it afterward so that
            // subsequent left-clicks still open the SwiftUI popover window.
            if let statusItem = button.statusItem {
                statusItem.menu = menu
                button.performClick(nil)
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
        guard window != nil else { return }
        guard !didSetup else { return }

        if let button = findStatusBarButton() {
            coordinator?.setupOnButton(button)
            didSetup = true
        } else {
            logger.warning("findStatusBarButton() failed — NSStatusBarButton ancestor not found")
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
        guard let coordinator else {
            super.rightMouseDown(with: event)
            return
        }
        coordinator.showRightClickMenu()
    }
}

// MARK: - NSStatusBarButton Extension

private extension NSStatusBarButton {
    var statusItem: NSStatusItem? {
        // Access the status item via KVC on NSStatusBarWindow (private API).
        // Guard with responds(to:) to avoid NSUnknownKeyException if the
        // internal key is removed in a future macOS release.
        guard let window = self.window else { return nil }
        let selector = NSSelectorFromString("statusItem")
        guard window.responds(to: selector) else {
            logger.warning("NSStatusBarWindow no longer responds to 'statusItem' KVC key")
            return nil
        }
        return window.value(forKey: "statusItem") as? NSStatusItem
    }
}
