//
//  NameEntryView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct NameEntryView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onBack: () -> Void
    let onContinue: () -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Spacer().frame(height: AppTheme.Spacing.xxl)
                
                // Name fields
                VStack(spacing: AppTheme.Spacing.lg) {
                    // First name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                        
                        TextField("", text: $viewModel.firstName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.Colors.softWhite)
                            .padding(AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                            .stroke(
                                                focusedField == .firstName ? AppTheme.Colors.accentCyan : AppTheme.Colors.accentCyan.opacity(0.3),
                                                lineWidth: focusedField == .firstName ? 2 : 1
                                            )
                                    )
                            )
                            .focused($focusedField, equals: .firstName)
                            .textContentType(.givenName)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .lastName
                            }
                    }
                    
                    // Last name (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Last Name")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.mutedGray)
                            
                            Text("(optional)")
                                .font(AppTheme.Typography.small)
                                .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.6))
                        }
                        
                        TextField("", text: $viewModel.lastName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.Colors.softWhite)
                            .padding(AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                            .stroke(
                                                focusedField == .lastName ? AppTheme.Colors.accentCyan : AppTheme.Colors.accentCyan.opacity(0.3),
                                                lineWidth: focusedField == .lastName ? 2 : 1
                                            )
                                    )
                            )
                            .focused($focusedField, equals: .lastName)
                            .textContentType(.familyName)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                                if viewModel.canProceed {
                                    onContinue()
                                }
                            }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                Spacer()
                
                // Bottom buttons
                bottomSection
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .firstName
            }
        }
        .onTapGesture {
            focusedField = nil
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
                action: {
                    focusedField = nil
                    onContinue()
                },
                isEnabled: viewModel.canProceed
            )
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.currentStep = .nameEntry
    return NameEntryView(
        viewModel: vm,
        onBack: {},
        onContinue: {}
    )
}
