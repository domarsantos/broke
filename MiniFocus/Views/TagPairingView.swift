//
//  TagPairingView.swift
//  MiniFocus
//
//  Connect Mini Tag flow: Scan -> Identify -> Name -> optional Mode -> Register.
//  Behavior is unchanged; only the presentation and copy follow the Mini Focus
//  design system.
//

import SwiftUI

struct TagPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @Environment(ModeStore.self) private var modeStore
    @Environment(TagStore.self) private var tagStore

    /// When presented from a home-screen scan, we already have the tag UID.
    let prefilledScan: ScannedTag?

    @State private var scan: ScannedTag?
    @State private var name: String = ""
    @State private var selectedModeID: UUID?
    @State private var isScanning = false
    @State private var alreadyRegisteredName: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(MiniCopy.pairingTagSection)) {
                    if let scan {
                        LabeledContent(MiniCopy.tagIdentifier, value: scan.hardwareIdentifier)
                        if let alreadyRegisteredName {
                            Label(MiniCopy.pairingAlready(alreadyRegisteredName), systemImage: "exclamationmark.triangle")
                                .foregroundStyle(MiniColor.warm)
                        }
                    } else {
                        Button(action: { Task { await scanTag() } }) {
                            Label(isScanning ? MiniCopy.pairingScanning : MiniCopy.pairingScan, systemImage: "wave.3.right")
                        }
                        .disabled(isScanning || !env.nfcService.isAvailable)
                    }
                }

                if scan != nil, alreadyRegisteredName == nil {
                    Section(header: Text(MiniCopy.pairingNameSection)) {
                        TextField(MiniCopy.pairingNamePlaceholder, text: $name)
                    }

                    Section(header: Text(MiniCopy.pairingModeSection)) {
                        ModePickerField(selectedModeID: $selectedModeID)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MiniColor.background)
            .navigationTitle(MiniCopy.pairingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(MiniCopy.actionCancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MiniCopy.actionSave, action: save)
                        .disabled(scan == nil || name.isEmpty || alreadyRegisteredName != nil)
                }
            }
            .alert(MiniCopy.nfcErrorTitle, isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(MiniCopy.actionOK, role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if let prefilledScan {
                    apply(prefilledScan)
                }
            }
        }
    }

    private func scanTag() async {
        isScanning = true
        defer { isScanning = false }
        do {
            let scanned = try await env.nfcService.scan()
            apply(scanned)
        } catch let error as NFCServiceError where error == .cancelled {
            // user cancelled; no-op
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ scanned: ScannedTag) {
        scan = scanned
        if let existing = tagStore.tag(forHardwareIdentifier: scanned.hardwareIdentifier) {
            alreadyRegisteredName = existing.name
        } else {
            alreadyRegisteredName = nil
        }
    }

    private func save() {
        guard let scan else { return }
        do {
            try tagStore.register(
                hardwareIdentifier: scan.hardwareIdentifier,
                name: name,
                linkedModeID: selectedModeID
            )
            dismiss()
        } catch {
            errorMessage = MiniCopy.pairingRegisterError(error.localizedDescription)
        }
    }
}
