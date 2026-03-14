//
//  MenuBarTooltipView.swift
//  FrogTray
//
//  Mini dashboard shown in NSPopover on hover.
//

import SwiftUI

struct MenuBarTooltipView: View {
    let snapshot: SystemSnapshot
    let state: PondState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: state.sfSymbolName)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(characterColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.storyTitle)
                        .font(.headline)

                    Text(snapshot.lastUpdated.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            tooltipRow(label: "CPU", value: snapshot.cpuUsage)
            tooltipRow(label: "Memory", value: snapshot.memoryUsage, detail: "\(snapshot.memoryUsedText) / \(snapshot.memoryTotalText)")
            tooltipRow(label: "Disk", value: snapshot.diskUsage, detail: "\(snapshot.diskUsedText) / \(snapshot.diskTotalText)")
        }
        .padding(12)
        .frame(width: 220)
    }

    private var characterColor: Color {
        switch state {
        case .danger: UsageTone.critical.color
        case .caution: UsageTone.caution.color
        default: PondTheme.lilyPadGreen
        }
    }

    private func tooltipRow(label: String, value: Double, detail: String? = nil) -> some View {
        let tone = UsageTone(value: value)
        return HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(tone.color.opacity(0.15))

                    Capsule(style: .continuous)
                        .fill(tone.color)
                        .frame(width: max(0, geo.size.width * CGFloat(value)))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule(style: .continuous))

            Text(value.percentText)
                .font(.caption.monospacedDigit().bold())
                .frame(width: 36, alignment: .trailing)
        }
    }
}
