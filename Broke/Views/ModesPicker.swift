//
//  ModesPicker.swift
//  Broke
//
//  Grid of Modes (formerly Profiles). Tap to select, long-press to edit.
//

import SwiftUI

struct ModesPicker: View {
    @Environment(ModeStore.self) private var modeStore

    @State private var showAddMode = false
    @State private var editingMode: Mode?

    var body: some View {
        VStack {
            Text("Modes")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                    ForEach(modeStore.modes) { mode in
                        ModeCell(mode: mode, isSelected: mode.id == modeStore.selectedModeID)
                            .onTapGesture {
                                modeStore.select(mode.id)
                            }
                            .onLongPressGesture {
                                editingMode = mode
                            }
                    }

                    ModeCellBase(name: "New...", icon: "plus", appsBlocked: nil, categoriesBlocked: nil, isSelected: false, isDashed: true, hasDivider: false)
                        .onTapGesture {
                            showAddMode = true
                        }
                }
                .padding(.horizontal, 10)
            }

            Spacer()

            Text("Long press on a Mode to edit...")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.bottom, 8)
        }
        .background(Color("ProfileSectionBackground"))
        .sheet(item: $editingMode) { mode in
            ModeFormView(mode: mode)
        }
        .sheet(isPresented: $showAddMode) {
            ModeFormView()
        }
    }
}

struct ModeCellBase: View {
    let name: String
    let icon: String
    let appsBlocked: Int?
    let categoriesBlocked: Int?
    let isSelected: Bool
    var isDashed: Bool = false
    var hasDivider: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            if hasDivider {
                Divider().padding(2)
            }
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            if let apps = appsBlocked, let categories = categoriesBlocked {
                Text("A: \(apps) | C: \(categories)")
                    .font(.system(size: 10))
            }
        }
        .frame(width: 90, height: 90)
        .padding(2)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.blue : (isDashed ? Color.secondary : Color.clear),
                    style: StrokeStyle(lineWidth: 2, dash: isDashed ? [5] : [])
                )
        )
    }
}

struct ModeCell: View {
    let mode: Mode
    let isSelected: Bool

    var body: some View {
        ModeCellBase(
            name: mode.name,
            icon: mode.icon,
            appsBlocked: mode.selectedApplications.count,
            categoriesBlocked: mode.selectedCategories.count,
            isSelected: isSelected
        )
    }
}
