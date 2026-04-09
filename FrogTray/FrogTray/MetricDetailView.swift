//
//  MetricDetailView.swift
//  FrogTray
//
//  Created by Claude on 3/14/26.
//

import SwiftUI

struct MetricDetailView: View {
    let kind: MetricKind
    let snapshot: SystemSnapshot
    @ObservedObject var processMonitor: ProcessMonitor
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            backButton

            switch kind {
            case .cpu:
                cpuDetailContent
            case .memory:
                memoryDetailContent
            case .disk:
                diskDetailContent
            }
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
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                Text("뒤로")
                    .font(.subheadline)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .keyboardShortcut(.escape, modifiers: [])
    }

    // MARK: - CPU Detail

    private var cpuDetailContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricHeader(
                title: "CPU",
                iconName: "cpu",
                value: snapshot.cpuUsage,
                tone: UsageTone(value: snapshot.cpuUsage)
            )

            if let detail = snapshot.cpuDetail {
                TrayCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "사용률 분류", subtitle: "User / System / Idle 비율")

                        usageBar(label: "User", value: detail.userUsage, color: PondTheme.pondSurface)
                        usageBar(label: "System", value: detail.systemUsage, color: PondTheme.mossFern)
                        usageBar(label: "Idle", value: detail.idleUsage, color: PondTheme.lilyPadGreen)
                    }
                }

                if !detail.coreUsages.isEmpty {
                    TrayCard {
                        DisclosureGroup("코어별 사용률 (\(detail.coreUsages.count)개)") {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 6) {
                                ForEach(Array(detail.coreUsages.enumerated()), id: \.offset) { index, usage in
                                    HStack(spacing: 4) {
                                        Text("\(index)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 16, alignment: .trailing)

                                        Gauge(value: usage, in: 0...1) {
                                            EmptyView()
                                        }
                                        .gaugeStyle(.accessoryLinear)
                                        .tint(UsageTone(value: usage).color)

                                        Text(usage.percentText)
                                            .font(.caption2.monospacedDigit())
                                            .frame(width: 32, alignment: .trailing)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        .font(.caption)
                    }
                }
            }

            processListCard(
                title: "CPU 물결 상위",
                subtitle: "연못에서 가장 큰 파문을 일으키는 생물",
                processes: processMonitor.topCPUProcesses,
                valueFormatter: { String(format: "%.1f%%", $0.totalCPUUsage) }
            )
        }
    }

    // MARK: - Memory Detail

    private var memoryDetailContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricHeader(
                title: "Memory",
                iconName: "memorychip",
                value: snapshot.memoryUsage,
                tone: UsageTone(value: snapshot.memoryUsage)
            )

            TrayCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "메모리 용량", subtitle: "사용 / 총 용량")

                    detailRow(label: "사용", value: snapshot.memoryUsedText)
                    detailRow(label: "총 용량", value: snapshot.memoryTotalText)

                    if let detail = snapshot.memoryDetail {
                        Divider()

                        SectionHeader(title: "분류별 용량", subtitle: "메모리 사용 분류")

                        detailRow(label: "Active", value: formatBytes(detail.activeBytes))
                        detailRow(label: "Wired", value: formatBytes(detail.wiredBytes))
                        detailRow(label: "Compressed", value: formatBytes(detail.compressedBytes))
                        detailRow(label: "Inactive", value: formatBytes(detail.inactiveBytes))
                        detailRow(label: "Free", value: formatBytes(detail.freeBytes))
                    }
                }
            }

            processListCard(
                title: "메모리 서식 상위",
                subtitle: "연못에서 가장 넓은 자리를 차지하는 생물",
                processes: processMonitor.topMemoryProcesses,
                valueFormatter: { formatBytes($0.totalMemoryBytes) }
            )
        }
    }

    // MARK: - Disk Detail

    private var diskDetailContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricHeader(
                title: "Disk",
                iconName: "internaldrive",
                value: snapshot.diskUsage,
                tone: UsageTone(value: snapshot.diskUsage)
            )

            TrayCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "디스크 용량", subtitle: "사용 / 여유 / 퍼지 가능")

                    detailRow(label: "사용", value: snapshot.diskUsedText)
                    detailRow(label: "총 용량", value: snapshot.diskTotalText)

                    if let detail = snapshot.diskDetail {
                        Divider()

                        detailRow(label: "여유 공간", value: formatDiskBytes(detail.freeBytes))
                        detailRow(label: "퍼지 가능", value: formatDiskBytes(detail.purgeableBytes))
                    }
                }
            }

            processListCard(
                title: "Disk I/O 활동 상위",
                subtitle: "연못 바닥을 가장 많이 뒤젓는 생물",
                processes: processMonitor.topDiskIOProcesses,
                valueFormatter: { formatBytes($0.totalDiskIOBytes) }
            )
        }
    }

    // MARK: - Shared Components

    private func metricHeader(title: String, iconName: String, value: Double, tone: UsageTone) -> some View {
        TrayCard(tint: tone.color.opacity(0.10)) {
            HStack(spacing: 16) {
                ZStack {
                    Gauge(value: value, in: 0...1) {
                        Image(systemName: iconName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(tone.color)
                    .scaleEffect(1.4)

                    Circle()
                        .strokeBorder(tone.color.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.title2.bold())

                        Spacer()

                        StatusBadge(title: tone.badgeTitle, tone: tone)
                    }

                    Text(value.percentText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
        }
    }

    private func usageBar(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(color.opacity(0.12))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(max(0, min(value, 1)))))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule(style: .continuous))

            Text(value.percentText)
                .font(.caption.monospacedDigit())
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption.monospacedDigit().bold())
        }
    }

    private func processListCard(
        title: String,
        subtitle: String,
        processes: [ProcessGroup],
        valueFormatter: @escaping (ProcessGroup) -> String
    ) -> some View {
        TrayCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: title, subtitle: subtitle)

                if !processMonitor.isWarmedUp {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("연못을 관찰하는 중…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else if processes.isEmpty {
                    Text("연못이 조용합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(processes.enumerated()), id: \.element.id) { index, process in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(PondTheme.lilyPadGreen.opacity(1.0 - Double(index) * 0.18))
                                .frame(width: 6, height: 6)

                            Text(process.displayName)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Text(valueFormatter(process))
                                .font(.caption.monospacedDigit().bold())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Formatters

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .memory)
    }

    private func formatDiskBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
