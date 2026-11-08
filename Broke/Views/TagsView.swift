//
//  TagsView.swift
//  Broke
//
//  Lists registered tags and their linked Mode.
//

import SwiftUI

struct TagsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ModeStore.self) private var modeStore
    @Environment(TagStore.self) private var tagStore

    @State private var showAddTag = false
    @State private var selectedTag: FocusTag?

    var body: some View {
        NavigationView {
            List {
                if tagStore.tags.isEmpty {
                    Text("No tags registered yet.")
                        .foregroundColor(.secondary)
                }

                ForEach(tagStore.tags) { tag in
                    Button {
                        selectedTag = tag
                    } label: {
                        row(for: tag)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTag = true
                    } label: {
                        Label("Add Tag", systemImage: "plus")
                    }
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.accentColor)
                Text(tag.name)
                    .font(.headline)
            }
            Text(linkedModeDescription(for: tag))
                .font(.subheadline)
                .foregroundColor(tag.linkedModeID == nil ? .secondary : .primary)
        }
        .padding(.vertical, 4)
    }

    private func linkedModeDescription(for tag: FocusTag) -> String {
        guard let modeID = tag.linkedModeID, let mode = modeStore.mode(id: modeID) else {
            return "No mode assigned"
        }
        return "\u{2192} \(mode.name)"
    }
}
