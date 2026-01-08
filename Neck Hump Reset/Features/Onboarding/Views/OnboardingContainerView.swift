//
//  OnboardingContainerView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeView(onContinue: { viewModel.nextStep() })
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .nameEntry:
                NameEntryView(
                    viewModel: viewModel,
                    onBack: { viewModel.previousStep() },
                    onContinue: { viewModel.nextStep() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .screenTime:
                ScreenTimeView(
                    viewModel: viewModel,
                    onBack: { viewModel.previousStep() },
                    onContinue: { viewModel.nextStep() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .screenTimeReassurance:
                ScreenTimeReassuranceView(onContinue: { viewModel.nextStep() })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .situation:
                SituationView(
                    viewModel: viewModel,
                    onBack: { viewModel.previousStep() },
                    onContinue: { viewModel.nextStep() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .timeCommitment:
                TimeCommitmentView(
                    viewModel: viewModel,
                    onBack: { viewModel.previousStep() },
                    onContinue: { viewModel.nextStep() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .movementComfort:
                MovementComfortView(
                    viewModel: viewModel,
                    onBack: { viewModel.previousStep() },
                    onContinue: { viewModel.nextStep() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .restrictions:
                RestrictionsView(
                    viewModel: viewModel,
                    onBack: { viewModel.previousStep() },
                    onContinue: { viewModel.nextStep() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.currentStep)
        .onChange(of: viewModel.isOnboardingComplete) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isOnboardingComplete = true
                }
            }
        }
    }
}

#Preview {
    OnboardingContainerView(isOnboardingComplete: .constant(false))
}
