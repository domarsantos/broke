//
//  ModesView.swift
//  MiniFocus
//
//  Mini Focus "Modos" screen. A roomy grid of focus Modes. Tap to select,
//  long-press to edit, and a dedicated cell to add a new one. Selection and
//  editing use the same ModeStore / ModeFormView as before.
//
//  Replaces the former ModesPicker (which lived in the lower half of the home
//  screen).
//

import SwiftUI

struct ModesView: View {
    @Environment(ModeStore.self) private var modeStore

    @State private var showAddMode = false
    @State private var editingMode: Mode?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: MiniSpacing.md)]

    var body: some View {
        NavigationStack {
            MiniScreen {
                if modeStore.modes.isEmpty {
                    MiniEmptyState(
                        systemImage: "square.stack.3d.up",
                        title: MiniCopy.modesEmptyTitle,
                        message: MiniCopy.modesEmptyBody,
                        actionTitle: MiniCopy.modesNew,
                        action: { showAddMode = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: MiniSpacing.lg) {
                            LazyVGrid(columns: columns, spacing: MiniSpacing.md) {
                                ForEach(modeStore.modes) { mode in
                                    ModeCard(mode: mode, isSelected: mode.id == modeStore.selectedModeID)
                                        .onTapGesture { modeStore.select(mode.id) }
                                        .onLongPressGesture { editingMode = mode }
                                }

                                AddModeCard { showAddMode = true }
                            }

                            Text(MiniCopy.modesHint)
                                .font(MiniFont.caption)
                                .foregroundStyle(MiniColor.muted)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, MiniSpacing.horizontal)
                        .padding(.vertical, MiniSpacing.lg)
                    }
                }
            }
            .navigationTitle(MiniCopy.modesTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddMode = true
                    } label: {
                        Label(MiniCopy.modesNew, systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingMode) { mode in
                ModeFormView(mode: mode)
            }
            .sheet(isPresented: $showAddMode) {
                ModeFormView()
            }
        }
    }
}

// MARK: - Mode card

struct ModeCard: View {
    let mode: Mode
    let isSelected: Bool

    private var countsText: String {
        let apps = mode.selectedApplications.count
        let categories = mode.selectedCategories.count
        return "\(apps) apps · \(categories) categorias"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MiniSpacing.sm) {
            HStack {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(MiniColor.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MiniColor.primary)
                        .accessibilityLabel("Selecionado")
                }
            }

            Text(mode.name)
                .font(MiniFont.bodyEmphasized)
                .foregroundStyle(MiniColor.text)
                .lineLimit(1)

            Text(countsText)
                .font(MiniFont.caption)
                .foregroundStyle(MiniColor.muted)
                .lineLimit(1)
        }
        .padding(MiniSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(
            isSelected ? MiniColor.sage : MiniColor.surface,
            in: RoundedRectangle(cornerRadius: MiniRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MiniRadius.card, style: .continuous)
                .stroke(isSelected ? MiniColor.primary : MiniColor.line, lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Add card

struct AddModeCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MiniSpacing.xs) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(MiniColor.primary)
                Text(MiniCopy.modesNew)
                    .font(MiniFont.caption)
                    .foregroundStyle(MiniColor.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 116)
            .background(MiniColor.background, in: RoundedRectangle(cornerRadius: MiniRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MiniRadius.card, style: .continuous)
                    .stroke(MiniColor.muted, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }
}
