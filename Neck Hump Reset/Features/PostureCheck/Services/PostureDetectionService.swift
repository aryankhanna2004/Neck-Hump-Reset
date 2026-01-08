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
    
    // ML Kit detector - using singleImage mode for highest accuracy
    private var poseDetector: PoseDetector?
    
    // MARK: - Init
    init() {
        setupDetector()
    }
    
    private func setupDetector() {
        // Use accurate detector with singleImage mode for highest accuracy
        // singleImage mode runs fresh detection on each image (no tracking state)
        let options = AccuratePoseDetectorOptions()
        options.detectorMode = .singleImage
        poseDetector = PoseDetector.poseDetector(options: options)
        
        isModelReady = true
        print("✅ ML Kit Pose Detector initialized (singleImage mode)")
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
                    
                    // Use the facing direction from signal algorithm
                    let facingDirection = pose.facingDirection ?? (ear.x > shoulder.x ? .right : .left)
                    
                    // Start from the original shoulder Y (before any offset)
                    // and scan UP along the body edge to find C7
                    let originalShoulderY = pose.originalShoulderY ?? shoulder.y
                    
                    // Find C7 by scanning up from shoulder along the body back edge
                    // C7 is typically 8-12% of image height above the shoulder
                    if let c7Point = await findC7AlongBodyEdge(
                        in: uiImage,
                        fromShoulderY: originalShoulderY,
                        facingDirection: facingDirection
                    ) {
                        improvedPose.shoulder = c7Point
                        print("📍 Improved C7 using body edge scan: (\(c7Point.x), \(c7Point.y))")
                    }
                    // If body segmentation fails, keep the original C7 estimate from extractSideProfilePose
                }
                
                let result = calculateNeckHumpMetrics(from: improvedPose)
                analysisResult = result
                currentPose = improvedPose
                detectionState = .complete
                print("✅ Pose analysis complete - Facing: \(improvedPose.facingDirection), CVA: \(result.craniovertebralAngle)°")
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
        
        // Recreate detector for fresh state
        setupDetector()
    }
    
    // MARK: - Private Methods
    
    private nonisolated func detectPose(in cgImage: CGImage) async throws -> SideProfilePose {
        let detector = await MainActor.run { self.poseDetector }
        guard let detector = detector else {
            throw PoseError.detectorNotInitialized
        }
        
        // Create UIImage from CGImage
        // Note: After normalization in CameraManager, the image should be in .up orientation
        let uiImage = UIImage(cgImage: cgImage)
        let visionImage = VisionImage(image: uiImage)
        
        // CRITICAL: After normalization, image is always .up orientation
        // ML Kit needs to know the orientation to correctly interpret coordinates
        visionImage.orientation = .up
        
        // CRITICAL: Use CGImage pixel dimensions directly
        // ML Kit returns coordinates in pixel space relative to the CGImage dimensions
        // After normalization, CGImage dimensions are what ML Kit sees
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Debug logging to verify dimensions
        print("📐 Image dimensions for ML Kit:")
        print("   CGImage (pixels): \(cgImage.width)x\(cgImage.height)")
        print("   UIImage size (points): \(uiImage.size.width)x\(uiImage.size.height)")
        print("   UIImage scale: \(uiImage.scale)")
        print("   UIImage pixels (size*scale): \(uiImage.size.width * uiImage.scale)x\(uiImage.size.height * uiImage.scale)")
        print("   Using for coordinate normalization: \(imageSize.width)x\(imageSize.height)")
        print("   Orientation: \(uiImage.imageOrientation.rawValue) (should be 0/.up after normalization)")
        
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
        // Get all landmarks
        let leftEar = pose.landmark(ofType: .leftEar)
        let rightEar = pose.landmark(ofType: .rightEar)
        let leftShoulder = pose.landmark(ofType: .leftShoulder)
        let rightShoulder = pose.landmark(ofType: .rightShoulder)
        let nose = pose.landmark(ofType: .nose)
        let leftEye = pose.landmark(ofType: .leftEye)
        let rightEye = pose.landmark(ofType: .rightEye)
        
        // Log all landmarks with confidence
        print("🔍 Pose Detection:")
        print("   Left ear - X: \(leftEar.position.x), Y: \(leftEar.position.y), Conf: \(leftEar.inFrameLikelihood)")
        print("   Right ear - X: \(rightEar.position.x), Y: \(rightEar.position.y), Conf: \(rightEar.inFrameLikelihood)")
        print("   Left shoulder - X: \(leftShoulder.position.x), Y: \(leftShoulder.position.y), Conf: \(leftShoulder.inFrameLikelihood)")
        print("   Right shoulder - X: \(rightShoulder.position.x), Y: \(rightShoulder.position.y), Conf: \(rightShoulder.inFrameLikelihood)")
        
        // Validity thresholds
        let leftEarValid = leftEar.inFrameLikelihood > 0.3
        let rightEarValid = rightEar.inFrameLikelihood > 0.3
        let leftShoulderValid = leftShoulder.inFrameLikelihood > 0.3
        let rightShoulderValid = rightShoulder.inFrameLikelihood > 0.3
        let noseValid = nose.inFrameLikelihood > 0.3
        let leftEyeValid = leftEye.inFrameLikelihood > 0.3
        let rightEyeValid = rightEye.inFrameLikelihood > 0.3
        
        // === FACING DIRECTION using signal algorithm ===
        var orientationScore: Float = 0.0
        
        // Signal 1: Nose position relative to ears (strongest signal)
        if noseValid && (leftEarValid || rightEarValid) {
            var earMidX: CGFloat = 0
            if leftEarValid && rightEarValid {
                earMidX = (leftEar.position.x + rightEar.position.x) / 2
            } else if leftEarValid {
                earMidX = leftEar.position.x
            } else {
                earMidX = rightEar.position.x
            }
            
            let noseToEarX = nose.position.x - earMidX
            if noseToEarX > 10 {
                orientationScore += 3.0 // Nose to right of ears → facing right
            } else if noseToEarX < -10 {
                orientationScore -= 3.0 // Nose to left of ears → facing left
            }
            print("   📊 Signal: Nose to ears (diff: \(noseToEarX)px) → score: \(orientationScore)")
        }
        
        // Signal 2: Eye positions relative to ears
        if (leftEyeValid || rightEyeValid) && (leftEarValid || rightEarValid) {
            var eyeMidX: CGFloat = 0
            if leftEyeValid && rightEyeValid {
                eyeMidX = (leftEye.position.x + rightEye.position.x) / 2
            } else if leftEyeValid {
                eyeMidX = leftEye.position.x
            } else {
                eyeMidX = rightEye.position.x
            }
            
            var earMidX: CGFloat = 0
            if leftEarValid && rightEarValid {
                earMidX = (leftEar.position.x + rightEar.position.x) / 2
            } else if leftEarValid {
                earMidX = leftEar.position.x
            } else {
                earMidX = rightEar.position.x
            }
            
            let eyeToEarX = eyeMidX - earMidX
            if eyeToEarX > 10 {
                orientationScore += 2.0 // Eyes to right of ears → facing right
            } else if eyeToEarX < -10 {
                orientationScore -= 2.0 // Eyes to left of ears → facing left
            }
            print("   📊 Signal: Eyes to ears (diff: \(eyeToEarX)px) → score: \(orientationScore)")
        }
        
        // Signal 3: Shoulder visibility/confidence difference
        if leftShoulderValid && !rightShoulderValid {
            orientationScore += 1.0 // Only left shoulder visible → facing right
        } else if rightShoulderValid && !leftShoulderValid {
            orientationScore -= 1.0 // Only right shoulder visible → facing left
        } else if leftShoulderValid && rightShoulderValid {
            let confDiff = leftShoulder.inFrameLikelihood - rightShoulder.inFrameLikelihood
            orientationScore += confDiff * 0.5
        }
        print("   📊 Signal: Shoulder visibility → score: \(orientationScore)")
        
        // Signal 4: Ear visibility/confidence difference
        if leftEarValid && !rightEarValid {
            orientationScore += 0.5 // Only left ear visible → facing right
        } else if rightEarValid && !leftEarValid {
            orientationScore -= 0.5 // Only right ear visible → facing left
        }
        print("   📊 Signal: Ear visibility → score: \(orientationScore)")
        
        let facingRight = orientationScore >= 0
        print("📍 Facing direction score: \(orientationScore) → \(facingRight ? "RIGHT" : "LEFT")")
        
        // === EAR SELECTION ===
        // Store BOTH ears for user selection
        let leftEarPoint = leftEarValid ? normalizePoint(leftEar.position, imageSize: imageSize) : nil
        let rightEarPoint = rightEarValid ? normalizePoint(rightEar.position, imageSize: imageSize) : nil
        
        let earConfDiff = abs(leftEar.inFrameLikelihood - rightEar.inFrameLikelihood)
        let earXDiff = abs(leftEar.position.x - rightEar.position.x)
        let earYDiff = abs(leftEar.position.y - rightEar.position.y)
        
        print("   👂 Ear Analysis:")
        print("      Left: X=\(leftEar.position.x), Y=\(leftEar.position.y), Conf=\(leftEar.inFrameLikelihood)")
        print("      Right: X=\(rightEar.position.x), Y=\(rightEar.position.y), Conf=\(rightEar.inFrameLikelihood)")
        print("      Differences: X=\(earXDiff)px, Y=\(earYDiff)px, Conf=\(earConfDiff)")
        
        // Auto-select: use the ear with HIGHER confidence (user can override later)
        var earPoint: CGPoint?
        var earConfidence: Float = 0.0
        var selectedEar: EarSelection? = nil
        
        if leftEar.inFrameLikelihood > rightEar.inFrameLikelihood && leftEarValid {
            earPoint = leftEarPoint
            earConfidence = leftEar.inFrameLikelihood
            selectedEar = .left
            print("📍 Auto-selected LEFT ear (higher confidence: \(leftEar.inFrameLikelihood) > \(rightEar.inFrameLikelihood))")
        } else if rightEarValid {
            earPoint = rightEarPoint
            earConfidence = rightEar.inFrameLikelihood
            selectedEar = .right
            print("📍 Auto-selected RIGHT ear (higher confidence: \(rightEar.inFrameLikelihood) > \(leftEar.inFrameLikelihood))")
        } else if leftEarValid {
            // Fallback: only left ear valid
            earPoint = leftEarPoint
            earConfidence = leftEar.inFrameLikelihood
            selectedEar = .left
            print("📍 Auto-selected LEFT ear (only one valid)")
        }
        
        // === SHOULDER - Just get the raw position, C7 will be found via body segmentation ===
        // Use the shoulder with higher confidence
        var shoulderPoint: CGPoint?
        var shoulderConfidence: Float = 0.0
        var originalShoulderY: CGFloat = 0
        
        let useLeftShoulder = leftShoulder.inFrameLikelihood >= rightShoulder.inFrameLikelihood
        let visibleShoulder = useLeftShoulder ? leftShoulder : rightShoulder
        
        if visibleShoulder.inFrameLikelihood > 0.3 {
            let rawPoint = normalizePoint(visibleShoulder.position, imageSize: imageSize)
            originalShoulderY = rawPoint.y
            
            // Just use the raw shoulder point as initial estimate
            // The actual C7 will be found via body segmentation in analyzeImage
            shoulderPoint = rawPoint
            shoulderConfidence = visibleShoulder.inFrameLikelihood
            print("📍 Using \(useLeftShoulder ? "LEFT" : "RIGHT") shoulder (conf: \(shoulderConfidence))")
        }
        
        let facingDirection: FacingDirection = facingRight ? .right : .left
        
        var result = SideProfilePose(ear: earPoint, shoulder: shoulderPoint, hip: nil, nose: nil)
        result.earConfidence = earConfidence
        result.shoulderConfidence = shoulderConfidence
        result.facingDirection = facingDirection
        result.originalShoulderY = originalShoulderY
        
        // Store both ears for user selection
        result.leftEar = leftEarPoint
        result.rightEar = rightEarPoint
        result.leftEarConfidence = leftEarValid ? leftEar.inFrameLikelihood : 0.0
        result.rightEarConfidence = rightEarValid ? rightEar.inFrameLikelihood : 0.0
        result.selectedEar = selectedEar
        
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
    
    /// Recalculate metrics with a specific ear position
    func calculateNeckHumpMetrics(ear: CGPoint, shoulder: CGPoint, facingDirection: FacingDirection) -> NeckHumpAnalysisResult {
        // Create a temporary pose with the selected ear
        var tempPose = SideProfilePose(ear: ear, shoulder: shoulder, hip: nil, nose: nil)
        tempPose.facingDirection = facingDirection
        return calculateNeckHumpMetrics(from: tempPose)
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
    
    /// Find C7 position by scanning up from shoulder along the body back edge
    /// C7 is at the base of the neck, where the neck meets the upper back
    func findC7AlongBodyEdge(in image: UIImage, fromShoulderY: CGFloat, facingDirection: FacingDirection) async -> CGPoint? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
                
                guard let result = request.results?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let maskBuffer = result.pixelBuffer
                let maskWidth = CVPixelBufferGetWidth(maskBuffer)
                let maskHeight = CVPixelBufferGetHeight(maskBuffer)
                
                CVPixelBufferLockBaseAddress(maskBuffer, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(maskBuffer, .readOnly) }
                
                guard let baseAddress = CVPixelBufferGetBaseAddress(maskBuffer) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let bytesPerRow = CVPixelBufferGetBytesPerRow(maskBuffer)
                let threshold: UInt8 = 128
                
                // Convert normalized Y to mask coordinates
                let shoulderRowInMask = Int(fromShoulderY * CGFloat(maskHeight))
                
                // C7 is only 2-3cm above the shoulder joint
                // In a photo, this is typically 2-3% of image height, not 10%
                // Scan from shoulder up a small amount to find C7 at the base of the neck
                let c7OffsetRows = Int(0.025 * CGFloat(maskHeight)) // 2.5% up from shoulder (much smaller offset)
                let targetRow = max(0, shoulderRowInMask - c7OffsetRows)
                
                print("📍 C7 scan: shoulder at row \(shoulderRowInMask), scanning up \(c7OffsetRows) rows to row \(targetRow)")
                
                // Find the back edge at the target C7 height
                let rowStart = baseAddress.advanced(by: targetRow * bytesPerRow)
                let pixels = rowStart.assumingMemoryBound(to: UInt8.self)
                
                var edgeX: Int? = nil
                
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
                    // C7 is EXACTLY on the body edge - no inward offset
                    // Return normalized coordinates
                    let normalizedX = CGFloat(edge) / CGFloat(maskWidth)
                    let normalizedY = CGFloat(targetRow) / CGFloat(maskHeight)
                    
                    print("📍 C7 on body edge at: X=\(normalizedX), Y=\(normalizedY)")
                    continuation.resume(returning: CGPoint(x: normalizedX, y: normalizedY))
                } else {
                    print("⚠️ Could not find body edge at C7 height")
                    continuation.resume(returning: nil)
                }
                
            } catch {
                print("❌ Person segmentation failed: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
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
