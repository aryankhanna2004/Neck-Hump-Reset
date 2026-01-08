//
//  PostureDetectionService.swift
//  Neck Hump Reset
//
//  Pose detection service using Google ML Kit
//

import Foundation
import AVFoundation
import UIKit
import Combine
import MLKitPoseDetectionAccurate
import MLKitPoseDetectionCommon
import MLKitVision
import Vision

/// Pose detection service using Google ML Kit
/// ML Kit is more accurate for side-profile poses than Apple's Vision framework
///
/// ## Why ML Kit for Side Profiles?
/// - Trained on more diverse pose angles
/// - Better landmark detection from various camera positions
/// - Provides 33 body landmarks (vs 19 in Apple Vision)
/// - More reliable confidence scores
///
/// ## Landmarks for Neck Hump Analysis
/// - leftEar / rightEar (PoseLandmarkType.leftEar / .rightEar)
/// - leftShoulder / rightShoulder
/// - nose
/// - leftHip / rightHip
@MainActor
class PostureDetectionService: ObservableObject {
    
    // MARK: - Shared Instance for Pre-initialization
    static let shared = PostureDetectionService()
    
    // Track if model is ready
    @Published var isModelReady: Bool = false
    
    // MARK: - Published Properties
    @Published var currentPose: SideProfilePose?
    @Published var analysisResult: NeckHumpAnalysisResult?
    @Published var detectionState: PostureDetectionState = .searching
    @Published var positioningGuidance: PositioningGuidance?
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    // For real-time visualization
    @Published var liveEarPoint: CGPoint?
    @Published var liveShoulderPoint: CGPoint?
    @Published var liveHipPoint: CGPoint?
    @Published var liveIdealLine: (start: CGPoint, end: CGPoint)?
    
    // Stability tracking
    private var recentPoses: [SideProfilePose] = []
    private let stabilityThreshold = 5
    
    // ML Kit detector
    private var poseDetector: PoseDetector?
    
    // MARK: - Init
    init() {
        setupDetector()
    }
    
    private func setupDetector() {
        // Use accurate detector with stream mode for real-time processing
        let options = AccuratePoseDetectorOptions()
        options.detectorMode = .stream
        
        poseDetector = PoseDetector.poseDetector(options: options)
        isModelReady = true
        print("✅ ML Kit Pose Detector initialized")
    }
    
    /// Pre-warm the model by running a dummy detection
    /// Call this during app startup to load model weights into memory
    /// IMPORTANT: ML Kit detection MUST run on a background thread
    func preWarmModel() async {
        guard let detector = poseDetector else { return }
        
        print("🔥 Pre-warming ML Kit model...")
        
        // Run on background thread - ML Kit requires this
        await Task.detached {
            // Create a small dummy image for warm-up
            let size = CGSize(width: 100, height: 100)
            UIGraphicsBeginImageContext(size)
            UIColor.gray.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let dummyImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let cgImage = dummyImage?.cgImage else {
                print("⚠️ Failed to create dummy image for warm-up")
                return
            }
            
            // Run detection on the dummy image to load model weights
            let visionImage = VisionImage(image: UIImage(cgImage: cgImage))
            visionImage.orientation = .up
            
            do {
                _ = try detector.results(in: visionImage)
                print("✅ ML Kit model pre-warmed successfully")
            } catch {
                print("⚠️ Model warm-up detection failed (this is okay): \(error.localizedDescription)")
            }
        }.value
    }
    
    // MARK: - Public Methods
    
    /// Analyze a captured image
    func analyzeImage(_ image: CGImage) async {
        isProcessing = true
        detectionState = .analyzing
        
        do {
            // Run detection on background thread
            let pose = try await Task.detached { [weak self] in
                try await self?.detectPose(in: image)
            }.value ?? SideProfilePose(ear: nil, shoulder: nil, hip: nil, nose: nil)
            
            if pose.isValid {
                // Try to improve C7 estimation using body segmentation
                var improvedPose = pose
                if let shoulder = pose.shoulder, let ear = pose.ear {
                    let uiImage = UIImage(cgImage: image)
                    
                    // Determine facing direction based on ear position relative to shoulder
                    // If ear is to the right of shoulder, person is facing right
                    let facingDirection: FacingDirection = ear.x > shoulder.x ? .right : .left
                    
                    // Find the back edge of the body at shoulder height
                    if let backEdgeX = await findBodyBackEdge(in: uiImage, atNormalizedY: shoulder.y, facingDirection: facingDirection) {
                        // C7 is at the back edge of the body, at shoulder height
                        // Move slightly inward from the edge (the edge is the skin, C7 is slightly inside)
                        let c7Offset: CGFloat = 0.01 // 1% inward from edge
                        let c7X: CGFloat
                        switch facingDirection {
                        case .right:
                            c7X = backEdgeX + c7Offset // Move right from left edge
                        case .left:
                            c7X = backEdgeX - c7Offset // Move left from right edge
                        }
                        
                        // C7 is typically at or slightly above shoulder height
                        let c7Y = shoulder.y - 0.01 // Slightly above shoulder
                        
                        improvedPose.shoulder = CGPoint(x: c7X, y: c7Y)
                        print("📍 Improved C7 estimate using body segmentation: (\(c7X), \(c7Y))")
                    }
                }
                
                let result = calculateNeckHumpMetrics(from: improvedPose)
                analysisResult = result
                currentPose = improvedPose
                detectionState = .complete
                print("✅ Pose analysis complete - CVA: \(result.craniovertebralAngle)°")
            } else {
                errorMessage = "Could not detect pose. Please ensure your side profile is visible."
                detectionState = .positioning
            }
        } catch {
            errorMessage = "Pose detection failed: \(error.localizedDescription)"
            detectionState = .searching
        }
        
        isProcessing = false
    }
    
    /// Process live camera frame for real-time feedback
    nonisolated func processLiveFrame(_ sampleBuffer: CMSampleBuffer) {
        // ML Kit MUST be called on a background thread
        Task.detached { [weak self] in
            await self?.processLiveFrameAsync(sampleBuffer)
        }
    }
    
    private nonisolated func processLiveFrameAsync(_ sampleBuffer: CMSampleBuffer) async {
        // Check if already processing on main actor
        let shouldSkip = await MainActor.run { self.isProcessing }
        guard !shouldSkip else { return }
        
        // Get device orientation on main actor
        let deviceOrientation = await MainActor.run { UIDevice.current.orientation }
        let detector = await MainActor.run { self.poseDetector }
        
        // Get image dimensions from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        
        // Create VisionImage from sample buffer
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = imageOrientation(
            deviceOrientation: deviceOrientation,
            cameraPosition: .front
        )
        
        do {
            guard let detector = detector else { return }
            // This runs on background thread as required by ML Kit
            let poses = try detector.results(in: visionImage)
            
            if let firstPose = poses.first {
                // Pass actual image size for proper coordinate normalization
                let sideProfilePose = extractSideProfilePose(from: firstPose, imageSize: imageSize)
                // Update UI on main actor
                await MainActor.run {
                    self.updateLiveFeedback(with: sideProfilePose)
                }
            } else {
                await MainActor.run {
                    self.detectionState = .searching
                    self.positioningGuidance = PositioningGuidance(
                        message: "Stand sideways to the camera",
                        isGoodPosition: false,
                        specificIssue: nil
                    )
                }
            }
        } catch {
            print("ML Kit pose detection error: \(error)")
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
    
    private nonisolated func detectPose(in cgImage: CGImage) async throws -> SideProfilePose {
        let detector = await MainActor.run { self.poseDetector }
        guard let detector = detector else {
            throw PoseError.detectorNotInitialized
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        let visionImage = VisionImage(image: uiImage)
        visionImage.orientation = .up
        
        // Get image size for coordinate normalization
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Run ML Kit on background thread
        let poses = try detector.results(in: visionImage)
        
        guard let firstPose = poses.first else {
            return SideProfilePose(ear: nil, shoulder: nil, hip: nil, nose: nil)
        }
        
        return extractSideProfilePose(from: firstPose, imageSize: imageSize)
    }
    
    /// Extract pose points from ML Kit Pose
    /// ML Kit uses image coordinates, we convert to normalized 0-1 coordinates
    private nonisolated func extractSideProfilePose(from pose: Pose, imageSize: CGSize = CGSize(width: 1, height: 1)) -> SideProfilePose {
        // For side profile, use the ear with higher confidence
        var earPoint: CGPoint?
        var earConfidence: Float = 0.0
        let leftEar = pose.landmark(ofType: .leftEar)
        let rightEar = pose.landmark(ofType: .rightEar)
        
        // Pick the ear that's more visible (higher confidence)
        if leftEar.inFrameLikelihood > rightEar.inFrameLikelihood && leftEar.inFrameLikelihood > 0.3 {
            earPoint = normalizePoint(leftEar.position, imageSize: imageSize)
            earConfidence = leftEar.inFrameLikelihood
            print("📍 Using left ear (confidence: \(leftEar.inFrameLikelihood))")
        } else if rightEar.inFrameLikelihood > 0.3 {
            earPoint = normalizePoint(rightEar.position, imageSize: imageSize)
            earConfidence = rightEar.inFrameLikelihood
            print("📍 Using right ear (confidence: \(rightEar.inFrameLikelihood))")
        }
        
        // For C7 estimation in side profile:
        // ML Kit detects shoulder joints (acromion), but CVA research uses C7 vertebra
        // C7 is at the base of the neck - in a side profile, it's roughly:
        // - At the same X position as the visible shoulder (or slightly toward center of body)
        // - At approximately shoulder height
        //
        // Since we can't detect C7 directly, we estimate it from the visible shoulder
        // and allow the user to manually adjust if needed.
        var shoulderPoint: CGPoint?
        var shoulderConfidence: Float = 0.0
        let leftShoulder = pose.landmark(ofType: .leftShoulder)
        let rightShoulder = pose.landmark(ofType: .rightShoulder)
        
        let leftShoulderValid = leftShoulder.inFrameLikelihood > 0.3
        let rightShoulderValid = rightShoulder.inFrameLikelihood > 0.3
        
        // Determine which side the person is facing based on ear visibility
        let facingLeft = leftEar.inFrameLikelihood > rightEar.inFrameLikelihood
        
        if leftShoulderValid && rightShoulderValid {
            // Both shoulders visible - estimate C7 as midpoint between shoulders, moved up
            let leftPoint = normalizePoint(leftShoulder.position, imageSize: imageSize)
            let rightPoint = normalizePoint(rightShoulder.position, imageSize: imageSize)
            
            let midX = (leftPoint.x + rightPoint.x) / 2
            let midY = (leftPoint.y + rightPoint.y) / 2
            let shoulderWidth = abs(rightPoint.x - leftPoint.x)
            let c7OffsetY = shoulderWidth * 0.12 // Move up slightly
            
            shoulderPoint = CGPoint(x: midX, y: midY - c7OffsetY)
            shoulderConfidence = min(leftShoulder.inFrameLikelihood, rightShoulder.inFrameLikelihood)
            print("📍 Estimated C7 from both shoulders (confidence: \(shoulderConfidence))")
        } else if leftShoulderValid || rightShoulderValid {
            // Only one shoulder visible (typical side profile)
            // Use the visible shoulder but adjust toward where C7 would be
            let visibleShoulder = leftShoulderValid ? leftShoulder : rightShoulder
            let rawPoint = normalizePoint(visibleShoulder.position, imageSize: imageSize)
            
            // C7 is more toward the center of the body than the shoulder joint
            // In a side profile facing right: C7 is to the LEFT of the visible (left) shoulder
            // In a side profile facing left: C7 is to the RIGHT of the visible (right) shoulder
            // We shift the X position slightly toward the center (toward where the spine would be)
            
            // Estimate: C7 is about 8-12% of image width toward center from shoulder
            let c7ShiftX: CGFloat = 0.08 // 8% shift toward body center
            
            var adjustedX = rawPoint.x
            if leftShoulderValid {
                // Left shoulder visible - person likely facing right
                // C7 is to the right of the left shoulder (toward center)
                adjustedX = rawPoint.x + c7ShiftX
            } else {
                // Right shoulder visible - person likely facing left
                // C7 is to the left of the right shoulder (toward center)
                adjustedX = rawPoint.x - c7ShiftX
            }
            
            // C7 is also slightly higher than the shoulder joint
            // Angle slightly upward (~95° instead of 90° horizontal)
            // This means moving up more than just straight horizontal
            let adjustedY = rawPoint.y - 0.06 // Move up 6% (angled upward ~5°)
            
            shoulderPoint = CGPoint(x: adjustedX, y: adjustedY)
            shoulderConfidence = visibleShoulder.inFrameLikelihood
            print("📍 Estimated C7 from single shoulder, adjusted toward spine (confidence: \(shoulderConfidence))")
        }
        
        // Hip - for posture reference
        var hipPoint: CGPoint?
        let leftHip = pose.landmark(ofType: .leftHip)
        let rightHip = pose.landmark(ofType: .rightHip)
        
        if leftHip.inFrameLikelihood > rightHip.inFrameLikelihood && leftHip.inFrameLikelihood > 0.3 {
            hipPoint = normalizePoint(leftHip.position, imageSize: imageSize)
        } else if rightHip.inFrameLikelihood > 0.3 {
            hipPoint = normalizePoint(rightHip.position, imageSize: imageSize)
        }
        
        // Nose - can be used as head reference
        var nosePoint: CGPoint?
        let nose = pose.landmark(ofType: .nose)
        if nose.inFrameLikelihood > 0.3 {
            nosePoint = normalizePoint(nose.position, imageSize: imageSize)
        }
        
        var result = SideProfilePose(ear: earPoint, shoulder: shoulderPoint, hip: hipPoint, nose: nosePoint)
        result.earConfidence = earConfidence
        result.shoulderConfidence = shoulderConfidence
        return result
    }
    
    /// Normalize ML Kit coordinates to 0-1 range
    private nonisolated func normalizePoint(_ position: Vision3DPoint, imageSize: CGSize) -> CGPoint {
        // ML Kit provides coordinates in image space
        // Normalize to 0-1 range for consistent display
        let x = position.x / imageSize.width
        let y = position.y / imageSize.height
        return CGPoint(x: x, y: y)
    }
    
    private func updateLiveFeedback(with pose: SideProfilePose) {
        currentPose = pose
        
        // Update visualization points
        liveEarPoint = pose.ear
        liveShoulderPoint = pose.shoulder
        liveHipPoint = pose.hip
        
        // Calculate ideal line (vertical from shoulder)
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
        
        let earPositions = recentPoses.compactMap { $0.ear }
        let shoulderPositions = recentPoses.compactMap { $0.shoulder }
        
        guard earPositions.count >= stabilityThreshold,
              shoulderPositions.count >= stabilityThreshold else { return false }
        
        let earVariance = calculateVariance(earPositions)
        let shoulderVariance = calculateVariance(shoulderPositions)
        
        let threshold: CGFloat = 0.02
        return earVariance < threshold && shoulderVariance < threshold
    }
    
    private func calculateVariance(_ points: [CGPoint]) -> CGFloat {
        guard !points.isEmpty else { return 0 }
        
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
            return NeckHumpAnalysisResult(
                forwardHeadDistance: 0,
                neckAngle: 0,
                earPosition: CGPoint.zero,
                shoulderPosition: CGPoint.zero
            )
        }
        
        let forwardDistance = pose.calculateForwardDistance() ?? 0
        let estimatedCm = abs(forwardDistance) * 130
        let neckAngle = pose.calculateNeckAngle() ?? 0
        
        return NeckHumpAnalysisResult(
            forwardHeadDistance: estimatedCm,
            neckAngle: neckAngle,
            earPosition: ear,
            shoulderPosition: shoulder
        )
    }
    
    /// Get image orientation for ML Kit based on device orientation
    private nonisolated func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            return .up
        }
    }
    
    // MARK: - Body Segmentation for C7 Estimation
    
    /// Find the back edge of the body at a given Y position using person segmentation
    /// This helps estimate C7 position more accurately regardless of zoom level
    func findBodyBackEdge(in image: UIImage, atNormalizedY: CGFloat, facingDirection: FacingDirection) async -> CGFloat? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced // Good balance of speed and accuracy
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
                
                guard let result = request.results?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let maskBuffer = result.pixelBuffer
                
                // Convert pixel buffer to find the edge
                let maskWidth = CVPixelBufferGetWidth(maskBuffer)
                let maskHeight = CVPixelBufferGetHeight(maskBuffer)
                
                // Calculate the row to scan (Y position in mask coordinates)
                let rowToScan = Int(atNormalizedY * CGFloat(maskHeight))
                let clampedRow = max(0, min(maskHeight - 1, rowToScan))
                
                CVPixelBufferLockBaseAddress(maskBuffer, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(maskBuffer, .readOnly) }
                
                guard let baseAddress = CVPixelBufferGetBaseAddress(maskBuffer) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let bytesPerRow = CVPixelBufferGetBytesPerRow(maskBuffer)
                let rowStart = baseAddress.advanced(by: clampedRow * bytesPerRow)
                let pixels = rowStart.assumingMemoryBound(to: UInt8.self)
                
                // Find the edge based on facing direction
                // If facing right, we want the LEFT edge (back of body)
                // If facing left, we want the RIGHT edge (back of body)
                var edgeX: Int? = nil
                let threshold: UInt8 = 128 // Pixel is part of person if > threshold
                
                switch facingDirection {
                case .right:
                    // Scan from left to find first person pixel (back edge)
                    for x in 0..<maskWidth {
                        if pixels[x] > threshold {
                            edgeX = x
                            break
                        }
                    }
                case .left:
                    // Scan from right to find first person pixel (back edge)
                    for x in stride(from: maskWidth - 1, through: 0, by: -1) {
                        if pixels[x] > threshold {
                            edgeX = x
                            break
                        }
                    }
                }
                
                if let edge = edgeX {
                    // Return normalized X position
                    let normalizedX = CGFloat(edge) / CGFloat(maskWidth)
                    print("📍 Body back edge found at normalized X: \(normalizedX)")
                    continuation.resume(returning: normalizedX)
                } else {
                    continuation.resume(returning: nil)
                }
                
            } catch {
                print("❌ Person segmentation failed: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    enum FacingDirection {
        case left
        case right
    }
}

// MARK: - Errors
enum PoseError: LocalizedError {
    case detectorNotInitialized
    case noPersonDetected
    case insufficientLandmarks
    
    var errorDescription: String? {
        switch self {
        case .detectorNotInitialized:
            return "Pose detector not initialized"
        case .noPersonDetected:
            return "No person detected in the image"
        case .insufficientLandmarks:
            return "Could not detect enough body landmarks"
        }
    }
}
