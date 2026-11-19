//
//  MiniComponents.swift
//  MiniFocus
//
//  Mini Focus shared UI components, built on the design tokens.
//
//  Reusable building blocks so screens stay consistent and free of hardcoded
//  colors, fonts and spacing: buttons, cards, status indicators, empty states
//  and a screen container.
//

import SwiftUI

// MARK: - Screen container

/// Standard screen background and horizontal padding for Mini Focus.
struct MiniScreen<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            MiniColor.background.ignoresSafeArea()
            content
        }
    }
}

// MARK: - Buttons

/// Filled primary action. Full width, >= 52 pt tall, rounded 16 pt.
struct MiniPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MiniFont.bodyEmphasized)
            .foregroundStyle(MiniColor.onPrimary)
            .frame(maxWidth: .infinity, minHeight: MiniControl.buttonMinHeight)
            .padding(.horizontal, MiniSpacing.lg)
            .background(MiniColor.primary, in: RoundedRectangle(cornerRadius: MiniRadius.button, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
    }
}

/// Outlined secondary action. Same metrics as the primary button.
struct MiniSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MiniFont.bodyEmphasized)
            .foregroundStyle(MiniColor.primary)
            .frame(maxWidth: .infinity, minHeight: MiniControl.buttonMinHeight)
            .padding(.horizontal, MiniSpacing.lg)
            .background(MiniColor.surface, in: RoundedRectangle(cornerRadius: MiniRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MiniRadius.button, style: .continuous)
                    .stroke(MiniColor.primary, lineWidth: 1.5)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

/// Low-emphasis text action. Keeps a 44 pt tap target.
struct MiniQuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MiniFont.body)
            .foregroundStyle(MiniColor.primary)
            .frame(minHeight: MiniControl.tapTargetMinSize)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == MiniPrimaryButtonStyle {
    static var miniPrimary: MiniPrimaryButtonStyle { MiniPrimaryButtonStyle() }
}

extension ButtonStyle where Self == MiniSecondaryButtonStyle {
    static var miniSecondary: MiniSecondaryButtonStyle { MiniSecondaryButtonStyle() }
}

extension ButtonStyle where Self == MiniQuietButtonStyle {
    static var miniQuiet: MiniQuietButtonStyle { MiniQuietButtonStyle() }
}

// MARK: - Card

/// Rounded surface container with standard padding.
struct MiniCard<Content: View>: View {
    private let fill: Color
    private let content: Content

    init(fill: Color = MiniColor.surface, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        content
            .padding(MiniSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: MiniRadius.card, style: .continuous))
    }
}

// MARK: - Status indicator

/// Icon + label status. Never relies on color alone — an SF Symbol always
/// accompanies the text so state reads without color perception.
struct MiniStatusMark: View {
    let systemImage: String
    let title: String
    var tint: Color = MiniColor.primary

    var body: some View {
        Label {
            Text(title)
                .font(MiniFont.caption)
                .foregroundStyle(MiniColor.text)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .padding(.vertical, MiniSpacing.xs)
        .padding(.horizontal, MiniSpacing.sm)
        .background(MiniColor.sage, in: Capsule())
    }
}

// MARK: - Empty state

/// Centered empty state: symbol, title, supporting text and optional action.
struct MiniEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: MiniSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(MiniColor.muted)
            Text(title)
                .font(MiniFont.title)
                .foregroundStyle(MiniColor.text)
                .multilineTextAlignment(.center)
            Text(message)
                .font(MiniFont.body)
                .foregroundStyle(MiniColor.muted)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.miniSecondary)
                    .padding(.top, MiniSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MiniSpacing.xl)
    }
}
