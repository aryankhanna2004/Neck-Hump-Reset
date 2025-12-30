//
//  ProgressIndicator.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct OnboardingProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? AppTheme.Colors.accentCyan : AppTheme.Colors.mutedGray.opacity(0.3))
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.deepNavy.ignoresSafeArea()
        VStack(spacing: 30) {
            OnboardingProgressIndicator(totalSteps: 4, currentStep: 0)
            OnboardingProgressIndicator(totalSteps: 4, currentStep: 1)
            OnboardingProgressIndicator(totalSteps: 4, currentStep: 2)
            OnboardingProgressIndicator(totalSteps: 4, currentStep: 3)
        }
    }
}
