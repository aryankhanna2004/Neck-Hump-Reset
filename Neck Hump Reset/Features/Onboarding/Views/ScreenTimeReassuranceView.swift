//
//  ScreenTimeReassuranceView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct ScreenTimeReassuranceView: View {
    let onContinue: () -> Void
    
    @State private var contentAppeared = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            // Subtle background glow
            RadialGradient(
                colors: [
                    AppTheme.Colors.accentCyan.opacity(0.15),
                    AppTheme.Colors.deepNavy.opacity(0)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accentCyan.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Colors.accentCyan)
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .scaleEffect(contentAppeared ? 1 : 0.8)
                    
                    // Text
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("You're not alone")
                            .font(AppTheme.Typography.title)
                            .foregroundColor(AppTheme.Colors.softWhite)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 10)
                        
                        Text("Most people here are in the same boat.\nWe'll build short breaks that actually fit your day.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 10)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                }
                
                Spacer()
                
                // Continue button
                PrimaryButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                contentAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showButton = true
            }
        }
    }
}

#Preview {
    ScreenTimeReassuranceView(onContinue: {})
}
