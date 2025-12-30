//
//  MovementComfortView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct MovementComfortView: View {
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
                
                Spacer().frame(height: AppTheme.Spacing.xl)
                
                // Movement comfort cards
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(Array(MovementComfort.allCases.enumerated()), id: \.element.id) { index, comfort in
                        SelectionCard(
                            icon: comfort.icon,
                            title: comfort.title,
                            subtitle: nil,
                            isSelected: viewModel.selectedMovementComfort == comfort,
                            action: { viewModel.selectMovementComfort(comfort) }
                        )
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.06),
                            value: cardsAppeared
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Note about restrictions
                if viewModel.selectedMovementComfort == .restrictions {
                    restrictionsNote
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Spacer()
                
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
    
    // MARK: - Restrictions Note
    private var restrictionsNote: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accentCyan)
            
            Text("We'll ask about specifics on the next screen")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    // MARK: - Bottom
    private var bottomSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(
                title: viewModel.selectedMovementComfort == .restrictions ? "Continue" : "Complete",
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
    vm.currentStep = .movementComfort
    return MovementComfortView(
        viewModel: vm,
        onBack: {},
        onContinue: {}
    )
}
