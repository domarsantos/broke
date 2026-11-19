//
//  TodayView.swift
//  MiniFocus
//
//  Mini Focus "Hoje" screen. Shows the current focus state and the controls to
//  start/stop a session. All activation and lock logic lives in
//  FocusController / FocusRules; this view contains no NFC, Screen Time or
//  lock business rules — it only reads domain state and shows the matching UI.
//

import SwiftUI
import CoreNFC

struct TodayView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(ModeStore.self) private var modeStore
    @Environment(FocusController.self) private var focusController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pairingScan: ScannedTag?
    @State private var showNoModeAlert = false
    @State private var showStrictAlert = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var noticeTitle: String = ""
    @State private var noticeMessage: String?
    @State private var isAuthorized = true

    private var isBlocking: Bool { focusController.isActive }
    private var hasModes: Bool { !modeStore.modes.isEmpty }
    private var activeMode: Mode? { focusController.activeMode }

    var body: some View {
        NavigationStack {
            MiniScreen {
                ScrollView {
                    VStack(spacing: MiniSpacing.section) {
                        brandHeader

                        if !isAuthorized {
                            permissionCard
                        }

                        statusBlock

                        actions
                    }
                    .padding(.horizontal, MiniSpacing.horizontal)
                    .padding(.top, MiniSpacing.xl)
                    .padding(.bottom, MiniSpacing.section)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(MiniCopy.navToday)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("MiniMark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .accessibilityLabel(MiniCopy.appName)
                }
            }
            .alert(MiniCopy.noModeTitle, isPresented: $showNoModeAlert) {
                Button(MiniCopy.actionOK, role: .cancel) {}
            } message: {
                Text(MiniCopy.noModeBody)
            }
            .alert(MiniCopy.homeStrictAlertTitle, isPresented: $showStrictAlert) {
                Button(MiniCopy.actionOK, role: .cancel) {}
            } message: {
                Text(MiniCopy.homeStrictAlertBody)
            }
            .alert(noticeTitle, isPresented: Binding(
                get: { noticeMessage != nil },
                set: { if !$0 { noticeMessage = nil } }
            )) {
                Button(MiniCopy.actionOK, role: .cancel) { noticeMessage = nil }
            } message: {
                Text(noticeMessage ?? "")
            }
            .alert(MiniCopy.nfcErrorTitle, isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(MiniCopy.actionOK, role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert(MiniCopy.tagUnknownTitle, isPresented: Binding(
                get: { infoMessage != nil },
                set: { if !$0 { infoMessage = nil } }
            )) {
                Button(MiniCopy.actionOK, role: .cancel) { infoMessage = nil }
            } message: {
                Text(infoMessage ?? "")
            }
            .sheet(item: $pairingScan) { scan in
                TagPairingView(prefilledScan: scan)
            }
        }
        .onAppear(perform: refreshAuthorization)
        .animation(MiniMotion.standardAnimation(reduceMotion: reduceMotion), value: isBlocking)
    }

    // MARK: - Sections

    private var brandHeader: some View {
        Text(MiniCopy.tagline)
            .font(MiniFont.caption)
            .foregroundStyle(MiniColor.muted)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statusBlock: some View {
        VStack(spacing: MiniSpacing.md) {
            MiniStatusMark(
                systemImage: isBlocking ? "circle.dotted.circle" : "moon.zzz",
                title: isBlocking ? MiniCopy.homeOnTitle : MiniCopy.homeOffTitle
            )

            Text(statusTitle)
                .font(MiniFont.largeTitle)
                .foregroundStyle(MiniColor.text)
                .multilineTextAlignment(.center)

            Text(statusBody)
                .font(MiniFont.body)
                .foregroundStyle(MiniColor.muted)
                .multilineTextAlignment(.center)

            if isBlocking, let mode = activeMode, let session = focusController.activeSession {
                activeModeCard(mode: mode, session: session)
                    .padding(.top, MiniSpacing.xs)

                if mode.isSecurityMode {
                    securityBanner
                } else if mode.isStrictMode {
                    strictInstruction
                }
            }
        }
    }

    private func activeModeCard(mode: Mode, session: FocusSession) -> some View {
        MiniCard(fill: MiniColor.sage) {
            VStack(alignment: .leading, spacing: MiniSpacing.sm) {
                HStack(spacing: MiniSpacing.md) {
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundStyle(MiniColor.primary)
                        .frame(width: 44, height: 44)
                        .background(MiniColor.surface, in: Circle())
                    VStack(alignment: .leading, spacing: MiniSpacing.unit) {
                        Text(mode.name)
                            .font(MiniFont.bodyEmphasized)
                            .foregroundStyle(MiniColor.text)
                        if mode.isStrictMode {
                            Text(MiniCopy.homeStrictBadge)
                                .font(MiniFont.caption)
                                .foregroundStyle(MiniColor.primary)
                        }
                        Text(MiniCopy.homeActiveSince(session.startedAt.formatted(date: .omitted, time: .shortened)))
                            .font(MiniFont.caption)
                            .foregroundStyle(MiniColor.muted)
                    }
                    Spacer(minLength: 0)
                }

                elapsedTimer(since: session.startedAt)
            }
        }
    }

    private func elapsedTimer(since start: Date) -> some View {
        TimelineView(.periodic(from: start, by: 1)) { context in
            Text(Self.elapsedString(from: start, to: context.date))
                .font(MiniFont.largeTitle.monospacedDigit())
                .foregroundStyle(MiniColor.text)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel(Text(Self.elapsedString(from: start, to: context.date)))
        }
    }

    private var strictInstruction: some View {
        Text(MiniCopy.homeStrictInstruction)
            .font(MiniFont.caption)
            .foregroundStyle(MiniColor.muted)
            .multilineTextAlignment(.center)
    }

    private var securityBanner: some View {
        MiniCard {
            Label {
                Text(MiniCopy.homeSecurityBanner)
                    .font(MiniFont.caption)
                    .foregroundStyle(MiniColor.text)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(MiniColor.primary)
            }
        }
    }

    private var permissionCard: some View {
        MiniCard {
            VStack(alignment: .leading, spacing: MiniSpacing.sm) {
                Label(MiniCopy.permissionTitle, systemImage: "lock.shield")
                    .font(MiniFont.bodyEmphasized)
                    .foregroundStyle(MiniColor.text)
                Text(MiniCopy.permissionBody)
                    .font(MiniFont.caption)
                    .foregroundStyle(MiniColor.muted)
                Button(MiniCopy.permissionCTA, action: requestAuthorization)
                    .buttonStyle(.miniSecondary)
                    .padding(.top, MiniSpacing.xs)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: MiniSpacing.sm) {
            Button(action: { Task { await scanTag() } }) {
                Text(isBlocking ? MiniCopy.homeOnCTA : MiniCopy.homeOffCTA)
            }
            .buttonStyle(.miniPrimary)

            if isBlocking {
                // Security Mode never shows a manual stop. Strict shows one that
                // explains it must be ended with a tag. Normal modes stop here.
                if activeMode?.isSecurityMode == false {
                    Button(MiniCopy.homeEndFocus, action: endFocus)
                        .buttonStyle(.miniQuiet)
                }
            } else {
                Button(MiniCopy.homeStartWithoutTag, action: startWithoutTag)
                    .buttonStyle(.miniQuiet)
            }
        }
    }

    // MARK: - Derived copy

    private var statusTitle: String {
        if isBlocking { return MiniCopy.homeOnTitle }
        return hasModes ? MiniCopy.homeOffTitle : MiniCopy.homePrepareTitle
    }

    private var statusBody: String {
        if isBlocking { return MiniCopy.homeOnBody }
        return hasModes ? MiniCopy.homeOffBody : MiniCopy.homePrepareBody
    }

    // MARK: - Actions

    private func refreshAuthorization() {
        isAuthorized = env.screenTime.authorizationStatus() == .approved
    }

    private func requestAuthorization() {
        Task {
            try? await env.screenTime.authorize()
            refreshAuthorization()
        }
    }

    private func scanTag() async {
        do {
            let scanned = try await env.nfcService.scan()
            let outcome = try focusController.handleScan(
                scanned,
                fallbackModeID: modeStore.selectedModeID
            )
            switch outcome {
            case .unregistered:
                // Never open the pairing sheet while a locked session is active:
                // just inform the user which tag is needed.
                if focusController.isLockedActive {
                    infoMessage = MiniCopy.homeLockedUnknownTag
                } else {
                    pairingScan = scanned
                }
            case .noModeToActivate:
                showNoModeAlert = true
            case let .denied(reason):
                infoMessage = describe(reason)
            case .activated, .deactivated, .switched:
                break // state updates drive the UI
            }
        } catch let error as NFCServiceError {
            if error != .cancelled {
                errorMessage = describe(error)
            }
        } catch let error as FocusControllerError {
            presentNotice(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startWithoutTag() {
        guard let modeID = modeStore.selectedModeID else {
            showNoModeAlert = true
            return
        }
        do {
            _ = try focusController.startManual(modeID: modeID)
        } catch let error as FocusControllerError {
            presentNotice(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func endFocus() {
        do {
            try focusController.stopManual()
        } catch FocusControllerError.manualStopBlocked {
            // Strict Mode: explain it must be ended with a tag.
            showStrictAlert = true
        } catch let error as FocusControllerError {
            presentNotice(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Error presentation

    private func presentNotice(for error: FocusControllerError) {
        switch error {
        case .lockedModeNeedsAuthorizedTag:
            noticeTitle = MiniCopy.homeLockedNoTagTitle
            noticeMessage = MiniCopy.homeLockedNoTagBody
        case .securityModeNeedsApps:
            noticeTitle = MiniCopy.homeSecurityNoAppsTitle
            noticeMessage = MiniCopy.homeSecurityNoAppsBody
        case .notAuthorized:
            noticeTitle = MiniCopy.homeNotAuthorizedTitle
            noticeMessage = MiniCopy.homeNotAuthorizedBody
            refreshAuthorization()
        case .activationFailed, .deactivationFailed, .modeNotFound, .manualStopBlocked:
            noticeTitle = MiniCopy.homeActivationFailedTitle
            noticeMessage = MiniCopy.homeActivationFailedBody
        }
    }

    private func describe(_ reason: FocusDenialReason) -> String {
        switch reason {
        case .lockedDifferentModeTag: return MiniCopy.homeLockedOtherModeTag
        case .manualStopBlocked: return MiniCopy.homeStrictAlertBody
        }
    }

    private func describe(_ error: NFCServiceError) -> String {
        switch error {
        case .unavailable: return MiniCopy.nfcUnavailable
        case .noTag: return MiniCopy.nfcNoTag
        case let .readFailed(message): return message
        case let .writeFailed(message): return message
        case .cancelled: return ""
        }
    }

    // MARK: - Elapsed formatting

    static func elapsedString(from start: Date, to now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// Allow using ScannedTag with `.sheet(item:)`.
extension ScannedTag: Identifiable {
    public var id: String { hardwareIdentifier }
}
