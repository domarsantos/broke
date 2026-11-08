//
//  TagPairingView.swift
//  Broke
//
//  Add Tag flow: Scan -> Identify -> Name -> optional Mode -> Register.
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
        NavigationView {
            Form {
                Section(header: Text("Tag")) {
                    if let scan {
                        LabeledContent("Identifier", value: scan.hardwareIdentifier)
                        if let alreadyRegisteredName {
                            Label("Already registered as \(alreadyRegisteredName)", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    } else {
                        Button(action: { Task { await scanTag() } }) {
                            Label(isScanning ? "Scanning..." : "Scan NFC Tag", systemImage: "wave.3.right")
                        }
                        .disabled(isScanning || !env.nfcService.isAvailable)
                    }
                }

                if scan != nil, alreadyRegisteredName == nil {
                    Section(header: Text("Name")) {
                        TextField("e.g. Home, Office, Keychain", text: $name)
                    }

                    Section(header: Text("Mode (optional)")) {
                        ModePickerField(selectedModeID: $selectedModeID)
                    }
                }
            }
            .navigationTitle("Add Tag")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: save)
                        .disabled(scan == nil || name.isEmpty || alreadyRegisteredName != nil)
                }
            }
            .alert("NFC Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
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
            errorMessage = "Could not register tag: \(error.localizedDescription)"
        }
    }
}

/// Reusable picker to choose a Mode (or none).
struct ModePickerField: View {
    @Environment(ModeStore.self) private var modeStore
    @Binding var selectedModeID: UUID?

    var body: some View {
        Picker("Mode", selection: $selectedModeID) {
            Text("No mode assigned").tag(UUID?.none)
            ForEach(modeStore.modes) { mode in
                Text(mode.name).tag(UUID?.some(mode.id))
            }
        }
    }
}
