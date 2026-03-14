//
//  PondTheme.swift
//  FrogTray
//
//  Extracted from ContentView.swift — shared color palette + usage tone.
//

import SwiftUI

// MARK: - PondTheme

enum PondTheme {
    // Day pond colors
    static let pondDeep = Color(hue: 0.48, saturation: 0.55, brightness: 0.30)
    static let pondMid = Color(hue: 0.46, saturation: 0.40, brightness: 0.50)
    static let pondSurface = Color(hue: 0.44, saturation: 0.30, brightness: 0.65)
    static let lilyPadGreen = Color(hue: 0.35, saturation: 0.35, brightness: 0.55)
    static let lilyPadLight = Color(hue: 0.33, saturation: 0.20, brightness: 0.75)
    static let mossFern = Color(hue: 0.30, saturation: 0.45, brightness: 0.40)

    // Night pond colors (dark mode)
    static let nightDeep = Color(hue: 0.62, saturation: 0.60, brightness: 0.20)
    static let nightMid = Color(hue: 0.60, saturation: 0.45, brightness: 0.35)
    static let moonlightSilver = Color(hue: 0.55, saturation: 0.08, brightness: 0.82)
    static let starGlow = Color(hue: 0.15, saturation: 0.20, brightness: 0.90)

    static let pondGradient = LinearGradient(
        colors: [pondDeep, pondMid, pondSurface.opacity(0.3)],
        startPoint: .bottom,
        endPoint: .top
    )

    static let lilyPadGradient = LinearGradient(
        colors: [lilyPadGreen.opacity(0.08), lilyPadLight.opacity(0.04)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    static func characterTint(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? moonlightSilver : lilyPadGreen
    }

    static func characterAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? starGlow : pondSurface
    }
}

// MARK: - UsageTone

enum UsageTone {
    case stable
    case caution
    case critical

    init(value: Double) {
        switch value {
        case 0.85...:
            self = .critical
        case 0.65...:
            self = .caution
        default:
            self = .stable
        }
    }

    var color: Color {
        switch self {
        case .stable:
            return Color(hue: 0.48, saturation: 0.65, brightness: 0.75)
        case .caution:
            return Color(hue: 0.10, saturation: 0.70, brightness: 0.85)
        case .critical:
            return Color(hue: 0.02, saturation: 0.60, brightness: 0.90)
        }
    }

    var badgeTitle: String {
        switch self {
        case .stable:
            return "잔잔"
        case .caution:
            return "출렁"
        case .critical:
            return "넘침"
        }
    }
}
