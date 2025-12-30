//
//  SituationView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct SituationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onBack: () -> Void
    let onContinue: () -> Void
    
    @State private var cardsAppeared = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Spacer().frame(height: AppTheme.Spacing.lg)
                
                // Situation cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(Array(UserSituation.allCases.enumerated()), id: \.element.id) { index, situation in
                            SelectionCard(
                                icon: situation.icon,
                                title: situation.title,
                                subtitle: nil,
                                isSelected: viewModel.selectedSituation == situation,
                                action: { viewModel.selectSituation(situation) }
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                                value: cardsAppeared
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.md)
                }
                
                // Bottom buttons
                bottomSection
            }
        }
        .onAppear {
            withAnimation {
                cardsAppeared = true
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(AppTheme.Typography.body)
                    }
                    .foregroundColor(AppTheme.Colors.accentCyan)
                }
                
                Spacer()
                
                OnboardingProgressIndicator(
                    totalSteps: viewModel.totalProgressSteps,
                    currentStep: viewModel.currentProgressIndex
                )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.md)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(viewModel.currentStep.title)
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.currentStep.subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Bottom
    private var bottomSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(
                title: "Continue",
                action: onContinue,
                isEnabled: viewModel.canProceed
            )
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.currentStep = .situation
    return SituationView(
        viewModel: vm,
        onBack: {},
        onContinue: {}
    )
}
