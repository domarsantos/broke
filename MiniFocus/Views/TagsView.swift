//
//  TagsView.swift
//  MiniFocus
//
//  Mini Focus "Mini Tag" screen. Lists connected tags and their linked Mode.
//  Pairing and detail still open as sheets with the same fields and actions.
//

import SwiftUI

struct TagsView: View {
    @Environment(ModeStore.self) private var modeStore
    @Environment(TagStore.self) private var tagStore
    @Environment(FocusController.self) private var focusController

    @State private var showAddTag = false
    @State private var selectedTag: FocusTag?

    /// While a locked (Strict/Security) session runs, connecting new tags is
    /// frozen so the lock cannot be worked around.
    private var isLocked: Bool { focusController.isLockedActive }

    var body: some View {
        NavigationStack {
            Group {
                if tagStore.tags.isEmpty {
                    MiniScreen {
                        MiniEmptyState(
                            systemImage: "wave.3.right",
                            title: MiniCopy.tagsEmptyTitle,
                            message: MiniCopy.tagsEmptyBody,
                            actionTitle: MiniCopy.tagsAdd,
                            action: { showAddTag = true }
                        )
                    }
                } else {
                    List {
                        if isLocked {
                            Section {
                                Label(MiniCopy.tagLockedNotice, systemImage: "lock.fill")
                                    .font(MiniFont.caption)
                                    .foregroundStyle(MiniColor.warm)
                            }
                            .listRowBackground(MiniColor.surface)
                        }
                        ForEach(tagStore.tags) { tag in
                            Button {
                                selectedTag = tag
                            } label: {
                                row(for: tag)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(MiniColor.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(MiniColor.background)
                }
            }
            .navigationTitle(MiniCopy.tagsTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTag = true
                    } label: {
                        Label(MiniCopy.tagsAdd, systemImage: "plus")
                    }
                    .disabled(isLocked)
                }
            }
            .sheet(isPresented: $showAddTag) {
                TagPairingView(prefilledScan: nil)
            }
            .sheet(item: $selectedTag) { tag in
                TagDetailView(tag: tag)
            }
        }
    }

    private func row(for tag: FocusTag) -> some View {
        HStack(spacing: MiniSpacing.md) {
            Image(systemName: "wave.3.right")
                .font(.title3)
                .foregroundStyle(MiniColor.primary)
                .frame(width: 40, height: 40)
                .background(MiniColor.sage, in: Circle())

            VStack(alignment: .leading, spacing: MiniSpacing.unit) {
                Text(tag.name)
                    .font(MiniFont.bodyEmphasized)
                    .foregroundStyle(MiniColor.text)
                Text(linkedModeDescription(for: tag))
                    .font(MiniFont.caption)
                    .foregroundStyle(tag.linkedModeID == nil ? MiniColor.muted : MiniColor.primary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(MiniColor.muted)
        }
        .padding(.vertical, MiniSpacing.unit)
    }

    private func linkedModeDescription(for tag: FocusTag) -> String {
        guard let modeID = tag.linkedModeID, let mode = modeStore.mode(id: modeID) else {
            return MiniCopy.tagNoMode
        }
        return MiniCopy.tagLinkedMode(mode.name)
    }
}

/// Reusable picker to choose a Mode (or none). Shared by pairing and detail.
struct ModePickerField: View {
    @Environment(ModeStore.self) private var modeStore
    @Binding var selectedModeID: UUID?

    var body: some View {
        Picker(MiniCopy.tagModeSection, selection: $selectedModeID) {
            Text(MiniCopy.modePickerNone).tag(UUID?.none)
            ForEach(modeStore.modes) { mode in
                Text(mode.name).tag(UUID?.some(mode.id))
            }
        }
    }
}
