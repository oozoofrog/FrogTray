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

                        usageBar(label: "User", value: detail.userUsage, color: .blue)
                        usageBar(label: "System", value: detail.systemUsage, color: .red)
                        usageBar(label: "Idle", value: detail.idleUsage, color: .gray)
                    }
                }

                if !detail.coreUsages.isEmpty {
                    TrayCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "코어별 사용률", subtitle: "\(detail.coreUsages.count)개 코어")

                            ForEach(Array(detail.coreUsages.enumerated()), id: \.offset) { index, usage in
                                HStack(spacing: 8) {
                                    Text("코어 \(index)")
                                        .font(.caption.monospacedDigit())
                                        .frame(width: 50, alignment: .leading)

                                    Gauge(value: usage, in: 0...1) {
                                        EmptyView()
                                    }
                                    .gaugeStyle(.accessoryLinear)
                                    .tint(UsageTone(value: usage).color)

                                    Text(usage.percentText)
                                        .font(.caption.monospacedDigit())
                                        .frame(width: 36, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
            }

            processListCard(
                title: "CPU 사용량 상위",
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
                title: "메모리 사용량 상위",
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
                title: "Disk I/O 상위",
                processes: processMonitor.topDiskIOProcesses,
                valueFormatter: { formatBytes($0.totalDiskIOBytes) }
            )
        }
    }

    // MARK: - Shared Components

    private func metricHeader(title: String, iconName: String, value: Double, tone: UsageTone) -> some View {
        TrayCard(tint: tone.color.opacity(0.10)) {
            HStack(spacing: 16) {
                Gauge(value: value, in: 0...1) {
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(tone.color)
                .scaleEffect(1.4)
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

            Gauge(value: max(0, min(value, 1)), in: 0...1) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            .tint(color)

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
        processes: [ProcessGroup],
        valueFormatter: @escaping (ProcessGroup) -> String
    ) -> some View {
        TrayCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: title, subtitle: "프로세스별 사용량 (상위 5개)")

                if processes.isEmpty {
                    Text("데이터 수집 중…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(processes) { process in
                        HStack {
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
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func formatDiskBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
