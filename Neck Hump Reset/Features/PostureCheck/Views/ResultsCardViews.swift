//
//  ResultsCardViews.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI

// MARK: - Measurement Detail Row
struct MeasurementDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let explanation: String
    let threshold: String
    let isGood: Bool
    
    @State private var showExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isGood ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isGood ? .green : .orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        Button(action: { withAnimation(.spring(response: 0.3)) { showExplanation.toggle() } }) {
                            Image(systemName: showExplanation ? "chevron.up.circle.fill" : "questionmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.7))
                        }
                    }
                    
                    Text(threshold)
                        .font(.system(size: 11))
                        .foregroundColor(isGood ? .green.opacity(0.8) : .orange.opacity(0.8))
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isGood ? .green : .orange)
            }
            
            if showExplanation {
                Text(explanation)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(.leading, 56)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
        )
    }
}
