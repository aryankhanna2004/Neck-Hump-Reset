//
//  WelcomeView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var particlesVisible: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Floating particles
            if particlesVisible {
                FloatingParticles()
            }
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo / App Image
                logoSection
                
                Spacer()
                    .frame(height: AppTheme.Spacing.xl)
                
                // Title & subtitle
                textSection
                
                Spacer()
                
                // CTA Button
                buttonSection
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            AppTheme.Colors.deepNavy
                .ignoresSafeArea()
            
            // Radial glow behind logo
            RadialGradient(
                colors: [
                    AppTheme.Colors.glowBlue.opacity(0.3),
                    AppTheme.Colors.deepNavy.opacity(0)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .offset(y: -100)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image("Image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .shadow(color: AppTheme.Colors.accentCyan.opacity(0.5), radius: 30, x: 0, y: 10)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
    }
    
    // MARK: - Text Section
    private var textSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Neck Hump Reset")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(AppTheme.Colors.softWhite)
                .multilineTextAlignment(.center)
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            
            Text("Fix tech neck with daily\n5-minute routines")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(subtitleOpacity)
        }
    }
    
    // MARK: - Button Section
    private var buttonSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(title: "Get Started", action: onContinue)
                .opacity(buttonOpacity)
            
            Text("Takes less than 2 minutes to set up")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
                .opacity(buttonOpacity)
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Subtitle animation
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            subtitleOpacity = 1.0
        }
        
        // Button animation
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            buttonOpacity = 1.0
        }
        
        // Particles
        withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
            particlesVisible = true
        }
    }
}

// MARK: - Floating Particles
struct FloatingParticles: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(AppTheme.Colors.accentCyan.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .offset(y: animate ? -20 : 20)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...5))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
