//
//  MenuBarHistoryBarsView.swift
//  FrogTray
//
//  Emoji-based metric labels showing CPU/Memory/Disk percentages.
//

import SwiftUI

struct MenuBarHistoryBarsView: View {
    let history: MetricsHistory

    private let font = Font.system(size: 11, weight: .medium, design: .rounded)

    var body: some View {
        HStack(spacing: 6) {
            metricLabel("🖥", value: history.cpuValues.last ?? 0)
            metricLabel("💾", value: history.memoryValues.last ?? 0)
            metricLabel("💿", value: history.diskValues.last ?? 0)
        }
        .accessibilityHidden(true)
    }

    private func metricLabel(_ emoji: String, value: Double) -> some View {
        Text("\(emoji)\(Int((value * 100).rounded()))%")
            .font(font)
            .monospacedDigit()
    }
}
