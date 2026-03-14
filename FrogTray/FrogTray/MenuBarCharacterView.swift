//
//  MenuBarCharacterView.swift
//  FrogTray
//
//  Animated SF Symbol character for the menu bar.
//  Includes breathing, blinking, state-specific motion, and symbol morphing.
//

import SwiftUI

struct MenuBarCharacterView: View {
    let state: PondState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var breathPhase = false
    @State private var isBlinking = false
    @State private var motionPhase = false
    @State private var blinkTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: state.sfSymbolName)
            .font(.system(size: 14, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(characterColor)
            .scaleEffect(animatedScale)
            .opacity(isBlinking ? 0.3 : 1.0)
            .modifier(StateMotionModifier(state: state, active: motionPhase))
            .contentTransition(.symbolEffect(.replace.byLayer))
            .frame(width: 18, height: 16)
            .onAppear { startAnimations() }
            .onDisappear { stopAnimations() }
            .accessibilityHidden(true)
    }

    // MARK: - Computed

    private var characterColor: Color {
        switch state {
        case .sleeping:
            return PondTheme.characterAccent(for: colorScheme)
        case .danger:
            return UsageTone.critical.color
        case .caution:
            return UsageTone.caution.color
        default:
            return PondTheme.characterTint(for: colorScheme)
        }
    }

    private var animatedScale: CGFloat {
        guard !reduceMotion else { return 1.0 }
        let base: CGFloat = breathPhase ? 1.05 : 1.0
        return state == .danger ? base * 1.08 : base
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathPhase = true
        }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            motionPhase = true
        }

        blinkTask = Task {
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(Double.random(in: 4...6)))
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isBlinking = true
                    }
                    try await Task.sleep(for: .milliseconds(150))
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isBlinking = false
                    }
                }
            } catch is CancellationError {
                // Expected when stopAnimations() cancels the task
            } catch {
                // Unexpected error; stop blinking gracefully
            }
        }
    }

    private func stopAnimations() {
        blinkTask?.cancel()
        blinkTask = nil
    }
}

// MARK: - State Motion Modifier

private struct StateMotionModifier: ViewModifier {
    let state: PondState
    let active: Bool

    func body(content: Content) -> some View {
        let phase = active ? 1.0 : 0.0
        switch state {
        case .sleeping:
            content.offset(y: phase * 1.5)
        case .caution:
            content.rotationEffect(.degrees(phase * 4 - 2))
        case .danger:
            content.rotationEffect(.degrees(phase * 10 - 5))
        default:
            content
        }
    }
}
