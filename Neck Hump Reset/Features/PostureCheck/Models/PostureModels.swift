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
///
/// **Primary Source - Titcomb et al. (2024):**
/// "Evaluation of the Craniovertebral Angle in Standing versus Sitting Positions
///  in Young Adults with and without Severe Forward Head Posture"
/// International Journal of Exercise Science, 17(1):73-85
/// DOI: 10.70252/GDNN4363 | PMCID: PMC11042887 | PMID: 38665167
///
/// **Key Findings from Titcomb et al.:**
/// - Normal posture: CVA > 53° (NORM group mean: 56.6 ± 2.7° standing)
/// - Severe FHP: CVA < 45° (SEV group mean: 41.2 ± 3.2° standing)
/// - Overall mean CVA: 50.0 ± 5.2° (standing), 47.8 ± 5.7° (sitting)
/// - Standing position recommended for standardized CVA assessment
///
/// **Thresholds used in this app (based on research):**
/// - CVA > 53°: Normal/Minimal - Great posture
/// - CVA 45-53°: Mild FHP - Slightly forward head position
/// - CVA 40-45°: Moderate FHP - Noticeable forward head
/// - CVA < 40°: Severe FHP - Significant forward head posture
///
/// **Additional Sources:**
/// - Singla D, Veqar Z. "Association between forward head, rounded shoulders,
///   and increased thoracic kyphosis" J Chiropr Med. 2017;16(3):220-229
/// - Shaghayegh Fard B, et al. "Evaluation of forward head posture in sitting
///   and standing positions" Eur Spine J. 2016;25(11):3577-3582
///
/// **ML Kit Pose Detection:**
/// This app uses Google ML Kit for pose landmark detection (ear, shoulder positions)
/// ML Kit provides normalized coordinates (0.0 to 1.0) with origin at top-left
///
/// **C7 Vertebra Estimation (Important):**
/// - ML Kit detects the tragus (ear) position accurately ✓
/// - ML Kit detects shoulder joints (acromion), NOT the C7 vertebra ✗
/// - We use Apple's VNGeneratePersonSegmentationRequest to find the back edge of the body
/// - C7 is estimated as the back edge of the body at shoulder height
/// - This approach works regardless of zoom level or camera distance
/// - Users can manually adjust the "S" point for even better accuracy

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
        
        // CVA (Craniovertebral Angle) is now calculated directly in calculateNeckAngle()
        // It's the angle between horizontal through shoulder and line to ear
        // Perfect posture: ear directly above shoulder = CVA of 90°
        // Forward head: ear in front of shoulder = CVA decreases (e.g., 44° in severe FHP)
        self.craniovertebralAngle = neckAngle
        
        // Determine severity based on CVA (research-backed thresholds from Titcomb et al. 2024)
        // CVA > 53°: Normal (NORM group had mean 56.6°)
        // CVA 45-53°: Mild FHP (between normal and severe thresholds)
        // CVA 40-45°: Moderate FHP (approaching severe)
        // CVA < 45°: Severe FHP (SEV group had mean 41.2°, threshold < 45°)
        if craniovertebralAngle >= 53 {
            self.humpSeverity = .minimal
            // Score 85-100 based on how close to ideal (CVA ~57° is excellent)
            self.overallScore = min(100, Int(85 + (craniovertebralAngle - 53) * 2.5))
        } else if craniovertebralAngle >= 45 {
            self.humpSeverity = .mild
            // Score 60-84
            self.overallScore = Int(60 + (craniovertebralAngle - 45) * 3)
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
        case .mild: return "Slightly Forward"
        case .moderate: return "Noticeably Forward"
        case .severe: return "Very Forward"
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
    
    /// Research-backed CVA threshold for this severity (Titcomb et al. 2024)
    var cvaThreshold: String {
        switch self {
        case .minimal: return "CVA > 53°"
        case .mild: return "CVA 45-53°"
        case .moderate: return "CVA 40-45°"
        case .severe: return "CVA < 40°"
        }
    }
    
    var description: String {
        switch self {
        case .minimal:
            return "Your head is well-aligned over your shoulders. Nice work — keep it up!"
        case .mild:
            return "Your head is slightly forward of your shoulders. This is very common and can often be improved with regular practice."
        case .moderate:
            return "Your head is noticeably forward of your shoulders. Many people see improvement with consistent daily exercises."
        case .severe:
            return "Your head appears quite far forward of your shoulders. We recommend consulting a qualified professional for personalized guidance in addition to using this app."
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
                "Consider consulting a qualified professional for personalized guidance",
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
enum EarSelection: String, CaseIterable {
    case left = "Left Ear"
    case right = "Right Ear"
}

struct SideProfilePose {
    // Key points for side view analysis (already converted to UI coordinates)
    let ear: CGPoint?           // Ear position (represents head position) - selected ear
    var shoulder: CGPoint?      // Shoulder/C7 position (can be adjusted by segmentation)
    let hip: CGPoint?           // Hip position (for full posture context)
    let nose: CGPoint?          // Nose (backup for head position)
    
    // Both ear positions for user selection
    var leftEar: CGPoint?
    var rightEar: CGPoint?
    var leftEarConfidence: Float = 0.0
    var rightEarConfidence: Float = 0.0
    var selectedEar: EarSelection? // User-selected ear (nil = auto-selected)
    
    // Confidence scores (0.0 - 1.0)
    var earConfidence: Float = 0.0
    var shoulderConfidence: Float = 0.0
    
    // Facing direction - needed for correct CVA calculation
    var facingDirection: FacingDirection = .right
    
    // Original shoulder Y position before C7 offset (used for body segmentation)
    var originalShoulderY: CGFloat?
    
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
    
    /// Overall confidence score (average of ear and shoulder)
    var overallConfidence: Float {
        let earConf = ear != nil ? earConfidence : 0.0
        let shoulderConf = shoulder != nil ? shoulderConfidence : 0.0
        return (earConf + shoulderConf) / 2.0
    }
    
    /// Whether the detection is confident enough for accurate analysis
    var isHighConfidence: Bool {
        return earConfidence >= 0.6 && shoulderConfidence >= 0.6
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
    
    /// Calculate CVA (Craniovertebral Angle)
    /// CVA = angle between horizontal line through C7 and line to ear
    /// Higher angle = better posture (90° = perfect, ear directly above shoulder)
    /// Lower angle = worse posture (forward head position)
    func calculateNeckAngle() -> Double? {
        guard let head = headPoint, let shoulder = shoulder else { return nil }
        let dx = head.x - shoulder.x
        let dy = shoulder.y - head.y // In UI coords, Y increases downward
        
        // If dy is 0 or negative (head at same level or below shoulder), 
        // the measurement isn't valid for this analysis
        guard dy > 0.01 else { return nil }
        
        // Calculate the "forward" distance based on facing direction
        // IMPORTANT: In side profile photos, "forward" means head is forward relative to C7
        // For CVA: we want the horizontal distance component for the angle calculation
        // The sign tells us direction, but for angle calculation we need the magnitude
        // 
        // When facing RIGHT: 
        //   - If ear is to RIGHT of C7 (dx > 0): head is forward (bad) → use positive
        //   - If ear is to LEFT of C7 (dx < 0): head is back (good) → use negative
        // When facing LEFT:
        //   - If ear is to LEFT of C7 (dx < 0): head is forward (bad) → negate to make positive
        //   - If ear is to RIGHT of C7 (dx > 0): head is back (good) → negate to make negative
        let forwardDistance: Double
        switch facingDirection {
        case .right:
            // Facing right: forward = ear has higher X than C7
            // Use dx as-is: positive = forward (bad), negative = back (good)
            forwardDistance = Double(dx)
        case .left:
            // Facing left: forward = ear has lower X than C7
            // Negate dx: if dx is negative (ear left of C7), negate to positive (forward)
            forwardDistance = Double(-dx)
        }
        
        // Debug: Check if interpretation might be inverted
        // If user says good posture but forwardDistance is positive, we might need to invert
        print("   📍 Direction check: dx=\(dx), facing=\(facingDirection), forwardDistance=\(forwardDistance)")
        print("   📍 Interpretation: \(forwardDistance > 0 ? "FORWARD (bad)" : forwardDistance < 0 ? "BACK (good)" : "ALIGNED")")
        
        // CVA (Craniovertebral Angle) calculation:
        // CVA = angle between horizontal line through C7 and line from C7 to ear
        // 
        // Using atan2(vertical, horizontal):
        // - atan2(dy, forwardDistance) gives angle from horizontal (0°) counterclockwise
        // - Perfect posture (ear directly above C7): forwardDistance ≈ 0 → angle ≈ 90°
        // - Forward head posture: forwardDistance > 0 → angle < 90° (e.g., 44° = severe FHP)
        //
        // Example: If ear is forward by 0.2 and above by 0.2:
        //   angle = atan2(0.2, 0.2) = 45° (forward head posture)
        //
        // If head is behind shoulder (forwardDistance < 0), that's excellent posture
        // We cap it at 90° for the CVA metric
        if forwardDistance <= 0 {
            // Head is at or behind shoulder - excellent posture
            // Return angle close to 90° (or slightly more)
            let angleRadians = atan2(Double(dy), max(0.001, abs(forwardDistance)))
            return min(90.0, angleRadians * 180.0 / .pi)
        }
        
        // Head is forward of shoulder - calculate actual CVA
        // This is the standard CVA measurement: angle from horizontal to ear-shoulder line
        // IMPORTANT: Use absolute value of horizontal distance for angle calculation
        // The direction (forward/back) doesn't affect the angle itself, only whether it's good/bad
        let horizontalDistance = abs(forwardDistance)
        let angleRadians = atan2(Double(dy), horizontalDistance)
        let angleDegrees = angleRadians * 180.0 / .pi
        
        // Debug logging
        print("📐 CVA Calculation Debug:")
        print("   Ear: (\(head.x), \(head.y))")
        print("   C7: (\(shoulder.x), \(shoulder.y))")
        print("   dx: \(dx), dy: \(dy)")
        print("   Facing: \(facingDirection), forwardDistance: \(forwardDistance)")
        print("   Horizontal distance (abs): \(horizontalDistance)")
        print("   Raw angle: \(angleDegrees)°")
        
        // Verify: angle should be between 0° and 90°
        // 0° = head completely forward (worst)
        // 90° = head directly above shoulder (best)
        let finalAngle = max(0.0, min(90.0, angleDegrees))
        print("   Final CVA: \(finalAngle)°")
        print("   Posture assessment: \(forwardDistance > 0 ? "FORWARD head (bad)" : forwardDistance < 0 ? "BACK head (good)" : "ALIGNED (perfect)")")
        return finalAngle
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

// MARK: - Facing Direction
enum FacingDirection {
    case left
    case right
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
