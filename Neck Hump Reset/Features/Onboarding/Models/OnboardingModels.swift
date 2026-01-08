//
//  OnboardingModels.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import Foundation

// MARK: - Onboarding Step
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case nameEntry
    case screenTime
    case screenTimeReassurance
    case situation
    case timeCommitment
    case movementComfort
    case restrictions
    
    var title: String {
        switch self {
        case .welcome:
            return ""
        case .nameEntry:
            return "What's your name?"
        case .screenTime:
            return "Screen & sitting time"
        case .screenTimeReassurance:
            return ""
        case .situation:
            return "Your situation"
        case .timeCommitment:
            return "How much can you actually do?"
        case .movementComfort:
            return "Movement comfort level"
        case .restrictions:
            return "Safety note"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return ""
        case .nameEntry:
            return "Let's personalize your experience"
        case .screenTime:
            return "On a typical day, how long are you sitting or on screens?"
        case .screenTimeReassurance:
            return ""
        case .situation:
            return "Which describes you best?"
        case .timeCommitment:
            return "How much time can you realistically give this most days?"
        case .movementComfort:
            return "How comfortable are you with exercise/stretching?"
        case .restrictions:
            return "Anything we should avoid?"
        }
    }
    
    // Steps that count toward progress (excluding reassurance screen and welcome)
    static var progressSteps: [OnboardingStep] {
        [.nameEntry, .screenTime, .situation, .timeCommitment, .movementComfort]
    }
    
    var progressIndex: Int? {
        OnboardingStep.progressSteps.firstIndex(of: self)
    }
}

// MARK: - Screen Time
enum ScreenTime: String, CaseIterable, Identifiable {
    case under3 = "under_3"
    case hours3to6 = "3_to_6"
    case hours6to9 = "6_to_9"
    case hours9plus = "9_plus"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .under3: return "☀️"
        case .hours3to6: return "🌤️"
        case .hours6to9: return "🌥️"
        case .hours9plus: return "🌙"
        }
    }
    
    var title: String {
        switch self {
        case .under3: return "Under 3 hours"
        case .hours3to6: return "3–6 hours"
        case .hours6to9: return "6–9 hours"
        case .hours9plus: return "9+ hours"
        }
    }
}

// MARK: - User Situation
enum UserSituation: String, CaseIterable, Identifiable {
    case student = "student"
    case deskWork = "desk_work"
    case gamer = "gamer"
    case phoneUser = "phone_user"
    case physicalJob = "physical_job"
    case other = "other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .student: return "📚"
        case .deskWork: return "💼"
        case .gamer: return "🎮"
        case .phoneUser: return "📱"
        case .physicalJob: return "🔧"
        case .other: return "✨"
        }
    }
    
    var title: String {
        switch self {
        case .student: return "Student"
        case .deskWork: return "Desk/office work"
        case .gamer: return "Gamer / streamer"
        case .phoneUser: return "On my phone a lot"
        case .physicalJob: return "Physical job, but still use screens"
        case .other: return "Other"
        }
    }
}

// MARK: - Time Commitment
enum TimeCommitment: String, CaseIterable, Identifiable {
    case min3to5 = "3_to_5"
    case min5to10 = "5_to_10"
    case min10to15 = "10_to_15"
    case surprise = "surprise"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .min3to5: return "⚡"
        case .min5to10: return "🔥"
        case .min10to15: return "💪"
        case .surprise: return "🎲"
        }
    }
    
    var title: String {
        switch self {
        case .min3to5: return "3–5 minutes"
        case .min5to10: return "5–10 minutes"
        case .min10to15: return "10–15 minutes"
        case .surprise: return "It depends, surprise me"
        }
    }
}

// MARK: - Movement Comfort
enum MovementComfort: String, CaseIterable, Identifiable {
    case beginner = "beginner"
    case sometimes = "sometimes"
    case regular = "regular"
    case restrictions = "restrictions"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .beginner: return "🌱"
        case .sometimes: return "🌿"
        case .regular: return "🌳"
        case .restrictions: return "⚠️"
        }
    }
    
    var title: String {
        switch self {
        case .beginner: return "Total beginner"
        case .sometimes: return "I stretch sometimes"
        case .regular: return "I work out regularly"
        case .restrictions: return "I have exercise restrictions"
        }
    }
}

// MARK: - Exercise Restrictions
enum ExerciseRestriction: String, CaseIterable, Identifiable {
    case neckInjury = "neck_injury"
    case shoulderProblems = "shoulder"
    case backProblems = "back"
    case dizziness = "dizziness"
    case other = "other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .neckInjury: return "🩹"
        case .shoulderProblems: return "💪"
        case .backProblems: return "🔙"
        case .dizziness: return "💫"
        case .other: return "📝"
        }
    }
    
    var title: String {
        switch self {
        case .neckInjury: return "Recent neck injury"
        case .shoulderProblems: return "Shoulder problems"
        case .backProblems: return "Back problems"
        case .dizziness: return "Dizziness issues"
        case .other: return "Other"
        }
    }
}

// MARK: - Camera Preference
enum CameraPreference: String, CaseIterable, Identifiable {
    case useCamera = "use_camera"
    case noCamera = "no_camera"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .useCamera: return "📸"
        case .noCamera: return "🏃"
        }
    }
    
    var title: String {
        switch self {
        case .useCamera: return "Yes, I'm okay using the camera"
        case .noCamera: return "No, just give me exercises"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .useCamera: return "Track your posture progress visually"
        case .noCamera: return "Exercise-only experience"
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var firstName: String?
    var lastName: String?
    var screenTime: String?
    var situations: [String]? // Changed to array for multi-select
    var timeCommitment: String?
    var movementComfort: String?
    var restrictions: [String]?
    var otherRestriction: String?
    var cameraPreference: String?
    var hasCompletedOnboarding: Bool = false
    var createdAt: Date = Date()
    
    // Legacy support for single situation
    var situation: String? {
        get { situations?.first }
        set {
            if let value = newValue {
                situations = [value]
            } else {
                situations = nil
            }
        }
    }
    
    static let storageKey = "user_profile"
    
    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserProfile.storageKey)
        }
    }
    
    // MARK: - Computed Display Properties
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "User" : name
    }
    
    var displayName: String {
        firstName ?? "User"
    }
    
    var initials: String {
        let first = firstName?.first.map { String($0).uppercased() } ?? ""
        let last = lastName?.first.map { String($0).uppercased() } ?? ""
        return first + last
    }
    
    var screenTimeDisplay: ScreenTime? {
        guard let raw = screenTime else { return nil }
        return ScreenTime(rawValue: raw)
    }
    
    var situationsDisplay: [UserSituation] {
        guard let situations = situations else { return [] }
        return situations.compactMap { UserSituation(rawValue: $0) }
    }
    
    var timeCommitmentDisplay: TimeCommitment? {
        guard let raw = timeCommitment else { return nil }
        return TimeCommitment(rawValue: raw)
    }
    
    var movementComfortDisplay: MovementComfort? {
        guard let raw = movementComfort else { return nil }
        return MovementComfort(rawValue: raw)
    }
    
    var restrictionsDisplay: [ExerciseRestriction] {
        guard let restrictions = restrictions else { return [] }
        return restrictions.compactMap { ExerciseRestriction(rawValue: $0) }
    }
    
    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}
