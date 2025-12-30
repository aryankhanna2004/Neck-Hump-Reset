//
//  ProgressPlaceholderView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct ProgressPlaceholderView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.4))
                
                Text("Progress Tracking")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text("Complete your first routine to\nstart tracking your progress")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    ProgressPlaceholderView()
}
