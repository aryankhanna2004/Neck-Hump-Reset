//
//  PostureModels.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import Foundation
import CoreGraphics

// MARK: - Research Citations
/// Forward Head Posture (FHP) Assessment Research:
///
/// **Craniovertebral Angle (CVA):**
/// The CVA is measured between a horizontal line through C7 and a line from the tragus (ear) to C7.
/// - Normal posture: CVA > 50°
/// - Mild FHP: CVA 45-50°
/// - Moderate FHP: CVA 40-45°
/// - Severe FHP: CVA < 45°
///
/// Sources:
/// - "Comparison of craniovertebral angle in young adults with and without forward head posture"
///   (PubMed PMID: 38665167) - CVA < 45° indicates severe FHP, > 53° is normal
/// - "Forward head posture and neck pain" (PubMed PMID: 34109357)
/// - "A Preliminary Diagnostic Model for Forward Head Posture among Adolescents"
///   (MDPI Diagnostics 2024;14(4):394) - Forward neck tilt > 25° indicates FHP
///
/// **Apple Vision Framework Coordinate System:**
/// - VNRecognizedPoint returns normalized coordinates (0.0 to 1.0)
/// - Origin is at BOTTOM-LEFT of the image
/// - Y increases upward, X increases rightward
/// - Must flip Y coordinate for standard UI coordinates (origin top-left)
///
/// Source: Apple Developer Documentation - "Detecting Human Body Poses in Images"
/// https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images

// MARK: - Neck Hump Analysis Result
struct NeckHumpAnalysisResult {
    let forwardHeadDistance: Double    // cm estimate - how far head is forward of shoulders
    let neckAngle: Double              // Degrees - angle from vertical (0° = perfect, + = forward)
    let craniovertebralAngle: Double   // CVA in degrees (ideal > 50°)
    let humpSeverity: HumpSeverity     // Classification based on research
    let overallScore: Int              // 0-100 (100 = perfect posture)
    let timestamp: Date
    
    // Key measurements for visualization
    let earPosition: CGPoint           // Normalized position of ear
    let shoulderPosition: CGPoint      // Normalized position of shoulder
    let idealEarPosition: CGPoint      // Where ear should be for perfect posture
    
    init(forwardHeadDistance: Double, neckAngle: Double, earPosition: CGPoint, shoulderPosition: CGPoint) {
        self.forwardHeadDistance = forwardHeadDistance
        self.neckAngle = neckAngle
        self.earPosition = earPosition
        self.shoulderPosition = shoulderPosition
        self.timestamp = Date()
        
        // Calculate ideal ear position (directly above shoulder)
        self.idealEarPosition = CGPoint(x: shoulderPosition.x, y: earPosition.y)
        
        // Calculate CVA: angle between horizontal and ear-to-shoulder line
        // In a perfect posture, ear is directly above shoulder (CVA ≈ 90° from horizontal)
        // We measure deviation from vertical, so CVA = 90 - neckAngle
        self.craniovertebralAngle = 90.0 - abs(neckAngle)
        
        // Determine severity based on CVA (research-backed thresholds)
        // CVA > 50°: Normal
        // CVA 45-50°: Mild FHP
        // CVA 40-45°: Moderate FHP
        // CVA < 40°: Severe FHP
        if craniovertebralAngle >= 50 {
            self.humpSeverity = .minimal
            // Score 80-100 based on how close to ideal (CVA 90°)
            self.overallScore = min(100, Int(80 + (craniovertebralAngle - 50) * 0.5))
        } else if craniovertebralAngle >= 45 {
            self.humpSeverity = .mild
            // Score 60-79
            self.overallScore = Int(60 + (craniovertebralAngle - 45) * 4)
        } else if craniovertebralAngle >= 40 {
            self.humpSeverity = .moderate
            // Score 40-59
            self.overallScore = Int(40 + (craniovertebralAngle - 40) * 4)
        } else {
            self.humpSeverity = .severe
            // Score 10-39
            self.overallScore = max(10, Int(40 - (40 - craniovertebralAngle)))
        }
    }
    
    var feedback: [String] {
        humpSeverity.suggestions
    }
}

// MARK: - Hump Severity
enum HumpSeverity: String, CaseIterable {
    case minimal = "minimal"
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var title: String {
        switch self {
        case .minimal: return "Great Posture"
        case .mild: return "Mild Forward Head"
        case .moderate: return "Moderate Neck Hump"
        case .severe: return "Significant Neck Hump"
        }
    }
    
    var emoji: String {
        switch self {
        case .minimal: return "🎯"
        case .mild: return "👍"
        case .moderate: return "⚠️"
        case .severe: return "🔴"
        }
    }
    
    var color: String {
        switch self {
        case .minimal: return "green"
        case .mild: return "cyan"
        case .moderate: return "orange"
        case .severe: return "red"
        }
    }
    
    /// Research-backed CVA threshold for this severity
    var cvaThreshold: String {
        switch self {
        case .minimal: return "CVA ≥ 50°"
        case .mild: return "CVA 45-50°"
        case .moderate: return "CVA 40-45°"
        case .severe: return "CVA < 40°"
        }
    }
    
    var description: String {
        switch self {
        case .minimal:
            return "Your head is well-aligned over your shoulders (\(cvaThreshold)). Research shows this is within the normal range. Keep it up!"
        case .mild:
            return "Your head is slightly forward (\(cvaThreshold)). Studies show this is common and very fixable with consistent exercises."
        case .moderate:
            return "Your head is noticeably forward of your shoulders (\(cvaThreshold)). Research indicates daily corrective exercises can significantly improve this."
        case .severe:
            return "Significant forward head posture detected (\(cvaThreshold)). Research suggests consulting a physical therapist alongside exercises for best results."
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .minimal:
            return [
                "Maintain your great posture!",
                "Keep taking breaks from screens",
                "Continue with maintenance exercises"
            ]
        case .mild:
            return [
                "Practice chin tucks: Pull chin back, hold 5 seconds, repeat 10x",
                "Set hourly reminders to check your posture",
                "Raise your screen to eye level"
            ]
        case .moderate:
            return [
                "Do chin tucks 3x daily (10 reps each)",
                "Add wall angels: Stand against wall, slide arms up/down",
                "Stretch chest muscles daily - doorway stretches help",
                "Consider a standing desk or laptop riser"
            ]
        case .severe:
            return [
                "Start with gentle chin tucks - don't force it",
                "Focus on upper back strengthening exercises",
                "Consider seeing a physical therapist for personalized guidance",
                "Take breaks every 20-30 minutes when on screens",
                "Sleep with a supportive pillow that maintains neck curve"
            ]
        }
    }
}

// MARK: - Side Profile Pose Data
/// Represents detected body points from Apple's Vision framework
/// Note: Vision returns normalized coordinates (0.0-1.0) with origin at BOTTOM-LEFT
/// We convert to standard UI coordinates (origin top-left) by flipping Y: newY = 1 - y
struct SideProfilePose {
    // Key points for side view analysis (already converted to UI coordinates)
    let ear: CGPoint?           // Ear position (represents head position)
    let shoulder: CGPoint?      // Shoulder position
    let hip: CGPoint?           // Hip position (for full posture context)
    let nose: CGPoint?          // Nose (backup for head position)
    
    var isValid: Bool {
        // Need at least ear/nose and shoulder for neck hump analysis
        let hasHead = ear != nil || nose != nil
        let hasShoulder = shoulder != nil
        return hasHead && hasShoulder
    }
    
    var headPoint: CGPoint? {
        // Prefer ear, fallback to nose
        ear ?? nose
    }
    
    /// Calculate forward head distance in normalized coordinates
    /// Positive = head is forward of shoulder (in side profile view)
    /// Note: In a front-facing camera side view, "forward" depends on which way user is facing
    func calculateForwardDistance() -> Double? {
        guard let head = headPoint, let shoulder = shoulder else { return nil }
        // Horizontal distance between ear and shoulder
        // The sign indicates direction but we care about magnitude
        return Double(abs(head.x - shoulder.x))
    }
    
    /// Calculate neck angle from vertical (0° = perfect alignment)
    /// Positive angle = head is forward of shoulders
    func calculateNeckAngle() -> Double? {
        guard let head = headPoint, let shoulder = shoulder else { return nil }
        let dx = head.x - shoulder.x
        let dy = shoulder.y - head.y // In UI coords, Y increases downward
        
        // If dy is 0 or negative (head at same level or below shoulder), 
        // the measurement isn't valid for this analysis
        guard dy > 0.01 else { return nil }
        
        // Angle from vertical: atan(horizontal/vertical) * 180/π
        // 0° = ear directly above shoulder (perfect)
        // Positive = ear is forward/ahead of shoulder
        let angleRadians = atan2(Double(abs(dx)), Double(dy))
        return angleRadians * 180.0 / .pi
    }
}

// MARK: - Detection State
enum PostureDetectionState {
    case searching          // Looking for person
    case positioning        // Person found, need better position
    case ready              // Good position, ready to analyze
    case analyzing          // Taking measurement
    case complete           // Analysis done
}

// MARK: - Positioning Guidance
struct PositioningGuidance {
    let message: String
    let isGoodPosition: Bool
    let specificIssue: PositioningIssue?
}

enum PositioningIssue {
    case tooClose
    case tooFar
    case notSideways
    case shoulderNotVisible
    case headNotVisible
    case tooMuchMovement
    
    var instruction: String {
        switch self {
        case .tooClose:
            return "Step back a bit"
        case .tooFar:
            return "Move closer to the camera"
        case .notSideways:
            return "Turn to show your side profile"
        case .shoulderNotVisible:
            return "Make sure your shoulder is visible"
        case .headNotVisible:
            return "Make sure your head is in frame"
        case .tooMuchMovement:
            return "Hold still for measurement"
        }
    }
}
