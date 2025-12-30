//
//  TodayView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var contentAppeared = false
    @State private var showPostureCheck = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : -20)
                    
                    routineCard
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                    
                    // Posture Check Card (if camera enabled)
                    if viewModel.usesCamera {
                        postureCheckCard
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                    }
                    
                    statsSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                    
                    quickActionsSection
                        .opacity(contentAppeared ? 1 : 0)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                contentAppeared = true
            }
        }
        .fullScreenCover(isPresented: $showPostureCheck) {
            PostureCheckView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(viewModel.greetingText)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Text("Ready to reset?")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(AppTheme.Colors.softWhite)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.Spacing.md)
    }
    
    private var routineCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Routine")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    Text("\(viewModel.timeCommitmentDisplay) • \(viewModel.situationLabel)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                
                Spacer()
                
                Circle()
                    .fill(AppTheme.Colors.buttonGradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.Colors.deepNavy)
                            .offset(x: 2)
                    )
                    .shadow(color: AppTheme.Colors.accentCyan.opacity(0.4), radius: 12, x: 0, y: 4)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("0 of 5 exercises")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    
                    Spacer()
                    
                    Text("Not started")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.accentCyan)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(AppTheme.Colors.buttonGradient)
                            .frame(width: 0, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.Colors.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Posture Check Card
    private var postureCheckCard: some View {
        Button(action: { showPostureCheck = true }) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.glowBlue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "figure.stand")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.accentCyan)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Posture Check")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    Text("Analyze your posture with AI")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accentCyan)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statsSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StatCard(icon: "flame.fill", value: "0", label: "Day streak", color: .orange)
            StatCard(icon: "clock.fill", value: "0m", label: "Total time", color: AppTheme.Colors.accentCyan)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Quick Actions")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            HStack(spacing: AppTheme.Spacing.md) {
                QuickActionCard(
                    icon: "timer",
                    title: "3-min Break",
                    action: {}
                )
                QuickActionCard(
                    icon: "figure.walk",
                    title: "Stretch",
                    action: {}
                )
            }
        }
        .padding(.top, AppTheme.Spacing.md)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(label)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                
                Text(title)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.softWhite)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TodayView(viewModel: MainViewModel())
}
