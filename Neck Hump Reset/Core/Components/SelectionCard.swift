//
//  SelectionCard.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct SelectionCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                Text(icon)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.Colors.accentCyan.opacity(0.2) : AppTheme.Colors.primaryBlue.opacity(0.3))
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                }
                
                Spacer()
                
                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.Colors.accentCyan : AppTheme.Colors.mutedGray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.accentCyan)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? AppTheme.Colors.primaryBlue.opacity(0.4) : AppTheme.Colors.primaryBlue.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(isSelected ? AppTheme.Colors.accentCyan.opacity(0.6) : AppTheme.Colors.accentCyan.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.deepNavy.ignoresSafeArea()
        VStack(spacing: 12) {
            SelectionCard(
                icon: "🖥️",
                title: "Desk worker",
                subtitle: "Office, remote work, studying",
                isSelected: true,
                action: {}
            )
            SelectionCard(
                icon: "🎮",
                title: "Gamer / Heavy phone user",
                subtitle: nil,
                isSelected: false,
                action: {}
            )
        }
        .padding()
    }
}
