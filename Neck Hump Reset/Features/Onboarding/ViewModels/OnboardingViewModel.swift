//
//  OnboardingViewModel.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: OnboardingStep = .welcome
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var selectedScreenTime: ScreenTime?
    @Published var selectedSituations: Set<UserSituation> = [] // Changed to Set for multi-select
    @Published var selectedTimeCommitment: TimeCommitment?
    @Published var selectedMovementComfort: MovementComfort?
    @Published var selectedRestrictions: Set<ExerciseRestriction> = []
    @Published var otherRestrictionText: String = ""
    @Published var isOnboardingComplete: Bool = false
    
    // Legacy computed property for backward compatibility
    var selectedSituation: UserSituation? {
        selectedSituations.first
    }
    
    // MARK: - Computed Properties
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .nameEntry:
            return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        case .screenTime:
            return selectedScreenTime != nil
        case .screenTimeReassurance:
            return true
        case .situation:
            return !selectedSituations.isEmpty // At least one situation selected
        case .timeCommitment:
            return selectedTimeCommitment != nil
        case .movementComfort:
            return selectedMovementComfort != nil
        case .restrictions:
            return !selectedRestrictions.isEmpty
        }
    }
    
    var isLastStep: Bool {
        if hasRestrictions {
            return currentStep == .restrictions
        }
        return currentStep == .movementComfort
    }
    
    var totalProgressSteps: Int {
        OnboardingStep.progressSteps.count
    }
    
    var currentProgressIndex: Int {
        currentStep.progressIndex ?? 0
    }
    
    var hasRestrictions: Bool {
        selectedMovementComfort == .restrictions
    }
    
    // MARK: - Init
    init() {
        loadExistingProfile()
    }
    
    // MARK: - Navigation Methods
    func nextStep() {
        guard canProceed else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                currentStep = .nameEntry
            case .nameEntry:
                currentStep = .screenTime
            case .screenTime:
                currentStep = .screenTimeReassurance
            case .screenTimeReassurance:
                currentStep = .situation
            case .situation:
                currentStep = .timeCommitment
            case .timeCommitment:
                currentStep = .movementComfort
            case .movementComfort:
                if hasRestrictions {
                    currentStep = .restrictions
                } else {
                    completeOnboarding()
                }
            case .restrictions:
                completeOnboarding()
            }
        }
    }
    
    func previousStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                break
            case .nameEntry:
                currentStep = .welcome
            case .screenTime:
                currentStep = .nameEntry
            case .screenTimeReassurance:
                currentStep = .screenTime
            case .situation:
                currentStep = .screenTimeReassurance
            case .timeCommitment:
                currentStep = .situation
            case .movementComfort:
                currentStep = .timeCommitment
            case .restrictions:
                currentStep = .movementComfort
            }
        }
    }
    
    // MARK: - Selection Methods
    func selectScreenTime(_ time: ScreenTime) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedScreenTime = time
        }
    }
    
    func toggleSituation(_ situation: UserSituation) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedSituations.contains(situation) {
                selectedSituations.remove(situation)
            } else {
                selectedSituations.insert(situation)
            }
        }
    }
    
    // Legacy method for backward compatibility
    func selectSituation(_ situation: UserSituation) {
        toggleSituation(situation)
    }
    
    func selectTimeCommitment(_ time: TimeCommitment) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTimeCommitment = time
        }
    }
    
    func selectMovementComfort(_ comfort: MovementComfort) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedMovementComfort = comfort
            // Clear restrictions if they don't have any
            if comfort != .restrictions {
                selectedRestrictions.removeAll()
                otherRestrictionText = ""
            }
        }
    }
    
    func toggleRestriction(_ restriction: ExerciseRestriction) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedRestrictions.contains(restriction) {
                selectedRestrictions.remove(restriction)
            } else {
                selectedRestrictions.insert(restriction)
            }
        }
    }
    
    // MARK: - Persistence
    private func completeOnboarding() {
        var profile = UserProfile()
        profile.firstName = firstName.trimmingCharacters(in: .whitespaces)
        profile.lastName = lastName.trimmingCharacters(in: .whitespaces)
        profile.screenTime = selectedScreenTime?.rawValue
        profile.situations = selectedSituations.map { $0.rawValue }
        profile.timeCommitment = selectedTimeCommitment?.rawValue
        profile.movementComfort = selectedMovementComfort?.rawValue
        profile.restrictions = selectedRestrictions.map { $0.rawValue }
        profile.otherRestriction = otherRestrictionText.isEmpty ? nil : otherRestrictionText
        // Camera is always enabled by default
        profile.cameraPreference = CameraPreference.useCamera.rawValue
        profile.hasCompletedOnboarding = true
        profile.save()
        
        isOnboardingComplete = true
    }
    
    private func loadExistingProfile() {
        let profile = UserProfile.load()
        if profile.hasCompletedOnboarding {
            isOnboardingComplete = true
        }
    }
    
    // For testing/debugging - reset onboarding
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: UserProfile.storageKey)
        currentStep = .welcome
        firstName = ""
        lastName = ""
        selectedScreenTime = nil
        selectedSituations.removeAll()
        selectedTimeCommitment = nil
        selectedMovementComfort = nil
        selectedRestrictions.removeAll()
        otherRestrictionText = ""
        isOnboardingComplete = false
    }
}
