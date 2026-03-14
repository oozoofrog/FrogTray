//
//  PondState.swift
//  FrogTray
//
//  6-stage pond state model with SF Symbol mapping.
//

import SwiftUI

enum PondState: String, CaseIterable, Sendable {
    case sleeping   // CPU<10%, MEM<30%, DSK<30%
    case relaxed    // default 0-39%
    case normal     // 40-64%
    case caution    // 65-84%
    case danger     // 85%+
    case loading    // no data yet

    init(snapshot: SystemSnapshot) {
        guard snapshot.cpuDetail != nil || snapshot.memoryDetail != nil else {
            self = .loading
            return
        }

        if snapshot.cpuUsage < 0.10 && snapshot.memoryUsage < 0.30 && snapshot.diskUsage < 0.30 {
            self = .sleeping
            return
        }

        switch snapshot.worstUsage {
        case 0.85...:
            self = .danger
        case 0.65...:
            self = .caution
        case 0.40...:
            self = .normal
        default:
            self = .relaxed
        }
    }

    var sfSymbolName: String {
        switch self {
        case .sleeping: "moon.zzz.fill"
        case .relaxed:  "leaf.fill"
        case .normal:   "cloud.fill"
        case .caution:  "cloud.bolt.fill"
        case .danger:   "tornado"
        case .loading:  "ellipsis.circle"
        }
    }

    var storyTitle: String {
        switch self {
        case .sleeping: "고요한 밤 연못"
        case .relaxed:  "맑은 연못"
        case .normal:   "흐린 연못"
        case .caution:  "폭풍우 연못"
        case .danger:   "토네이도 연못"
        case .loading:  "연못 관찰 중"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .sleeping: "시스템이 매우 여유롭습니다. 잠자기 상태"
        case .relaxed:  "시스템이 여유롭습니다"
        case .normal:   "시스템 사용량이 보통입니다"
        case .caution:  "시스템 사용량에 주의가 필요합니다"
        case .danger:   "시스템 사용량이 위험 수준입니다"
        case .loading:  "시스템 정보를 불러오는 중입니다"
        }
    }
}
