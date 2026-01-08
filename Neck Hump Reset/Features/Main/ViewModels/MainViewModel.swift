//
//  MainViewModel.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var selectedTab: MainTab = .home
    @Published var userProfile: UserProfile
    
    init() {
        self.userProfile = UserProfile.load()
    }
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hey there"
        }
    }
    
    var timeCommitmentDisplay: String {
        guard let time = userProfile.timeCommitment,
              let commitment = TimeCommitment(rawValue: time) else {
            return "5 min"
        }
        switch commitment {
        case .min3to5: return "3-5 min"
        case .min5to10: return "5-10 min"
        case .min10to15: return "10-15 min"
        case .surprise: return "Flex"
        }
    }
    
    var situationLabel: String {
        guard let sit = userProfile.situation,
              let situation = UserSituation(rawValue: sit) else {
            return "Reset"
        }
        switch situation {
        case .student: return "Student Reset"
        case .deskWork: return "Desk Worker Reset"
        case .gamer: return "Gamer Reset"
        case .phoneUser: return "Phone User Reset"
        case .physicalJob: return "Active Reset"
        case .other: return "Daily Reset"
        }
    }
    
    var usesCamera: Bool {
        userProfile.cameraPreference == CameraPreference.useCamera.rawValue
    }
}

enum MainTab: String, CaseIterable {
    case home = "home"
    case exercises = "exercises"
    case progress = "progress"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .exercises: return "Exercises"
        case .progress: return "Progress"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "camera.viewfinder"
        case .exercises: return "figure.strengthtraining.traditional"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
}
