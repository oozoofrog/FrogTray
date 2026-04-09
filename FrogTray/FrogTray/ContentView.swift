//
//  ContentView.swift
//  FrogTray
//
//  Created by oozoofrog on 3/7/26.
//

import AppKit
import SwiftUI

// MARK: - Navigation Types

enum MetricKind: CaseIterable {
    case cpu, memory, disk
}

enum TrayScreen: Equatable {
    case main
    case detail(MetricKind)

    static func == (lhs: TrayScreen, rhs: TrayScreen) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main):
            return true
        case (.detail(let l), .detail(let r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var monitor: SystemMetricsMonitor
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @ObservedObject var processMonitor: ProcessMonitor

    @State private var activeScreen: TrayScreen = .main

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginManager.isEnabled },
            set: { launchAtLoginManager.setLaunchAtLoginEnabled($0) }
        )
    }

    private var launchStatusTone: StatusTone {
        if launchAtLoginManager.errorMessage != nil {
            return .error
        }

        switch launchAtLoginManager.status {
        case .enabled:
            return .positive
        case .requiresApproval:
            return .warning
        case .notRegistered, .notFound:
            return .neutral
        }
    }

    private var launchStatusMessage: String {
        if let errorMessage = launchAtLoginManager.errorMessage {
            return errorMessage
        }

        return launchAtLoginManager.statusMessage
    }

    var body: some View {
        Group {
            switch activeScreen {
            case .main:
                mainView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .detail(let kind):
                MetricDetailView(
                    kind: kind,
                    snapshot: monitor.snapshot,
                    processMonitor: processMonitor,
                    onBack: { withAnimation(.easeInOut(duration: 0.2)) { activeScreen = .main } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: activeScreen)
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryCard

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { activeScreen = .detail(.cpu) }
            } label: {
                MetricCard(
                    title: "CPU",
                    subtitle: "전체 CPU 사용률",
                    details: monitor.snapshot.cpuUsage.statusDescription,
                    value: monitor.snapshot.cpuUsage,
                    iconName: "cpu",
                    tone: UsageTone(value: monitor.snapshot.cpuUsage),
                    topProcess: topProcessText(processMonitor.topCPUProcesses.first) {
                        String(format: "%.1f%%", $0.totalCPUUsage)
                    },
                    showChevron: true
                )
            }
            .buttonStyle(CardButtonStyle())

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { activeScreen = .detail(.memory) }
            } label: {
                MetricCard(
                    title: "Memory",
                    subtitle: "메모리 점유",
                    details: "\(monitor.snapshot.memoryUsedText) / \(monitor.snapshot.memoryTotalText)",
                    value: monitor.snapshot.memoryUsage,
                    iconName: "memorychip",
                    tone: UsageTone(value: monitor.snapshot.memoryUsage),
                    topProcess: topProcessText(processMonitor.topMemoryProcesses.first) {
                        ByteCountFormatter.string(fromByteCount: Int64(clamping: $0.totalMemoryBytes), countStyle: .memory)
                    },
                    showChevron: true
                )
            }
            .buttonStyle(CardButtonStyle())

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { activeScreen = .detail(.disk) }
            } label: {
                MetricCard(
                    title: "Disk",
                    subtitle: "시스템 디스크 사용량",
                    details: "\(monitor.snapshot.diskUsedText) / \(monitor.snapshot.diskTotalText)",
                    value: monitor.snapshot.diskUsage,
                    iconName: "internaldrive",
                    tone: UsageTone(value: monitor.snapshot.diskUsage),
                    topProcess: topProcessText(processMonitor.topDiskIOProcesses.first) {
                        ByteCountFormatter.string(fromByteCount: Int64(clamping: $0.totalDiskIOBytes), countStyle: .memory)
                    },
                    showChevron: true
                )
            }
            .buttonStyle(CardButtonStyle())

            settingsCard

            actionRow
        }
        .padding(16)
        .frame(width: 340)
        .background(
            LinearGradient(
                colors: [PondTheme.pondDeep.opacity(0.08), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .onAppear {
            launchAtLoginManager.refresh()
        }
    }

    private var summaryCard: some View {
        TrayCard {
            VStack(spacing: 14) {
                HStack {
                    FrogStatusIcon(state: monitor.snapshot.frogBellyState)
                        .foregroundStyle(PondTheme.lilyPadGreen)
                        .scaleEffect(1.2)

                    Text("개구리 연못")
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 5) {
                        Circle()
                            .fill(PondTheme.pondSurface)
                            .frame(width: 5, height: 5)
                            .shadow(color: PondTheme.pondSurface.opacity(0.6), radius: 3)

                        Text(monitor.snapshot.lastUpdated.formatted(date: .omitted, time: .shortened))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 0) {
                    miniGauge(title: "CPU", value: monitor.snapshot.cpuUsage)
                    miniGauge(title: "MEM", value: monitor.snapshot.memoryUsage)
                    miniGauge(title: "DISK", value: monitor.snapshot.diskUsage)
                }
            }
        }
    }

    private func miniGauge(title: String, value: Double) -> some View {
        let tone = UsageTone(value: value)
        return VStack(spacing: 5) {
            ZStack {
                Gauge(value: value, in: 0...1) {
                    Text(title)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [tone.color.opacity(0.5), tone.color]))
                .scaleEffect(1.15)

                Circle()
                    .strokeBorder(tone.color.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 48, height: 48)
            }

            Text(value.percentText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(tone.badgeTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tone.color)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsCard: some View {
        TrayCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "연못 설정", subtitle: "앱 동작과 로그인 시 자동 실행")

                Toggle("로그인 시 자동 실행", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
                    .disabled(launchAtLoginManager.isUpdating)

                if launchAtLoginManager.isUpdating {
                    InlineStatusMessage(
                        iconName: "arrow.triangle.2.circlepath",
                        message: "설정을 적용하는 중입니다…",
                        tone: .neutral
                    )
                } else {
                    InlineStatusMessage(
                        iconName: launchStatusTone.iconName,
                        message: launchStatusMessage,
                        tone: launchStatusTone
                    )
                }

                if launchAtLoginManager.shouldShowSystemSettingsButton {
                    Button {
                        launchAtLoginManager.openSystemSettingsLoginItems()
                    } label: {
                        Label("시스템 설정 열기", systemImage: "gearshape")
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)
                }
            }
        }
    }

    private func topProcessText(_ process: ProcessGroup?, formatter: (ProcessGroup) -> String) -> String? {
        guard let p = process else { return nil }
        return "\(p.displayName) · \(formatter(p))"
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                monitor.refresh()
                processMonitor.refresh()
                launchAtLoginManager.refresh()
            } label: {
                Label("새로고침", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .keyboardShortcut("r", modifiers: [.command])

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("종료", systemImage: "power")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(UsageTone.critical.color)
            .keyboardShortcut("q")
        }
    }
}

// MARK: - MetricCard

struct MetricCard: View {
    let title: String
    let subtitle: String
    let details: String
    let value: Double
    let iconName: String
    let tone: UsageTone
    var topProcess: String? = nil
    var showChevron: Bool = false

    var body: some View {
        TrayCard(tint: tone.color.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(tone.color.opacity(0.15))

                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tone.color)
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(value.percentText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()

                            Text(tone.badgeTitle)
                                .font(.caption2)
                                .foregroundStyle(tone.color)
                        }

                        if showChevron {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // Capsule "수위 바"
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(tone.color.opacity(0.12))

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tone.color.opacity(0.6), tone.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(value)))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule(style: .continuous))

                if let topProcess {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(tone.color)
                        Text("가장 큰 물결  \(topProcess)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.03 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Shared UI Components

struct TrayCard<Content: View>: View {
    let tint: Color
    @ViewBuilder var content: Content

    init(tint: Color = .clear, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tint)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PondTheme.lilyPadGradient)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(PondTheme.lilyPadGreen.opacity(0.15), lineWidth: 1)
                    }
            }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(PondTheme.lilyPadGreen)
                    .frame(width: 6, height: 6)

                Text(title)
                    .font(.headline)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatusBadge: View {
    let title: String
    let tone: UsageTone

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tone.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.color.opacity(0.15))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(tone.color.opacity(0.25), lineWidth: 0.5)
            )
    }
}

private struct InlineStatusMessage: View {
    let iconName: String
    let message: String
    let tone: StatusTone

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tone.color)
                .frame(width: 14)

            Text(message)
                .font(.caption)
                .foregroundStyle(tone.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - FrogStatusIcon (inline, used in summaryCard)

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

// MARK: - StatusTone

private enum StatusTone {
    case positive
    case neutral
    case warning
    case error

    var color: Color {
        switch self {
        case .positive:
            return PondTheme.lilyPadGreen
        case .neutral:
            return .secondary
        case .warning:
            return UsageTone.caution.color
        case .error:
            return UsageTone.critical.color
        }
    }

    var iconName: String {
        switch self {
        case .positive:
            return "checkmark.seal.fill"
        case .neutral:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }
}

// MARK: - SystemSnapshot Extensions

private extension SystemSnapshot {
    var dominantMetric: (title: String, value: Double, tone: UsageTone) {
        [
            (title: "CPU", value: cpuUsage, tone: UsageTone(value: cpuUsage)),
            (title: "Memory", value: memoryUsage, tone: UsageTone(value: memoryUsage)),
            (title: "Disk", value: diskUsage, tone: UsageTone(value: diskUsage))
        ]
        .max { lhs, rhs in lhs.value < rhs.value }
        ?? (title: "CPU", value: cpuUsage, tone: UsageTone(value: cpuUsage))
    }

    var summaryLine: String {
        "CPU \(cpuUsage.percentText) · MEM \(memoryUsage.percentText) · DISK \(diskUsage.percentText)"
    }
}

private extension Double {
    var statusDescription: String {
        switch UsageTone(value: self) {
        case .stable:
            return "연못 수면이 고요합니다"
        case .caution:
            return "수면에 파문이 일고 있습니다"
        case .critical:
            return "연못이 범람 직전입니다!"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView(
        monitor: SystemMetricsMonitor(refreshInterval: 60),
        launchAtLoginManager: LaunchAtLoginManager(
            controller: PreviewLaunchAtLoginController(status: .requiresApproval)
        ),
        processMonitor: ProcessMonitor(refreshInterval: 60)
    )
}

private struct PreviewLaunchAtLoginController: LaunchAtLoginControlling {
    let status: LaunchAtLoginStatus

    func register() throws {}
    func unregister() throws {}
    func openSystemSettingsLoginItems() {}
}
