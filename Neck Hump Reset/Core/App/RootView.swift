//
//  RootView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct RootView: View {
    @State private var hasCompletedOnboarding: Bool = {
        // If alwaysShowOnboarding is true, ignore saved state
        if AppConfig.alwaysShowOnboarding {
            return false
        }
        return UserProfile.load().hasCompletedOnboarding
    }()
    @State private var showSplash: Bool = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView(isOnboardingComplete: $hasCompletedOnboarding)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.splashDuration) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            // Subtle background glow
            RadialGradient(
                colors: [
                    AppTheme.Colors.accentCyan.opacity(0.2),
                    AppTheme.Colors.deepNavy.opacity(0)
                ],
                center: .center,
                startRadius: 80,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Image("Image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .shadow(color: AppTheme.Colors.accentCyan.opacity(0.6), radius: 30, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    RootView()
}
