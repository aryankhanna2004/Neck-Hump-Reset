//
//  DisclaimerView.swift
//  Neck Hump Reset
//
//  Wellness disclaimer shown during onboarding.
//

import SwiftUI

struct DisclaimerView: View {
    let onContinue: () -> Void
    
    @State private var contentOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                    .padding(.bottom, AppTheme.Spacing.lg)
                
                // Title
                Text("Before We Begin")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppTheme.Spacing.md)
                
                // Disclaimer points
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    disclaimerRow(
                        icon: "figure.run",
                        text: "This app is a fitness and wellness tool"
                    )
                    
                    disclaimerRow(
                        icon: "graduationcap.fill",
                        text: "All posture feedback and exercises are for general educational purposes only."
                    )
                    
                    disclaimerRow(
                        icon: "person.fill.checkmark",
                        text: "Always consult a qualified healthcare professional before starting any new exercise program or making health decisions."
                    )
                    
                    disclaimerRow(
                        icon: "xmark.shield",
                        text: "This app does not diagnose, treat, cure, or prevent any medical condition."
                    )
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                .stroke(AppTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.sm)
                
                Spacer()
                
                // Continue button
                VStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton(title: "I Understand", action: onContinue)
                    
                    Text("By continuing, you acknowledge this is not medical advice")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .opacity(buttonOpacity)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxl)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                buttonOpacity = 1.0
            }
        }
    }
    
    private func disclaimerRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 24)
                .padding(.top, 2)
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    DisclaimerView(onContinue: {})
}
