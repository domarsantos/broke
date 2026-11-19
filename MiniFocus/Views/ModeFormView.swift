//
//  ModeFormView.swift
//  MiniFocus
//
//  Create / edit a Mode, including its FamilyActivitySelection. Behavior is
//  unchanged; only the presentation and copy follow the Mini Focus design
//  system. The native FamilyActivityPicker is kept intact.
//

import SwiftUI
import SFSymbolsPicker
import FamilyControls

struct ModeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @Environment(ModeStore.self) private var modeStore
    @Environment(FocusController.self) private var focusController

    @State private var name: String
    @State private var icon: String
    @State private var showSymbolsPicker = false
    @State private var showAppSelection = false
    @State private var selection: FamilyActivitySelection
    @State private var showDeleteConfirmation = false
    @State private var showActiveDeleteAlert = false

    private let mode: Mode?

    init(mode: Mode? = nil) {
        self.mode = mode
        _name = State(initialValue: mode?.name ?? "")
        _icon = State(initialValue: mode?.icon ?? "bell.slash")
        _selection = State(initialValue: mode?.selection ?? FamilyActivitySelection())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(MiniCopy.modeDetailsSection)) {
                    VStack(alignment: .leading, spacing: MiniSpacing.unit) {
                        Text(MiniCopy.modeNameLabel)
                            .font(MiniFont.caption)
                            .foregroundStyle(MiniColor.muted)
                        TextField(MiniCopy.modeNamePlaceholder, text: $name)
                    }

                    Button(action: { showSymbolsPicker = true }) {
                        HStack(spacing: MiniSpacing.md) {
                            Image(systemName: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(MiniColor.primary)
                            Text(MiniCopy.modeChooseIcon)
                                .foregroundStyle(MiniColor.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(MiniColor.muted)
                        }
                    }
                }

                Section(header: Text(MiniCopy.modeAppsSection)) {
                    Button(action: { showAppSelection = true }) {
                        Text(MiniCopy.modeConfigureApps)
                    }

                    VStack(alignment: .leading, spacing: MiniSpacing.xs) {
                        row(MiniCopy.modeAppsBlocked, selection.applicationTokens.count)
                        row(MiniCopy.modeCategoriesBlocked, selection.categoryTokens.count)
                        row(MiniCopy.modeWebsitesBlocked, selection.webDomainTokens.count)
                        Text(MiniCopy.modePrivacyNote)
                            .font(MiniFont.caption)
                            .foregroundStyle(MiniColor.muted)
                    }
                }

                if mode != nil {
                    Section {
                        Button(role: .destructive, action: attemptDelete) {
                            Text(MiniCopy.modeDelete)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MiniColor.background)
            .navigationTitle(mode == nil ? MiniCopy.modeAddTitle : MiniCopy.modeEditTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(MiniCopy.actionCancel) { dismiss() },
                trailing: Button(MiniCopy.actionSave, action: handleSave).disabled(name.isEmpty)
            )
            .sheet(isPresented: $showSymbolsPicker) {
                SymbolsPicker(selection: $icon, title: MiniCopy.modeIconPickerTitle, autoDismiss: true)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationStack {
                    FamilyActivityPicker(selection: $selection)
                        .navigationTitle(MiniCopy.modeSelectAppsTitle)
                        .navigationBarItems(trailing: Button(MiniCopy.actionDone) {
                            showAppSelection = false
                        })
                }
            }
            .alert(MiniCopy.modeDeleteTitle, isPresented: $showDeleteConfirmation) {
                Button(MiniCopy.actionDelete, role: .destructive, action: performDelete)
                Button(MiniCopy.actionCancel, role: .cancel) {}
            } message: {
                Text(MiniCopy.modeDeleteBody)
            }
            .alert(MiniCopy.modeActiveDeleteTitle, isPresented: $showActiveDeleteAlert) {
                Button(MiniCopy.actionOK, role: .cancel) {}
            } message: {
                Text(MiniCopy.modeActiveDeleteBody)
            }
        }
    }

    private func row(_ label: String, _ count: Int) -> some View {
        HStack {
            Text(label)
                .font(MiniFont.body)
                .foregroundStyle(MiniColor.text)
            Spacer()
            Text("\(count)")
                .font(MiniFont.bodyEmphasized)
                .foregroundStyle(MiniColor.primary)
        }
    }

    private func handleSave() {
        if let mode {
            modeStore.update(id: mode.id, name: name, icon: icon, selection: selection)
            env.modeWasEdited(mode.id)
        } else {
            modeStore.add(name: name, icon: icon, selection: selection)
        }
        dismiss()
    }

    private func attemptDelete() {
        guard let mode else { return }
        if focusController.activeMode?.id == mode.id {
            showActiveDeleteAlert = true
        } else {
            showDeleteConfirmation = true
        }
    }

    private func performDelete() {
        guard let mode else { return }
        _ = env.deleteMode(mode.id)
        dismiss()
    }
}
