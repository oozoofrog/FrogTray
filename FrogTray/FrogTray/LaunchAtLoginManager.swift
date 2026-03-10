//
//  LaunchAtLoginManager.swift
//  FrogTray
//
//  Created by Codex on 3/11/26.
//

import Combine
import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

protocol LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettingsLoginItems()
}

struct SMAppLaunchAtLoginService: LaunchAtLoginControlling {
    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
    }

    var status: LaunchAtLoginStatus {
        switch service.status {
        case .notRegistered:
            .notRegistered
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .notFound
        @unknown default:
            .notFound
        }
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var status: LaunchAtLoginStatus
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?

    private let controller: any LaunchAtLoginControlling

    init(controller: (any LaunchAtLoginControlling)? = nil) {
        let controller = controller ?? SMAppLaunchAtLoginService()
        self.controller = controller
        self.status = controller.status
    }

    var isEnabled: Bool {
        switch status {
        case .enabled, .requiresApproval:
            true
        case .notRegistered, .notFound:
            false
        }
    }

    var statusMessage: String {
        switch status {
        case .enabled:
            "로그인 시 FrogTray가 자동으로 실행됩니다."
        case .notRegistered:
            "로그인 시 자동 실행이 꺼져 있습니다."
        case .requiresApproval:
            "시스템 설정 > 일반 > 로그인 항목에서 FrogTray를 허용해야 자동 실행됩니다."
        case .notFound:
            "자동 실행 항목을 찾을 수 없습니다. 앱을 다시 설치해 보세요."
        }
    }

    var shouldShowSystemSettingsButton: Bool {
        status == .requiresApproval
    }

    func refresh() {
        reloadStatus(clearingError: true)
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        guard !isUpdating else { return }

        isUpdating = true
        errorMessage = nil

        defer {
            isUpdating = false
        }

        do {
            if enabled {
                try controller.register()
            } else {
                try controller.unregister()
            }

            reloadStatus(clearingError: false)
        } catch {
            reloadStatus(clearingError: false)

            let requestSucceeded = enabled ? isEnabled : !isEnabled
            if !requestSucceeded {
                errorMessage = userFacingMessage(for: error, enabling: enabled)
            }
        }
    }

    func openSystemSettingsLoginItems() {
        controller.openSystemSettingsLoginItems()
    }

    private func reloadStatus(clearingError: Bool) {
        status = controller.status
        if clearingError {
            errorMessage = nil
        }
    }

    private func userFacingMessage(for error: Error, enabling: Bool) -> String {
        let action = enabling ? "켜는" : "끄는"
        let message = (error as NSError).localizedDescription
        return "로그인 시 자동 실행을 \(action) 데 실패했습니다. \(message)"
    }
}
