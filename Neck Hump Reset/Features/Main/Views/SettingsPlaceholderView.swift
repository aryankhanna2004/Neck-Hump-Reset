//
//  SettingsPlaceholderView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct SettingsPlaceholderView: View {
    @State private var showResetAlert = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    Text("Settings")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.softWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, AppTheme.Spacing.lg)
                    
                    // Coming soon section
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.4))
                        
                        Text("More settings coming soon")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    .padding(.vertical, AppTheme.Spacing.xxl)
                    
                    Spacer().frame(height: AppTheme.Spacing.xl)
                    
                    // Debug section - only visible in test mode
                    if AppConfig.testMode {
                        developerOptionsSection
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, 100)
            }
        }
        .alert("Reset Onboarding?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("This will clear your preferences. The app will restart to show onboarding.")
        }
    }
    
    // MARK: - Developer Options
    private var developerOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header with badge
            HStack {
                Text("Developer Options")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                
                Text("TEST MODE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.Colors.deepNavy)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
            }
            
            // Reset onboarding button
            Button(action: { showResetAlert = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18))
                    Text("Reset Onboarding")
                        .font(AppTheme.Typography.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                .foregroundColor(AppTheme.Colors.softWhite)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                )
            }
            
            Text("Clears preferences and restarts to show onboarding.")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
            
            // Config info
            VStack(alignment: .leading, spacing: 4) {
                configRow(label: "testMode", value: "\(AppConfig.testMode)")
                configRow(label: "alwaysShowOnboarding", value: "\(AppConfig.alwaysShowOnboarding)")
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.top, AppTheme.Spacing.sm)
        }
    }
    
    private func configRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.Colors.mutedGray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(value == "true" ? Color.green : AppTheme.Colors.softWhite)
        }
    }
    
    private func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "user_profile")
        exit(0)
    }
}

#Preview {
    SettingsPlaceholderView()
}
