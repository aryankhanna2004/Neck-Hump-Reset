//
//  MainTabView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            TodayView(viewModel: viewModel)
                .tabItem {
                    Label(MainTab.today.title, systemImage: MainTab.today.icon)
                }
                .tag(MainTab.today)
            
            ProgressPlaceholderView()
                .tabItem {
                    Label(MainTab.progress.title, systemImage: MainTab.progress.icon)
                }
                .tag(MainTab.progress)
            
            SettingsPlaceholderView()
                .tabItem {
                    Label(MainTab.settings.title, systemImage: MainTab.settings.icon)
                }
                .tag(MainTab.settings)
        }
        .tint(AppTheme.Colors.accentCyan)
    }
}

#Preview {
    MainTabView()
}
