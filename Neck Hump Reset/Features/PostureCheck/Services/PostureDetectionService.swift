//
//  PostureDetectionService.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import Foundation
import Vision
import AVFoundation
import CoreImage
import Combine

/// Service that uses Apple's Vision framework to detect body pose and analyze neck hump
/// Optimized for SIDE PROFILE view to measure forward head posture
/// All processing happens on-device - no data is sent anywhere
///
/// ## Apple Vision Framework - Coordinate System
///
/// From Apple Documentation (https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images):
///
/// > "Each instance of `VNRecognizedPoint` provides the X and Y coordinates, in normalized space,
/// > and a confidence score for the point."
///
/// > "The points the `recognizedPoints(_:)` method returns are in normalized coordinates (0.0 to 1.0),
/// > with the origin at the bottom-left. Use the `VNImagePointForNormalizedPoint(_:_:_:)` function
/// > to translate the normalized points to the input image coordinates."
///
/// **Key Points:**
/// - Normalized coordinates range from 0.0 to 1.0
/// - Origin is at **BOTTOM-LEFT** of the image
/// - Y increases **upward**, X increases rightward
/// - We convert to UI coordinates (origin top-left) by: `newY = 1.0 - y`
///
/// ## Body Points Detected (19 total)
/// Vision detects: nose, neck, left/right ear, left/right eye, left/right shoulder,
/// left/right elbow, left/right wrist, left/right hip, left/right knee, left/right ankle, root (center)
///
/// For neck hump analysis, we primarily use: ear, shoulder, and optionally hip/nose
///
/// Source: https://developer.apple.com/documentation/vision/vnhumanbodyposeobservation/jointname
@MainActor
class PostureDetectionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPose: SideProfilePose?
    @Published var analysisResult: NeckHumpAnalysisResult?
    @Published var detectionState: PostureDetectionState = .searching
    @Published var positioningGuidance: PositioningGuidance?
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    // For real-time visualization (in UI coordinates - origin top-left)
    @Published var liveEarPoint: CGPoint?
    @Published var liveShoulderPoint: CGPoint?
    @Published var liveHipPoint: CGPoint?
    @Published var liveIdealLine: (start: CGPoint, end: CGPoint)?
    
    // Stability tracking
    private var recentPoses: [SideProfilePose] = []
    private let stabilityThreshold = 5 // Need 5 stable frames
    
    // MARK: - Private Properties
    private var bodyPoseRequest: VNDetectHumanBodyPoseRequest?
    private let analysisQueue = DispatchQueue(label: "posture.analysis", qos: .userInteractive)
    
    // MARK: - Init
    init() {
        setupVision()
    }
    
    private func setupVision() {
        bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    }
    
    // MARK: - Public Methods
    
    /// Analyze a single image for neck hump (final capture)
    func analyzeImage(_ image: CGImage) async {
        isProcessing = true
        errorMessage = nil
        detectionState = .analyzing
        
        do {
            let pose = try await detectSideProfilePose(in: image)
            self.currentPose = pose
            
            if pose.isValid {
                let result = calculateNeckHumpMetrics(from: pose)
                self.analysisResult = result
                self.detectionState = .complete
            } else {
                self.errorMessage = "Could not detect your posture. Please ensure you're standing sideways with head and shoulder visible."
                self.detectionState = .positioning
            }
        } catch {
            self.errorMessage = "Analysis failed: \(error.localizedDescription)"
            self.detectionState = .positioning
        }
        
        isProcessing = false
    }
    
    /// Process live camera frame for real-time feedback
    nonisolated func processLiveFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        Task {
            await processPixelBufferForLiveFeedback(pixelBuffer)
        }
    }
    
    /// Reset the analysis
    func reset() {
        currentPose = nil
        analysisResult = nil
        errorMessage = nil
        detectionState = .searching
        positioningGuidance = nil
        recentPoses.removeAll()
        liveEarPoint = nil
        liveShoulderPoint = nil
        liveHipPoint = nil
        liveIdealLine = nil
    }
    
    // MARK: - Private Methods
    
    private func detectSideProfilePose(in image: CGImage) async throws -> SideProfilePose {
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            guard let request = bodyPoseRequest else {
                continuation.resume(throwing: PostureError.requestNotInitialized)
                return
            }
            
            do {
                try handler.perform([request])
                
                guard let observation = request.results?.first else {
                    continuation.resume(returning: SideProfilePose(ear: nil, shoulder: nil, hip: nil, nose: nil))
                    return
                }
                
                let pose = extractSideProfilePose(from: observation)
                continuation.resume(returning: pose)
                
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processPixelBufferForLiveFeedback(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        guard let request = bodyPoseRequest else { return }
        
        do {
            try handler.perform([request])
            
            if let observation = request.results?.first {
                let pose = extractSideProfilePose(from: observation)
                
                DispatchQueue.main.async { [weak self] in
                    self?.updateLiveFeedback(with: pose)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.detectionState = .searching
                    self?.positioningGuidance = PositioningGuidance(
                        message: "Stand sideways to the camera",
                        isGoodPosition: false,
                        specificIssue: nil
                    )
                }
            }
        } catch {
            print("Live pose detection error: \(error)")
        }
    }
    
    /// Extract pose points from Vision observation
    /// **Important:** Vision uses bottom-left origin, we convert to top-left origin
    /// 
    /// **Side Profile Detection Strategy:**
    /// Apple's Vision is optimized for front-facing poses, so for side profiles we:
    /// 1. Use the ear with higher confidence (the visible one)
    /// 2. Use the shoulder with higher confidence (the visible one)
    /// 3. Fall back to neck point if ears aren't detected well
    /// 4. Use nose as a backup head position reference
    private func extractSideProfilePose(from observation: VNHumanBodyPoseObservation) -> SideProfilePose {
        // Helper to get a point with confidence check
        func getPoint(_ jointName: VNHumanBodyPoseObservation.JointName, minConfidence: Float = 0.1) -> (point: CGPoint, confidence: Float)? {
            guard let point = try? observation.recognizedPoint(jointName),
                  point.confidence > minConfidence else { return nil }
            // Convert from Vision (bottom-left origin) to UI (top-left origin)
            let uiPoint = CGPoint(x: point.location.x, y: 1.0 - point.location.y)
            return (uiPoint, point.confidence)
        }
        
        // === EAR DETECTION ===
        // For side profile, typically only one ear is visible
        var earPoint: CGPoint?
        var earConfidence: Float = 0
        
        let leftEar = getPoint(.leftEar, minConfidence: 0.1)
        let rightEar = getPoint(.rightEar, minConfidence: 0.1)
        
        if let le = leftEar, let re = rightEar {
            // Both detected - use the one with higher confidence
            if le.confidence > re.confidence {
                earPoint = le.point
                earConfidence = le.confidence
            } else {
                earPoint = re.point
                earConfidence = re.confidence
            }
        } else if let le = leftEar {
            earPoint = le.point
            earConfidence = le.confidence
        } else if let re = rightEar {
            earPoint = re.point
            earConfidence = re.confidence
        }
        
        // If ear confidence is low, try using nose as head reference
        let noseData = getPoint(.nose, minConfidence: 0.1)
        var nosePoint: CGPoint?
        if let nose = noseData {
            nosePoint = nose.point
            // If ear wasn't found well, we can still use nose
            if earPoint == nil || earConfidence < 0.3 {
                // Nose is usually more reliably detected
                // For CVA calculation, ear is better, but nose works as fallback
            }
        }
        
        // === SHOULDER DETECTION ===
        // For side profile, one shoulder is more visible
        var shoulderPoint: CGPoint?
        
        let leftShoulder = getPoint(.leftShoulder, minConfidence: 0.1)
        let rightShoulder = getPoint(.rightShoulder, minConfidence: 0.1)
        
        if let ls = leftShoulder, let rs = rightShoulder {
            // Both detected - use the one with higher confidence
            if ls.confidence > rs.confidence {
                shoulderPoint = ls.point
            } else {
                shoulderPoint = rs.point
            }
        } else if let ls = leftShoulder {
            shoulderPoint = ls.point
        } else if let rs = rightShoulder {
            shoulderPoint = rs.point
        }
        
        // Try neck as backup reference point for shoulder area
        if shoulderPoint == nil {
            if let neck = getPoint(.neck, minConfidence: 0.1) {
                // Neck is at base of head - can use as approximate shoulder reference
                // Offset slightly down for better shoulder approximation
                shoulderPoint = CGPoint(x: neck.point.x, y: neck.point.y + 0.05)
            }
        }
        
        // === HIP DETECTION ===
        var hipPoint: CGPoint?
        
        let leftHip = getPoint(.leftHip, minConfidence: 0.1)
        let rightHip = getPoint(.rightHip, minConfidence: 0.1)
        
        if let lh = leftHip, let rh = rightHip {
            if lh.confidence > rh.confidence {
                hipPoint = lh.point
            } else {
                hipPoint = rh.point
            }
        } else if let lh = leftHip {
            hipPoint = lh.point
        } else if let rh = rightHip {
            hipPoint = rh.point
        }
        
        return SideProfilePose(ear: earPoint, shoulder: shoulderPoint, hip: hipPoint, nose: nosePoint)
    }
    
    private func updateLiveFeedback(with pose: SideProfilePose) {
        currentPose = pose
        
        // Update visualization points (already in UI coordinates)
        liveEarPoint = pose.ear
        liveShoulderPoint = pose.shoulder
        liveHipPoint = pose.hip
        
        // Calculate ideal line (vertical from shoulder to ear height)
        if let shoulder = pose.shoulder, let ear = pose.headPoint {
            liveIdealLine = (
                start: shoulder,
                end: CGPoint(x: shoulder.x, y: ear.y)
            )
        }
        
        // Determine positioning guidance
        if !pose.isValid {
            if pose.shoulder == nil {
                detectionState = .positioning
                positioningGuidance = PositioningGuidance(
                    message: "Show your shoulder",
                    isGoodPosition: false,
                    specificIssue: .shoulderNotVisible
                )
            } else if pose.headPoint == nil {
                detectionState = .positioning
                positioningGuidance = PositioningGuidance(
                    message: "Show your head/ear",
                    isGoodPosition: false,
                    specificIssue: .headNotVisible
                )
            }
            recentPoses.removeAll()
            return
        }
        
        // Check stability
        recentPoses.append(pose)
        if recentPoses.count > stabilityThreshold {
            recentPoses.removeFirst()
        }
        
        let isStable = checkStability()
        
        if isStable && pose.isValid {
            detectionState = .ready
            positioningGuidance = PositioningGuidance(
                message: "Perfect! Hold still...",
                isGoodPosition: true,
                specificIssue: nil
            )
        } else if pose.isValid {
            detectionState = .positioning
            positioningGuidance = PositioningGuidance(
                message: "Almost there, hold still...",
                isGoodPosition: false,
                specificIssue: .tooMuchMovement
            )
        }
    }
    
    private func checkStability() -> Bool {
        guard recentPoses.count >= stabilityThreshold else { return false }
        
        // Check if ear and shoulder positions are stable across recent frames
        let earPositions = recentPoses.compactMap { $0.ear }
        let shoulderPositions = recentPoses.compactMap { $0.shoulder }
        
        guard earPositions.count >= stabilityThreshold,
              shoulderPositions.count >= stabilityThreshold else { return false }
        
        // Calculate variance
        let earVariance = calculateVariance(earPositions)
        let shoulderVariance = calculateVariance(shoulderPositions)
        
        // Threshold for "stable" (in normalized coordinates)
        let threshold: CGFloat = 0.02
        
        return earVariance < threshold && shoulderVariance < threshold
    }
    
    private func calculateVariance(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        
        let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        
        let variance = points.map { point in
            let dx = point.x - avgX
            let dy = point.y - avgY
            return dx * dx + dy * dy
        }.reduce(0, +) / CGFloat(points.count)
        
        return sqrt(variance)
    }
    
    private func calculateNeckHumpMetrics(from pose: SideProfilePose) -> NeckHumpAnalysisResult {
        guard let ear = pose.headPoint, let shoulder = pose.shoulder else {
            // Fallback with zeros
            return NeckHumpAnalysisResult(
                forwardHeadDistance: 0,
                neckAngle: 0,
                earPosition: .zero,
                shoulderPosition: .zero
            )
        }
        
        // Calculate forward distance in normalized coordinates
        // We don't convert to cm since we don't know actual distances
        // Instead, we use the angle-based CVA measurement which is scale-independent
        let normalizedForward = pose.calculateForwardDistance() ?? 0
        
        // Estimate distance in cm (rough approximation)
        // Assuming typical frame shows ~50cm width at shoulder level
        let estimatedCm = normalizedForward * 50.0
        
        // Calculate neck angle from vertical
        let neckAngle = pose.calculateNeckAngle() ?? 0
        
        return NeckHumpAnalysisResult(
            forwardHeadDistance: estimatedCm,
            neckAngle: neckAngle,
            earPosition: ear,
            shoulderPosition: shoulder
        )
    }
}

// MARK: - Errors
enum PostureError: LocalizedError {
    case requestNotInitialized
    case noPoseDetected
    case cameraNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .requestNotInitialized:
            return "Pose detection not initialized"
        case .noPoseDetected:
            return "No pose detected in image"
        case .cameraNotAvailable:
            return "Camera is not available"
        }
    }
}
