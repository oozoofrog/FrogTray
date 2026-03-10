//
//  FrogTrayTests.swift
//  FrogTrayTests
//
//  Created by oozoofrog on 3/7/26.
//

import Foundation
import Testing
@testable import FrogTray

@MainActor
struct FrogTrayTests {

    @Test func enabledStatusTurnsToggleOn() {
        let controller = MockLaunchAtLoginController(status: .enabled)
        let manager = LaunchAtLoginManager(controller: controller)

        #expect(manager.isEnabled)
        #expect(manager.statusMessage == "로그인 시 FrogTray가 자동으로 실행됩니다.")
    }

    @Test func enablingRegistersMainAppLoginItem() {
        let controller = MockLaunchAtLoginController(status: .notRegistered)
        controller.status = .notRegistered
        controller.statusAfterRegister = .enabled

        let manager = LaunchAtLoginManager(controller: controller)
        manager.setLaunchAtLoginEnabled(true)

        #expect(controller.registerCallCount == 1)
        #expect(manager.status == .enabled)
        #expect(manager.isEnabled)
        #expect(manager.errorMessage == nil)
    }

    @Test func approvalRequiredKeepsToggleOnAndShowsSettingsButton() {
        let controller = MockLaunchAtLoginController(status: .notRegistered)
        controller.statusAfterRegister = .requiresApproval

        let manager = LaunchAtLoginManager(controller: controller)
        manager.setLaunchAtLoginEnabled(true)

        #expect(manager.status == .requiresApproval)
        #expect(manager.isEnabled)
        #expect(manager.shouldShowSystemSettingsButton)
        #expect(manager.errorMessage == nil)
    }

    @Test func unregisterFailureShowsErrorWhenStateDoesNotChange() {
        let controller = MockLaunchAtLoginController(status: .enabled)
        controller.unregisterError = MockLaunchAtLoginError.operationFailed

        let manager = LaunchAtLoginManager(controller: controller)
        manager.setLaunchAtLoginEnabled(false)

        #expect(controller.unregisterCallCount == 1)
        #expect(manager.status == .enabled)
        #expect(manager.isEnabled)
        #expect(manager.errorMessage?.contains("로그인 시 자동 실행을 끄는 데 실패했습니다.") == true)
    }

    @Test func openingSystemSettingsDelegatesToController() {
        let controller = MockLaunchAtLoginController(status: .requiresApproval)
        let manager = LaunchAtLoginManager(controller: controller)

        manager.openSystemSettingsLoginItems()

        #expect(controller.openSystemSettingsCallCount == 1)
    }

}

private enum MockLaunchAtLoginError: LocalizedError {
    case operationFailed

    var errorDescription: String? {
        "mock failure"
    }
}

@MainActor
private final class MockLaunchAtLoginController: LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus
    var statusAfterRegister: LaunchAtLoginStatus?
    var statusAfterUnregister: LaunchAtLoginStatus?
    var registerError: Error?
    var unregisterError: Error?
    var registerCallCount = 0
    var unregisterCallCount = 0
    var openSystemSettingsCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1

        if let registerError {
            throw registerError
        }

        if let statusAfterRegister {
            status = statusAfterRegister
        }
    }

    func unregister() throws {
        unregisterCallCount += 1

        if let unregisterError {
            throw unregisterError
        }

        if let statusAfterUnregister {
            status = statusAfterUnregister
        } else {
            status = .notRegistered
        }
    }

    func openSystemSettingsLoginItems() {
        openSystemSettingsCallCount += 1
    }
}
