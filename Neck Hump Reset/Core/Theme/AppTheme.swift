//
//  AppTheme.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primaryBlue = Color(red: 0.1, green: 0.2, blue: 0.45)
        static let accentCyan = Color(red: 0.3, green: 0.7, blue: 0.9)
        static let glowBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
        static let deepNavy = Color(red: 0.02, green: 0.05, blue: 0.15)
        static let softWhite = Color(red: 0.95, green: 0.97, blue: 1.0)
        static let mutedGray = Color(red: 0.6, green: 0.65, blue: 0.7)
        
        static let backgroundGradient = LinearGradient(
            colors: [deepNavy, primaryBlue.opacity(0.8), deepNavy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [primaryBlue.opacity(0.3), deepNavy.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let buttonGradient = LinearGradient(
            colors: [accentCyan, glowBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14, weight: .regular, design: .rounded)
        static let small = Font.system(size: 12, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let pill: CGFloat = 50
    }
}

// MARK: - View Modifiers
struct GlowEffect: ViewModifier {
    var color: Color = AppTheme.Colors.accentCyan
    var radius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(AppTheme.Colors.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glowEffect(color: Color = AppTheme.Colors.accentCyan, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
    
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
