//
//  WarningSheetViews.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI

// MARK: - Low Confidence Warning Sheet
struct LowConfidenceWarningSheet: View {
    let confidence: Float
    let onRetake: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            .padding(.top, AppTheme.Spacing.lg)
            
            // Title
            Text("Detection Quality Issue")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            // Description
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("We had difficulty detecting your ear and shoulder positions clearly.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                
                // Confidence indicator
                HStack(spacing: 8) {
                    Text("Detection confidence:")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(confidence < 0.5 ? .red : .orange)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            // Tips
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("For better results:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                tipRow(icon: "lightbulb.fill", text: "Ensure good lighting")
                tipRow(icon: "person.fill.turn.right", text: "Stand completely sideways")
                tipRow(icon: "eye.fill", text: "Make sure ear is visible")
                tipRow(icon: "camera.fill", text: "Position camera at shoulder height")
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
            )
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            Spacer()
            
            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Retake Photo")
                    }
                    .font(AppTheme.Typography.button)
                    .foregroundColor(AppTheme.Colors.deepNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.Colors.accentCyan)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                Button(action: onContinue) {
                    Text("Continue Anyway")
                        .font(AppTheme.Typography.button)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.Colors.primaryBlue.opacity(0.3))
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.deepNavy.ignoresSafeArea())
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.softWhite)
        }
    }
}
