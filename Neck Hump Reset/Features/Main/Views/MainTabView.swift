//
//  MainTabView.swift
//  Neck Hump Reset
//
//  Main tab navigation with 3 core features
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // Home / Posture Check
            NavigationStack {
                TodayView(viewModel: viewModel)
            }
            .tabItem {
                Label(MainTab.home.title, systemImage: MainTab.home.icon)
            }
            .tag(MainTab.home)
            
            // Exercises
            NavigationStack {
                ExercisesView()
            }
            .tabItem {
                Label(MainTab.exercises.title, systemImage: MainTab.exercises.icon)
            }
            .tag(MainTab.exercises)
            
            // Progress
            NavigationStack {
                ProgressPlaceholderView()
            }
            .tabItem {
                Label(MainTab.progress.title, systemImage: MainTab.progress.icon)
            }
            .tag(MainTab.progress)
        }
        .tint(AppTheme.Colors.accentCyan)
    }
}

#Preview {
    MainTabView()
}
