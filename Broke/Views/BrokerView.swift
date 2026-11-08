//
//  BrokerView.swift
//  Broke
//
//  Home screen. Delegates ALL activation logic to FocusController / NFCService;
//  it contains no NFC or Screen Time business rules.
//

import SwiftUI
import CoreNFC

struct BrokerView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(ModeStore.self) private var modeStore
    @Environment(FocusController.self) private var focusController

    @State private var showTags = false
    @State private var pairingScan: ScannedTag?
    @State private var showNoModeAlert = false
    @State private var errorMessage: String?

    private var isBlocking: Bool { focusController.isActive }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        blockButton(geometry: geometry)

                        if !isBlocking {
                            Divider()
                            ModesPicker()
                                .frame(height: geometry.size.height / 2)
                                .transition(.move(edge: .bottom))
                        } else {
                            activeModeFooter
                        }
                    }
                    .background(isBlocking ? Color("BlockingBackground") : Color("NonBlockingBackground"))
                }
            }
            .navigationBarItems(trailing: tagsButton)
            .alert("No Mode selected", isPresented: $showNoModeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Create or select a Mode before starting a focus session.")
            }
            .alert("NFC Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showTags) {
                TagsView()
            }
            .sheet(item: $pairingScan) { scan in
                TagPairingView(prefilledScan: scan)
            }
        }
        .animation(.spring(), value: isBlocking)
    }

    @ViewBuilder
    private func blockButton(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            Text(isBlocking ? "Tap to scan & unblock" : "Tap to scan & block")
                .font(.caption)
                .opacity(0.75)
                .transition(.scale)

            Button(action: { Task { await scanTag() } }) {
                Image(isBlocking ? "RedIcon" : "GreenIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: geometry.size.height / 3)
            }
            .transition(.scale)

            if !isBlocking {
                Button(action: startWithoutTag) {
                    Label("Start without tag", systemImage: "play.circle")
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: isBlocking ? geometry.size.height : geometry.size.height / 2)
        .animation(.spring(), value: isBlocking)
    }

    @ViewBuilder
    private var activeModeFooter: some View {
        if let mode = focusController.activeMode, let session = focusController.activeSession {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.title2)
                Text("\(mode.name) active")
                    .font(.headline)
                Text("Since \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Scan the tag again to finish.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding()
        }
    }

    private var tagsButton: some View {
        Button(action: { showTags = true }) {
            Image(systemName: "tag")
        }
    }

    // MARK: - Actions

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
        case .unavailable: return "NFC is not available on this device."
        case .noTag: return "No tag detected."
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
