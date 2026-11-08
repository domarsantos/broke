//
//  TagDetailView.swift
//  Broke
//
//  Edit a registered tag: rename, (re)assign Mode, write marker, delete.
//

import SwiftUI

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @Environment(ModeStore.self) private var modeStore
    @Environment(TagStore.self) private var tagStore

    let tag: FocusTag

    @State private var name: String
    @State private var selectedModeID: UUID?
    @State private var showDeleteConfirmation = false
    @State private var statusMessage: String?

    init(tag: FocusTag) {
        self.tag = tag
        _name = State(initialValue: tag.name)
        _selectedModeID = State(initialValue: tag.linkedModeID)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Tag name", text: $name)
                }

                Section(header: Text("Mode")) {
                    ModePickerField(selectedModeID: $selectedModeID)
                }

                Section(header: Text("Tag Info")) {
                    LabeledContent("Identifier", value: tag.hardwareIdentifier ?? "Unknown")
                    LabeledContent("Registered", value: tag.createdAt.formatted(date: .abbreviated, time: .shortened))
                }

                Section {
                    Button(action: { Task { await writeMarker() } }) {
                        Label("Write Broke marker to tag", systemImage: "square.and.pencil")
                    }
                    .disabled(!env.nfcService.isAvailable)
                    if let statusMessage {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Tag")
                    }
                }
            }
            .navigationTitle(tag.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: save).disabled(name.isEmpty)
                }
            }
            .alert("Delete Tag", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    tagStore.delete(id: tag.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Remove this tag registration? The physical tag can be registered again later.")
            }
        }
    }

    private func save() {
        if name != tag.name {
            tagStore.rename(tag, to: name)
        }
        if selectedModeID != tag.linkedModeID {
            tagStore.setLinkedMode(tag, modeID: selectedModeID)
        }
        dismiss()
    }

    private func writeMarker() async {
        do {
            _ = try await env.nfcService.write(text: "BROKE-IS-GREAT")
            statusMessage = "Marker written successfully."
        } catch let error as NFCServiceError where error == .cancelled {
            // no-op
        } catch {
            statusMessage = "Write failed: \(error.localizedDescription)"
        }
    }
}
