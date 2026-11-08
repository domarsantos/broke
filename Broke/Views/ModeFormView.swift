//
//  ModeFormView.swift
//  Broke
//
//  Create / edit a Mode, including its FamilyActivitySelection.
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
        NavigationView {
            Form {
                Section(header: Text("Mode Details")) {
                    VStack(alignment: .leading) {
                        Text("Mode Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter mode name", text: $name)
                    }

                    Button(action: { showSymbolsPicker = true }) {
                        HStack {
                            Image(systemName: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            Text("Choose Icon")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("App Configuration")) {
                    Button(action: { showAppSelection = true }) {
                        Text("Configure Blocked Apps")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        row("Blocked Apps:", selection.applicationTokens.count)
                        row("Blocked Categories:", selection.categoryTokens.count)
                        row("Blocked Websites:", selection.webDomainTokens.count)
                        Text("Broke can't list the names of the apps due to privacy concerns, it is only able to see the amount of apps selected in the configuration screen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if mode != nil {
                    Section {
                        Button(role: .destructive, action: attemptDelete) {
                            Text("Delete Mode")
                        }
                    }
                }
            }
            .navigationTitle(mode == nil ? "Add Mode" : "Edit Mode")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save", action: handleSave).disabled(name.isEmpty)
            )
            .sheet(isPresented: $showSymbolsPicker) {
                SymbolsPicker(selection: $icon, title: "Pick an icon", autoDismiss: true)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationView {
                    FamilyActivityPicker(selection: $selection)
                        .navigationTitle("Select Apps")
                        .navigationBarItems(trailing: Button("Done") {
                            showAppSelection = false
                        })
                }
            }
            .alert("Delete Mode", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive, action: performDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this mode? Tags linked to it will be unlinked.")
            }
            .alert("Mode is active", isPresented: $showActiveDeleteAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Finish the active focus session before deleting this mode.")
            }
        }
    }

    private func row(_ label: String, _ count: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)").fontWeight(.bold)
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
