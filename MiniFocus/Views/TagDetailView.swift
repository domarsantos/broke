//
//  TagDetailView.swift
//  MiniFocus
//
//  Edit a connected Mini Tag: rename, (re)assign Mode, write marker, delete.
//  Behavior is unchanged; only the presentation and copy follow the Mini Focus
//  design system. The written NDEF payload stays "BROKE-IS-GREAT" so tags
//  already programmed keep working.
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
        NavigationStack {
            Form {
                Section(header: Text(MiniCopy.tagNameSection)) {
                    TextField(MiniCopy.tagNamePlaceholder, text: $name)
                }

                Section(header: Text(MiniCopy.tagModeSection)) {
                    ModePickerField(selectedModeID: $selectedModeID)
                }

                Section(header: Text(MiniCopy.tagInfoSection)) {
                    LabeledContent(MiniCopy.tagIdentifier, value: tag.hardwareIdentifier ?? MiniCopy.tagIdentifierUnknown)
                    LabeledContent(MiniCopy.tagRegistered, value: tag.createdAt.formatted(date: .abbreviated, time: .shortened))
                }

                Section {
                    Button(action: { Task { await writeMarker() } }) {
                        Label(MiniCopy.tagWrite, systemImage: "square.and.pencil")
                    }
                    .disabled(!env.nfcService.isAvailable)
                    if let statusMessage {
                        Text(statusMessage)
                            .font(MiniFont.caption)
                            .foregroundStyle(MiniColor.muted)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text(MiniCopy.tagDelete)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MiniColor.background)
            .navigationTitle(tag.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(MiniCopy.actionCancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MiniCopy.actionSave, action: save).disabled(name.isEmpty)
                }
            }
            .alert(MiniCopy.tagDeleteTitle, isPresented: $showDeleteConfirmation) {
                Button(MiniCopy.actionRemove, role: .destructive) {
                    tagStore.delete(id: tag.id)
                    dismiss()
                }
                Button(MiniCopy.actionCancel, role: .cancel) {}
            } message: {
                Text(MiniCopy.tagDeleteBody)
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
            // Keep the legacy payload so already-programmed tags stay compatible.
            _ = try await env.nfcService.write(text: "BROKE-IS-GREAT")
            statusMessage = MiniCopy.tagWriteSuccess
        } catch let error as NFCServiceError where error == .cancelled {
            // no-op
        } catch {
            statusMessage = MiniCopy.tagWriteError(error.localizedDescription)
        }
    }
}
