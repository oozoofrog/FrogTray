//
//  MenuBarLabelView.swift
//  FrogTray
//
//  Menu bar label: renders metrics as CGImage via ImageRenderer,
//  then displays as Image (the only custom content type MenuBarExtra sizes correctly).
//

import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var monitor: SystemMetricsMonitor
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @ObservedObject var processMonitor: ProcessMonitor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let cgImage = renderLabel() {
            Image(cgImage, scale: 2, label: Text("FrogTray"))
                .renderingMode(.original)
                .background {
                    MenuBarHostingBridge(
                        monitor: monitor,
                        launchAtLoginManager: launchAtLoginManager,
                        processMonitor: processMonitor
                    )
                    .frame(width: 0, height: 0)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(monitor.snapshot.menuBarAccessibilityText)
                .accessibilityValue(monitor.pondState.accessibilityDescription)
        }
    }

    private func renderLabel() -> CGImage? {
        let content = MenuBarLabelContent(
            pondState: monitor.pondState,
            history: monitor.metricsHistory,
            colorScheme: colorScheme
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.cgImage
    }
}

// MARK: - Render-only view (never displayed directly, only rendered to CGImage)

private struct MenuBarLabelContent: View {
    let pondState: PondState
    let history: MetricsHistory
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 6) {
            // Frog character
            Image(systemName: pondState.sfSymbolName)
                .font(.system(size: 13, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(symbolColor)

            // Metric groups
            metricGroup("🖥", values: history.cpuValues)
            metricGroup("💾", values: history.memoryValues)
            metricGroup("💿", values: history.diskValues)
        }
        .padding(.horizontal, 2)
        .frame(height: 18)
        .environment(\.colorScheme, colorScheme)
    }

    private var symbolColor: Color {
        switch pondState {
        case .danger: UsageTone.critical.color
        case .caution: UsageTone.caution.color
        default: colorScheme == .dark
            ? PondTheme.moonlightSilver
            : PondTheme.lilyPadGreen
        }
    }

    private func metricGroup(_ emoji: String, values: [Double]) -> some View {
        HStack(spacing: 2) {
            Text(emoji)
                .font(.system(size: 9))

            HStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { i in
                    let val = i < values.count ? values[i] : 0.0
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(UsageTone(value: val).color)
                        .frame(width: 3, height: max(1, 12 * val))
                        .frame(height: 12, alignment: .bottom)
                }
            }
        }
    }
}
