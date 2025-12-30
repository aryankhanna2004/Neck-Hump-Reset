//
//  TimeCommitmentView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct TimeCommitmentView: View {
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
                
                // Time commitment cards
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(Array(TimeCommitment.allCases.enumerated()), id: \.element.id) { index, time in
                        SelectionCard(
                            icon: time.icon,
                            title: time.title,
                            subtitle: nil,
                            isSelected: viewModel.selectedTimeCommitment == time,
                            action: { viewModel.selectTimeCommitment(time) }
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
                
                // Tip
                tipCard
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: cardsAppeared)
                
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
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .padding(.top, AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Tip Card
    private var tipCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.yellow)
            
            Text("Even 3 minutes daily beats 30 minutes once a week.")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.softWhite.opacity(0.8))
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
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
    vm.currentStep = .timeCommitment
    return TimeCommitmentView(
        viewModel: vm,
        onBack: {},
        onContinue: {}
    )
}
