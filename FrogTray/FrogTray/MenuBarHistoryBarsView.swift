//
//  MenuBarHistoryBarsView.swift
//  FrogTray
//
//  Mini bar graph showing recent 3 readings for CPU/Memory/Disk.
//  Replaces the old "C32 M67 D74" text label.
//

import SwiftUI

struct MenuBarHistoryBarsView: View {
    let history: MetricsHistory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 1
    private let groupSpacing: CGFloat = 3
    private let maxBarHeight: CGFloat = 12
    private let labelFont = Font.system(size: 7, weight: .bold, design: .rounded)

    var body: some View {
        HStack(spacing: groupSpacing) {
            metricGroup(label: "C", values: history.cpuValues)
            metricGroup(label: "M", values: history.memoryValues)
            metricGroup(label: "D", values: history.diskValues)
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    private func metricGroup(label: String, values: [Double]) -> some View {
        VStack(spacing: 1) {
            HStack(spacing: barSpacing) {
                ForEach(0..<3, id: \.self) { index in
                    let value = index < values.count ? values[index] : 0
                    singleBar(value: value)
                }
            }
            .frame(height: maxBarHeight)

            Text(label)
                .font(labelFont)
                .foregroundStyle(.secondary)
        }
    }

    private func singleBar(value: Double) -> some View {
        let tone = UsageTone(value: value)
        let height = max(1, maxBarHeight * CGFloat(value))
        return VStack {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 1)
                .fill(tone.color)
                .frame(width: barWidth, height: height)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: value)
        }
    }
}
