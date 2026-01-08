//
//  RestrictionsView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct RestrictionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onBack: () -> Void
    let onContinue: () -> Void
    
    @State private var cardsAppeared = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                Spacer().frame(height: AppTheme.Spacing.xl)
                
                // Restriction cards (multi-select)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(Array(ExerciseRestriction.allCases.enumerated()), id: \.element.id) { index, restriction in
                            MultiSelectCard(
                                icon: restriction.icon,
                                title: restriction.title,
                                isSelected: viewModel.selectedRestrictions.contains(restriction),
                                action: { viewModel.toggleRestriction(restriction) }
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                                value: cardsAppeared
                            )
                        }
                        
                        // Other text field
                        if viewModel.selectedRestrictions.contains(.other) {
                            otherTextField
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.md)
                }
                
                bottomSection
            }
        }
        .onAppear {
            withAnimation { cardsAppeared = true }
        }
    }
    
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
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.md)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(viewModel.currentStep.title)
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text(viewModel.currentStep.subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.accentCyan)
                    .padding(.top, 4)
            }
            .padding(.top, AppTheme.Spacing.lg)
        }
    }
    
    private var otherTextField: some View {
        TextField("Describe your restriction...", text: $viewModel.otherRestrictionText)
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.softWhite)
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.top, AppTheme.Spacing.sm)
    }
    
    private var bottomSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PrimaryButton(
                title: "Complete",
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
    vm.currentStep = .restrictions
    return RestrictionsView(viewModel: vm, onBack: {}, onContinue: {})
}
