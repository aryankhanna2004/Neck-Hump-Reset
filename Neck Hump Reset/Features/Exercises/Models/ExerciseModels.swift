//
//  ExerciseModels.swift
//  Neck Hump Reset
//
//  Research-backed exercise models for neck posture correction
//

import Foundation
import SwiftUI

// MARK: - Research Citations
/// Exercise protocols based on peer-reviewed research:
///
/// **Primary Sources:**
///
/// 1. Sadeghi A, Rostami M, Ameri S, et al. (2022)
///    "Effectiveness of isometric exercises on disability and pain of cervical spondylosis:
///    a randomized controlled trial"
///    BMC Sports Science, Medicine and Rehabilitation, 14:108
///    DOI: 10.1186/s13102-022-00500-7
///    - 4-week isometric exercise protocol
///    - 6 movements, 3 sets/day, hold 10 seconds, 5 reps each
///    - Significant reduction in NDI and NPAD scores (P<0.001)
///
/// 2. Gallego Izquierdo T, Pecos-Martin D, et al. (2016)
///    "Comparison of cranio-cervical flexion training versus cervical proprioception training
///    in patients with chronic neck pain: A randomized controlled clinical trial"
///    Journal of Rehabilitation Medicine, 48(1):48-55
///    DOI: 10.2340/16501977-2034
///    - 6-week CCF training protocol
///    - Improved CCFT performance and reduced pain/disability
///
/// 3. Jull GA, O'Leary SP, Falla DL (2008)
///    "Clinical assessment of the deep cervical flexor muscles: the craniocervical flexion test"
///    Journal of Manipulative and Physiological Therapeutics, 31:525-533
///    - Deep neck flexor training protocol
///    - Progressive pressure biofeedback training

// MARK: - Exercise Category
enum ExerciseCategory: String, CaseIterable, Identifiable {
    case isometric = "Isometric Strengthening"
    case deepFlexor = "Deep Neck Flexor"
    case proprioception = "Proprioception"
    case stretch = "Stretching"
    case postural = "Postural Correction"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .isometric: return "hand.raised.fill"
        case .deepFlexor: return "arrow.down.circle.fill"
        case .proprioception: return "eye.fill"
        case .stretch: return "figure.flexibility"
        case .postural: return "figure.stand"
        }
    }
    
    var color: Color {
        switch self {
        case .isometric: return .orange
        case .deepFlexor: return AppTheme.Colors.accentCyan
        case .proprioception: return .purple
        case .stretch: return .green
        case .postural: return .blue
        }
    }
    
    var description: String {
        switch self {
        case .isometric:
            return "Strengthen muscles without joint movement"
        case .deepFlexor:
            return "Target deep stabilizing neck muscles"
        case .proprioception:
            return "Improve neck position awareness"
        case .stretch:
            return "Release tension and improve flexibility"
        case .postural:
            return "Correct alignment and posture habits"
        }
    }
}

// MARK: - Exercise Difficulty
enum ExerciseDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let difficulty: ExerciseDifficulty
    let duration: Int // seconds
    let holdTime: Int // seconds per rep
    let repetitions: Int
    let sets: Int
    let description: String
    let instructions: [String]
    let tips: [String]
    let researchCitation: String
    let iconName: String
    
    var totalTime: Int {
        sets * repetitions * (holdTime + 5) // 5 sec rest between reps
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes) min"
        }
        return "\(seconds)s"
    }
}

// MARK: - Exercise Routine
struct ExerciseRoutine: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let exercises: [Exercise]
    let category: ExerciseCategory
    let researchBasis: String
    let recommendedFrequency: String
    let duration: String
    
    var totalExercises: Int {
        exercises.count
    }
    
    var estimatedTime: Int {
        exercises.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTime: String {
        let minutes = estimatedTime / 60
        return "\(minutes) min"
    }
}

// MARK: - Predefined Exercise Library
struct ExerciseLibrary {
    
    // MARK: - Isometric Exercises (Sadeghi et al. 2022)
    static let isometricExercises: [Exercise] = [
        Exercise(
            name: "Cervical Flexion Isometric",
            category: .isometric,
            difficulty: .beginner,
            duration: 60,
            holdTime: 10,
            repetitions: 5,
            sets: 1,
            description: "Strengthen front neck muscles by pushing forehead against hands",
            instructions: [
                "Sit upright with good posture",
                "Place palms of both hands on your forehead",
                "Lean neck slightly forward",
                "Push head forward against hands while resisting with hands",
                "Hold for 10 seconds",
                "Release slowly and rest 5 seconds",
                "Repeat 5 times"
            ],
            tips: [
                "Keep shoulders relaxed",
                "Breathe normally throughout",
                "Don't hold your breath",
                "Apply moderate pressure, not maximum force"
            ],
            researchCitation: "Sadeghi et al. (2022) BMC Sports Sci Med Rehabil",
            iconName: "arrow.down.circle"
        ),
        
        Exercise(
            name: "Cervical Extension Isometric",
            category: .isometric,
            difficulty: .beginner,
            duration: 60,
            holdTime: 10,
            repetitions: 5,
            sets: 1,
            description: "Strengthen back neck muscles by pushing head backward against hands",
            instructions: [
                "Sit upright with neck straight",
                "Place palms of both hands behind your head",
                "Push head backwards against hands",
                "Resist the movement with your hands",
                "Hold for 10 seconds",
                "Release slowly and rest 5 seconds",
                "Repeat 5 times"
            ],
            tips: [
                "Interlace fingers for better grip",
                "Keep chin level, don't tilt up",
                "Focus on the back of neck muscles",
                "Maintain steady breathing"
            ],
            researchCitation: "Sadeghi et al. (2022) BMC Sports Sci Med Rehabil",
            iconName: "arrow.up.circle"
        ),
        
        Exercise(
            name: "Right Lateral Flexion Isometric",
            category: .isometric,
            difficulty: .beginner,
            duration: 60,
            holdTime: 10,
            repetitions: 5,
            sets: 1,
            description: "Strengthen right side neck muscles",
            instructions: [
                "Sit upright with neck straight",
                "Place palm of right hand on right side of head",
                "Push head towards hand (trying to bring ear to shoulder)",
                "Resist the movement with your hand",
                "Hold for 10 seconds",
                "Release slowly and rest 5 seconds",
                "Repeat 5 times"
            ],
            tips: [
                "Keep shoulders level and relaxed",
                "Don't rotate your head",
                "Apply equal pressure with head and hand",
                "Focus on side neck muscles"
            ],
            researchCitation: "Sadeghi et al. (2022) BMC Sports Sci Med Rehabil",
            iconName: "arrow.right.circle"
        ),
        
        Exercise(
            name: "Left Lateral Flexion Isometric",
            category: .isometric,
            difficulty: .beginner,
            duration: 60,
            holdTime: 10,
            repetitions: 5,
            sets: 1,
            description: "Strengthen left side neck muscles",
            instructions: [
                "Sit upright with neck straight",
                "Place palm of left hand on left side of head",
                "Push head towards hand (trying to bring ear to shoulder)",
                "Resist the movement with your hand",
                "Hold for 10 seconds",
                "Release slowly and rest 5 seconds",
                "Repeat 5 times"
            ],
            tips: [
                "Keep shoulders level and relaxed",
                "Don't rotate your head",
                "Apply equal pressure with head and hand",
                "Focus on side neck muscles"
            ],
            researchCitation: "Sadeghi et al. (2022) BMC Sports Sci Med Rehabil",
            iconName: "arrow.left.circle"
        ),
        
        Exercise(
            name: "Right Rotation Isometric",
            category: .isometric,
            difficulty: .beginner,
            duration: 60,
            holdTime: 10,
            repetitions: 5,
            sets: 1,
            description: "Strengthen rotational neck muscles (right)",
            instructions: [
                "Sit upright with neck straight",
                "Place palm of right hand on right side of face",
                "Try to rotate head slightly to the right",
                "Resist the movement with your hand",
                "Hold for 10 seconds",
                "Release slowly and rest 5 seconds",
                "Repeat 5 times"
            ],
            tips: [
                "Keep your chin level",
                "Don't tilt head up or down",
                "Focus on the rotation movement only",
                "Use gentle to moderate pressure"
            ],
            researchCitation: "Sadeghi et al. (2022) BMC Sports Sci Med Rehabil",
            iconName: "arrow.turn.right.up"
        ),
        
        Exercise(
            name: "Left Rotation Isometric",
            category: .isometric,
            difficulty: .beginner,
            duration: 60,
            holdTime: 10,
            repetitions: 5,
            sets: 1,
            description: "Strengthen rotational neck muscles (left)",
            instructions: [
                "Sit upright with neck straight",
                "Place palm of left hand on left side of face",
                "Try to rotate head slightly to the left",
                "Resist the movement with your hand",
                "Hold for 10 seconds",
                "Release slowly and rest 5 seconds",
                "Repeat 5 times"
            ],
            tips: [
                "Keep your chin level",
                "Don't tilt head up or down",
                "Focus on the rotation movement only",
                "Use gentle to moderate pressure"
            ],
            researchCitation: "Sadeghi et al. (2022) BMC Sports Sci Med Rehabil",
            iconName: "arrow.turn.left.up"
        )
    ]
    
    // MARK: - Deep Neck Flexor Exercises (Jull et al. 2008, Gallego Izquierdo et al. 2016)
    static let deepFlexorExercises: [Exercise] = [
        Exercise(
            name: "Chin Tuck (Craniocervical Flexion)",
            category: .deepFlexor,
            difficulty: .beginner,
            duration: 120,
            holdTime: 10,
            repetitions: 10,
            sets: 1,
            description: "Activate deep neck flexors with gentle nodding motion",
            instructions: [
                "Lie on your back with knees bent",
                "Place a small towel under head if needed for neutral position",
                "Gently nod your head as if saying 'yes'",
                "Focus on the movement coming from the top of your neck",
                "You should feel a gentle stretch at the back of your neck",
                "Hold for 10 seconds",
                "Slowly release and repeat 10 times"
            ],
            tips: [
                "Don't lift your head off the surface",
                "Keep the movement small and controlled",
                "Avoid using the front neck muscles (SCM)",
                "Place fingers on front of neck to check for unwanted muscle activity"
            ],
            researchCitation: "Jull et al. (2008) J Manipulative Physiol Ther; Gallego Izquierdo et al. (2016) J Rehabil Med",
            iconName: "arrow.down.to.line"
        ),
        
        Exercise(
            name: "Chin Tuck with Head Lift",
            category: .deepFlexor,
            difficulty: .intermediate,
            duration: 90,
            holdTime: 5,
            repetitions: 10,
            sets: 1,
            description: "Progress chin tuck by lifting head slightly",
            instructions: [
                "Lie on your back with knees bent",
                "First perform the chin tuck (nodding motion)",
                "While maintaining the tuck, lift head 1-2 cm off surface",
                "Keep chin tucked throughout the lift",
                "Hold for 5 seconds",
                "Lower head slowly while maintaining chin tuck",
                "Release and repeat 10 times"
            ],
            tips: [
                "Initiate movement with chin tuck, not head lift",
                "Keep lift minimal - just clearing the surface",
                "If neck muscles cramp, you're lifting too high",
                "Progress slowly over weeks"
            ],
            researchCitation: "Jull et al. (2008) J Manipulative Physiol Ther",
            iconName: "arrow.up.and.down"
        ),
        
        Exercise(
            name: "Seated Chin Tuck",
            category: .deepFlexor,
            difficulty: .beginner,
            duration: 60,
            holdTime: 5,
            repetitions: 10,
            sets: 1,
            description: "Perform chin tuck in functional seated position",
            instructions: [
                "Sit tall with good posture",
                "Look straight ahead",
                "Gently draw chin back (make a double chin)",
                "Imagine lengthening the back of your neck",
                "Hold for 5 seconds",
                "Release slowly",
                "Repeat 10 times"
            ],
            tips: [
                "Don't tilt head down - keep eyes level",
                "Movement should be horizontal, not vertical",
                "Can do against wall for feedback",
                "Practice throughout the day at desk"
            ],
            researchCitation: "Falla et al. (2007) Manual Therapy",
            iconName: "person.and.arrow.left.and.arrow.right"
        )
    ]
    
    // MARK: - Proprioception Exercises (Gallego Izquierdo et al. 2016)
    static let proprioceptionExercises: [Exercise] = [
        Exercise(
            name: "Head Relocation (Eyes Open)",
            category: .proprioception,
            difficulty: .beginner,
            duration: 120,
            holdTime: 3,
            repetitions: 10,
            sets: 1,
            description: "Improve neck position sense with visual feedback",
            instructions: [
                "Sit facing a wall at arm's length",
                "Place a small target at eye level",
                "Note your starting head position",
                "Close eyes and rotate head to one side",
                "Return head to starting position with eyes closed",
                "Open eyes and check accuracy",
                "Repeat to both sides, 10 times each"
            ],
            tips: [
                "Start with small movements",
                "Focus on the feeling of head position",
                "Don't rush - accuracy over speed",
                "Progress to eyes closed throughout"
            ],
            researchCitation: "Gallego Izquierdo et al. (2016) J Rehabil Med; Revel et al. (1994) Arch Phys Med Rehabil",
            iconName: "eye"
        ),
        
        Exercise(
            name: "Gaze Stability",
            category: .proprioception,
            difficulty: .intermediate,
            duration: 60,
            holdTime: 30,
            repetitions: 2,
            sets: 1,
            description: "Maintain focus while moving head",
            instructions: [
                "Sit or stand with good posture",
                "Hold a finger or target at arm's length",
                "Keep eyes focused on the target",
                "Slowly turn head left and right",
                "Maintain focus on target throughout",
                "Continue for 30 seconds",
                "Rest and repeat"
            ],
            tips: [
                "Keep target in sharp focus",
                "Start with slow movements",
                "If dizzy, reduce speed or range",
                "Progress by increasing speed gradually"
            ],
            researchCitation: "Gallego Izquierdo et al. (2016) J Rehabil Med",
            iconName: "eyes"
        )
    ]
    
    // MARK: - Stretching Exercises
    static let stretchExercises: [Exercise] = [
        Exercise(
            name: "Upper Trapezius Stretch",
            category: .stretch,
            difficulty: .beginner,
            duration: 60,
            holdTime: 30,
            repetitions: 2,
            sets: 1,
            description: "Release tension in upper shoulders and neck",
            instructions: [
                "Sit or stand with good posture",
                "Tilt head to the right, bringing ear toward shoulder",
                "Place right hand gently on head for light pressure",
                "Keep left shoulder down",
                "Hold for 30 seconds",
                "Slowly return to center",
                "Repeat on left side"
            ],
            tips: [
                "Don't force the stretch",
                "Keep shoulders relaxed and down",
                "Breathe deeply throughout",
                "Should feel gentle stretch, not pain"
            ],
            researchCitation: "General neck rehabilitation protocols",
            iconName: "figure.flexibility"
        ),
        
        Exercise(
            name: "Levator Scapulae Stretch",
            category: .stretch,
            difficulty: .beginner,
            duration: 60,
            holdTime: 30,
            repetitions: 2,
            sets: 1,
            description: "Stretch muscle connecting neck to shoulder blade",
            instructions: [
                "Sit with good posture",
                "Turn head 45 degrees to the right",
                "Tilt chin down toward right armpit",
                "Place right hand on back of head for gentle pressure",
                "Hold for 30 seconds",
                "Slowly return to center",
                "Repeat on left side"
            ],
            tips: [
                "Look toward your armpit",
                "Keep opposite shoulder down",
                "Use minimal hand pressure",
                "Breathe into the stretch"
            ],
            researchCitation: "General neck rehabilitation protocols",
            iconName: "arrow.down.left.and.arrow.up.right"
        )
    ]
    
    // MARK: - Postural Exercises
    static let posturalExercises: [Exercise] = [
        Exercise(
            name: "Wall Angel",
            category: .postural,
            difficulty: .intermediate,
            duration: 90,
            holdTime: 3,
            repetitions: 10,
            sets: 1,
            description: "Improve upper back and shoulder posture",
            instructions: [
                "Stand with back against wall",
                "Feet slightly away from wall, knees slightly bent",
                "Press lower back, upper back, and head against wall",
                "Place arms against wall in 'W' position",
                "Slowly slide arms up to 'Y' position",
                "Keep all contact points against wall",
                "Return to 'W' and repeat 10 times"
            ],
            tips: [
                "Maintain chin tuck throughout",
                "Don't arch lower back off wall",
                "Keep wrists against wall if possible",
                "Move slowly and controlled"
            ],
            researchCitation: "Postural rehabilitation protocols; Jull et al. (2002) Spine",
            iconName: "figure.arms.open"
        ),
        
        Exercise(
            name: "Scapular Retraction",
            category: .postural,
            difficulty: .beginner,
            duration: 60,
            holdTime: 5,
            repetitions: 10,
            sets: 1,
            description: "Strengthen muscles that pull shoulders back",
            instructions: [
                "Sit or stand with arms at sides",
                "Squeeze shoulder blades together",
                "Imagine pinching a pencil between them",
                "Keep shoulders down (don't shrug)",
                "Hold for 5 seconds",
                "Release slowly",
                "Repeat 10 times"
            ],
            tips: [
                "Don't arch your back",
                "Keep neck relaxed",
                "Combine with chin tuck for better effect",
                "Can do throughout the day"
            ],
            researchCitation: "Jull et al. (2002) Spine; Falla et al. (2007) Manual Therapy",
            iconName: "arrow.left.and.right.square"
        )
    ]
    
    // MARK: - Predefined Routines
    static let routines: [ExerciseRoutine] = [
        ExerciseRoutine(
            name: "Isometric Neck Strengthening",
            description: "Complete 6-movement isometric protocol shown to significantly reduce neck pain and disability",
            exercises: isometricExercises,
            category: .isometric,
            researchBasis: "Based on Sadeghi et al. (2022) RCT showing significant improvement in NDI and NPAD scores after 4 weeks (P<0.001)",
            recommendedFrequency: "3 times daily (morning, afternoon, evening)",
            duration: "4 weeks"
        ),
        
        ExerciseRoutine(
            name: "Deep Neck Flexor Training",
            description: "Progressive training for the deep cervical flexor muscles that support your neck",
            exercises: deepFlexorExercises,
            category: .deepFlexor,
            researchBasis: "Based on Jull et al. (2008) and Gallego Izquierdo et al. (2016) showing improved neuromuscular control",
            recommendedFrequency: "Twice daily",
            duration: "6 weeks"
        ),
        
        ExerciseRoutine(
            name: "Proprioception & Balance",
            description: "Improve your neck's position sense and eye-head coordination",
            exercises: proprioceptionExercises,
            category: .proprioception,
            researchBasis: "Based on Gallego Izquierdo et al. (2016) RCT comparing proprioception vs CCF training",
            recommendedFrequency: "Once daily",
            duration: "6-8 weeks"
        ),
        
        ExerciseRoutine(
            name: "Neck Stretching",
            description: "Release tension in commonly tight neck and shoulder muscles",
            exercises: stretchExercises,
            category: .stretch,
            researchBasis: "Standard neck rehabilitation protocols",
            recommendedFrequency: "2-3 times daily or as needed",
            duration: "Ongoing"
        ),
        
        ExerciseRoutine(
            name: "Postural Correction",
            description: "Exercises to improve overall posture and reduce forward head position",
            exercises: posturalExercises,
            category: .postural,
            researchBasis: "Based on Jull et al. (2002) and Falla et al. (2007) postural rehabilitation research",
            recommendedFrequency: "Daily, plus throughout the day",
            duration: "Ongoing"
        ),
        
        // Quick routines
        ExerciseRoutine(
            name: "Quick 5-Minute Reset",
            description: "Essential exercises for a quick posture break",
            exercises: [
                deepFlexorExercises[2], // Seated Chin Tuck
                isometricExercises[0],  // Cervical Flexion
                isometricExercises[1],  // Cervical Extension
                posturalExercises[1]    // Scapular Retraction
            ],
            category: .postural,
            researchBasis: "Combined protocol from multiple studies",
            recommendedFrequency: "Every 1-2 hours during desk work",
            duration: "5 minutes"
        )
    ]
    
    // MARK: - Get all exercises
    static var allExercises: [Exercise] {
        isometricExercises + deepFlexorExercises + proprioceptionExercises + stretchExercises + posturalExercises
    }
}
