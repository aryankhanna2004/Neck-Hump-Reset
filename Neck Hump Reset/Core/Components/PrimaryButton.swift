//
//  PrimaryButton.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(isEnabled ? AppTheme.Colors.deepNavy : AppTheme.Colors.mutedGray)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if isEnabled {
                            AppTheme.Colors.buttonGradient
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .shadow(color: isEnabled ? AppTheme.Colors.accentCyan.opacity(0.4) : .clear, radius: 12, x: 0, y: 4)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.5), lineWidth: 1.5)
                )
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.deepNavy.ignoresSafeArea()
        VStack(spacing: 20) {
            PrimaryButton(title: "Continue", action: {})
            PrimaryButton(title: "Disabled", action: {}, isEnabled: false)
            SecondaryButton(title: "Skip for now", action: {})
        }
        .padding()
    }
}
