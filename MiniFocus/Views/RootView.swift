//
//  RootView.swift
//  MiniFocus
//
//  Mini Focus root navigation: a native tab bar with Hoje, Modos and Mini Tag.
//  Each tab owns its own NavigationStack. Flows and state are unchanged — this
//  only replaces the old single-screen layout with the brand's sitemap.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label(MiniCopy.navToday, systemImage: "house")
                }

            ModesView()
                .tabItem {
                    Label(MiniCopy.navModes, systemImage: "square.stack.3d.up")
                }

            TagsView()
                .tabItem {
                    Label(MiniCopy.navTag, systemImage: "wave.3.right")
                }
        }
    }
}
