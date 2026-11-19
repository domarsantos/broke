//
//  TodayView.swift
//  MiniFocus
//
//  Mini Focus "Hoje" screen. Shows the current focus state and the single CTA
//  to read the Mini Tag. All activation logic still lives in FocusController /
//  NFCService; this view contains no NFC or Screen Time business rules.
//
//  Replaces the former BrokerView; the behavior (scan, start without tag,
//  alerts) is preserved.
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
    @State private var errorMessage: String?
    @State private var isAuthorized = true

    private var isBlocking: Bool { focusController.isActive }
    private var hasModes: Bool { !modeStore.modes.isEmpty }

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
            .alert(MiniCopy.nfcErrorTitle, isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(MiniCopy.actionOK, role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
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

            if isBlocking, let mode = focusController.activeMode, let session = focusController.activeSession {
                activeModeCard(mode: mode, session: session)
                    .padding(.top, MiniSpacing.xs)
            }
        }
    }

    private func activeModeCard(mode: Mode, session: FocusSession) -> some View {
        MiniCard(fill: MiniColor.sage) {
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
                    Text(MiniCopy.homeActiveSince(session.startedAt.formatted(date: .omitted, time: .shortened)))
                        .font(MiniFont.caption)
                        .foregroundStyle(MiniColor.muted)
                }
                Spacer(minLength: 0)
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

    private var actions: some View {
        VStack(spacing: MiniSpacing.sm) {
            Button(action: { Task { await scanTag() } }) {
                Text(isBlocking ? MiniCopy.homeOnCTA : MiniCopy.homeOffCTA)
            }
            .buttonStyle(.miniPrimary)

            if !isBlocking {
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

    // MARK: - Actions (behavior preserved from BrokerView)

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
                pairingScan = scanned
            case .noModeToActivate:
                showNoModeAlert = true
            case .activated, .deactivated, .switched:
                break // state updates drive the UI
            }
        } catch let error as NFCServiceError {
            if error != .cancelled {
                errorMessage = describe(error)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startWithoutTag() {
        guard let modeID = modeStore.selectedModeID else {
            showNoModeAlert = true
            return
        }
        _ = try? focusController.startManual(modeID: modeID)
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
}

// Allow using ScannedTag with `.sheet(item:)`.
extension ScannedTag: Identifiable {
    public var id: String { hardwareIdentifier }
}
