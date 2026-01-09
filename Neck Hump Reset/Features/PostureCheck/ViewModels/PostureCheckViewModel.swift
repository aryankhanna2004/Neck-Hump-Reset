//
//  PostureCheckViewModel.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import Combine
import CoreMedia
import SwiftData
import PhotosUI

@MainActor
class PostureCheckViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: PostureCheckState = .instructions
    @Published var analysisResult: NeckHumpAnalysisResult?
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    
    // Timer settings
    @Published var selectedTimerDuration: Int = 3  // Default 3 seconds
    @Published var countdownValue: Int? = nil
    @Published var isCountingDown: Bool = false
    
    // Available timer options
    let timerOptions = [3, 5, 10]
    
    // Captured image and editable points
    @Published var capturedPhoto: CGImage?
    @Published var capturedPhotoData: Data?
    @Published var editableEarPoint: CGPoint?
    @Published var editableShoulderPoint: CGPoint?
    @Published var isEditingPoints: Bool = false
    @Published var selectedPointToEdit: EditablePoint? = nil
    
    // Both ear positions for user selection
    @Published var leftEarPoint: CGPoint?
    @Published var rightEarPoint: CGPoint?
    @Published var leftEarConfidence: Float = 0.0
    @Published var rightEarConfidence: Float = 0.0
    @Published var selectedEar: EarSelection? = nil
    
    // Confidence tracking
    @Published var detectionConfidence: Float = 0.0
    @Published var isLowConfidence: Bool = false
    @Published var showLowConfidenceWarning: Bool = false
    
    // Save status
    @Published var isSaved: Bool = false
    
    // Photo picker
    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var showPhotoPicker: Bool = false
    
    // MARK: - Services
    let cameraManager = CameraManager()
    let postureService = PostureDetectionService.shared // Use shared pre-initialized instance
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    
    // MARK: - Init
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for captured photos
        cameraManager.$capturedImage
            .compactMap { $0 }
            .sink { [weak self] image in
                self?.capturedPhoto = image
                Task {
                    await self?.analyzeImage(image)
                }
            }
            .store(in: &cancellables)
        
        // Listen for captured photo data (for storage)
        cameraManager.$capturedImageData
            .sink { [weak self] data in
                self?.capturedPhotoData = data
            }
            .store(in: &cancellables)
        
        // Listen for camera errors
        cameraManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startCamera() {
        cameraManager.startSession()
    }
    
    func stopCamera() {
        cameraManager.stopSession()
    }
    
    func flipCamera() {
        cameraManager.flipCamera()
    }
    
    func beginCheck() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentState = .positioning
        }
        postureService.reset()
        capturedPhoto = nil
        capturedPhotoData = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        isSaved = false
        cameraManager.clearCapturedImage()
        startCamera()
    }
    
    func retake() {
        // Clear all state first
        analysisResult = nil
        errorMessage = nil
        countdownValue = nil
        isCountingDown = false
        capturedPhoto = nil
        capturedPhotoData = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        selectedPointToEdit = nil
        isSaved = false
        selectedPhotoItem = nil  // Reset photo picker selection
        detectionConfidence = 0.0
        isLowConfidence = false
        showLowConfidenceWarning = false
        
        // Reset ear selection
        leftEarPoint = nil
        rightEarPoint = nil
        leftEarConfidence = 0.0
        rightEarConfidence = 0.0
        selectedEar = nil
        
        // Reset posture service to clear ML Kit tracking state
        // This recreates the detector for fresh detection
        postureService.reset()
        
        // Clear camera manager state
        cameraManager.clearCapturedImage()
        
        print("🔄 Retake: All state reset, ready for new capture")
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentState = .positioning
        }
    }
    
    func done() {
        stopCamera()
        cancelCountdown()
        
        // Clear all state
        analysisResult = nil
        errorMessage = nil
        capturedPhoto = nil
        capturedPhotoData = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        selectedPointToEdit = nil
        isSaved = false
        selectedPhotoItem = nil  // Reset photo picker selection
        detectionConfidence = 0.0
        isLowConfidence = false
        showLowConfidenceWarning = false
        
        // Reset ear selection
        leftEarPoint = nil
        rightEarPoint = nil
        leftEarConfidence = 0.0
        rightEarConfidence = 0.0
        selectedEar = nil
        
        // Reset posture service to clear ML Kit tracking state
        postureService.reset()
        
        // Clear camera manager state
        cameraManager.clearCapturedImage()
        
        print("🔄 Done: All state reset")
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentState = .instructions
        }
    }
    
    // MARK: - Photo Library Import
    
    func handleSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        // IMPORTANT: Reset everything before processing new photo
        // This ensures we get fresh detection without any cached state
        await MainActor.run {
            // Clear all previous state
            analysisResult = nil
            errorMessage = nil
            capturedPhoto = nil
            capturedPhotoData = nil
            editableEarPoint = nil
            editableShoulderPoint = nil
            isEditingPoints = false
            selectedPointToEdit = nil
            isSaved = false
            detectionConfidence = 0.0
            isLowConfidence = false
            
            // Reset the posture service to clear ML Kit tracking state
            postureService.reset()
            
            // Clear camera manager state
            cameraManager.clearCapturedImage()
            
            // Now transition to analyzing state
            withAnimation {
                currentState = .analyzing
                isAnalyzing = true
            }
            // Clear the selection immediately so picker dismisses
            selectedPhotoItem = nil
            
            print("🔄 State reset complete, ready for new photo analysis")
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Stop camera since we're using an imported photo
                stopCamera()
                
                // Set the image through camera manager (handles orientation)
                // This will trigger the binding and start analysis
                cameraManager.setImage(from: uiImage)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load photo: \(error.localizedDescription)"
                currentState = .positioning
                isAnalyzing = false
            }
        }
    }
    
    // MARK: - Timer-based Capture
    
    func startTimerCapture() {
        guard currentState == .positioning, !isCountingDown else { return }
        
        // If instant (0 seconds), capture immediately
        if selectedTimerDuration == 0 {
            performCapture()
            return
        }
        
        isCountingDown = true
        countdownValue = selectedTimerDuration
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let current = self.countdownValue, current > 1 {
                    self.countdownValue = current - 1
                } else {
                    // Countdown finished, capture!
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.performCapture()
                }
            }
        }
    }
    
    func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownValue = nil
        isCountingDown = false
    }
    
    // MARK: - Save Photo
    
    func savePhoto(modelContext: ModelContext) {
        guard let imageData = capturedPhotoData, let result = analysisResult else {
            print("❌ Cannot save: missing image data or result")
            return
        }
        
        // Use current editable points (which reflect any edits or ear switches)
        // Fall back to result points if editable points aren't available
        let currentEarPoint = editableEarPoint ?? result.earPosition
        let currentShoulderPoint = editableShoulderPoint ?? result.shoulderPosition
        
        // Check if points have changed - if so, recalculate metrics with current points
        let pointsChanged = (currentEarPoint != result.earPosition) || (currentShoulderPoint != result.shoulderPosition)
        
        let finalResult: NeckHumpAnalysisResult
        if pointsChanged, let pose = postureService.currentPose {
            // Recalculate metrics with the current points to ensure accuracy
            finalResult = postureService.calculateNeckHumpMetrics(
                ear: currentEarPoint,
                shoulder: currentShoulderPoint,
                facingDirection: pose.facingDirection
            )
            print("📍 Points changed - recalculated metrics for save")
        } else {
            // Points haven't changed, but ensure we use current points in the saved result
            finalResult = NeckHumpAnalysisResult(
                forwardHeadDistance: result.forwardHeadDistance,
                neckAngle: result.neckAngle,
                earPosition: currentEarPoint,
                shoulderPosition: currentShoulderPoint
            )
        }
        
        let posturePhoto = PosturePhoto(
            imageData: imageData,
            timestamp: Date(),
            result: finalResult
        )
        
        modelContext.insert(posturePhoto)
        
        do {
            try modelContext.save()
            isSaved = true
            print("✅ Photo saved successfully with current points (ear: \(currentEarPoint), shoulder: \(currentShoulderPoint))")
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    // MARK: - Edit Mode Methods
    
    func toggleEditMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isEditingPoints.toggle()
            if !isEditingPoints {
                selectedPointToEdit = nil
            }
        }
    }
    
    func selectPoint(_ point: EditablePoint) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            selectedPointToEdit = point
        }
    }
    
    func updatePointPosition(to newPosition: CGPoint) {
        guard let selectedPoint = selectedPointToEdit else { return }
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            switch selectedPoint {
            case .ear:
                editableEarPoint = newPosition
            case .shoulder:
                editableShoulderPoint = newPosition
            }
        }
    }
    
    func recalculateWithEditedPoints() {
        guard let ear = editableEarPoint, let shoulder = editableShoulderPoint else { return }
        
        // Create new pose with edited points
        let editedPose = SideProfilePose(ear: ear, shoulder: shoulder, hip: nil, nose: nil)
        
        // Recalculate metrics
        let forwardDistance = editedPose.calculateForwardDistance() ?? 0
        let estimatedCm = abs(forwardDistance) * 130
        let neckAngle = editedPose.calculateNeckAngle() ?? 0
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            analysisResult = NeckHumpAnalysisResult(
                forwardHeadDistance: estimatedCm,
                neckAngle: neckAngle,
                earPosition: ear,
                shoulderPosition: shoulder
            )
            isEditingPoints = false
            selectedPointToEdit = nil
            isSaved = false // Mark as unsaved after edit
        }
    }
    
    // MARK: - Private Methods
    
    private func performCapture() {
        withAnimation {
            currentState = .analyzing
            isAnalyzing = true
            countdownValue = nil
            isCountingDown = false
        }
        
        cameraManager.capturePhoto()
    }
    
    private func analyzeImage(_ image: CGImage) async {
        let startTime = Date()
        
        await postureService.analyzeImage(image)
        
        // Ensure minimum 2 seconds on analyzing screen for better UX
        let elapsed = Date().timeIntervalSince(startTime)
        let minimumDuration: TimeInterval = 2.0
        if elapsed < minimumDuration {
            try? await Task.sleep(nanoseconds: UInt64((minimumDuration - elapsed) * 1_000_000_000))
        }
        
        await MainActor.run {
            if let result = postureService.analysisResult {
                self.analysisResult = result
                self.editableEarPoint = result.earPosition
                self.editableShoulderPoint = result.shoulderPosition
                
                // Store both ears for user selection
                if let pose = postureService.currentPose {
                    self.leftEarPoint = pose.leftEar
                    self.rightEarPoint = pose.rightEar
                    self.leftEarConfidence = pose.leftEarConfidence
                    self.rightEarConfidence = pose.rightEarConfidence
                    self.selectedEar = pose.selectedEar
                    
                    self.detectionConfidence = pose.overallConfidence
                    self.isLowConfidence = !pose.isHighConfidence
                    self.showLowConfidenceWarning = !pose.isHighConfidence
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.currentState = .results
                }
            } else if let error = postureService.errorMessage {
                self.errorMessage = error
                self.currentState = .positioning
            }
            self.isAnalyzing = false
        }
    }
    
    func dismissLowConfidenceWarning() {
        showLowConfidenceWarning = false
    }
    
    func retakeForBetterDetection() {
        showLowConfidenceWarning = false
        retake()
    }
    
    // MARK: - Ear Selection
    
    func switchToLeftEar() {
        guard let leftEar = leftEarPoint else { return }
        selectedEar = .left
        editableEarPoint = leftEar
        recalculateWithSelectedEar()
    }
    
    func switchToRightEar() {
        guard let rightEar = rightEarPoint else { return }
        selectedEar = .right
        editableEarPoint = rightEar
        recalculateWithSelectedEar()
    }
    
    private func recalculateWithSelectedEar() {
        guard let selectedEar = selectedEar,
              let pose = postureService.currentPose else { return }
        
        // Update the pose with selected ear
        var updatedPose = pose
        let newEarPoint: CGPoint?
        let newEarConfidence: Float
        
        switch selectedEar {
        case .left:
            newEarPoint = pose.leftEar
            newEarConfidence = pose.leftEarConfidence
        case .right:
            newEarPoint = pose.rightEar
            newEarConfidence = pose.rightEarConfidence
        }
        
        updatedPose.selectedEar = selectedEar
        // Note: We can't directly modify the ear property as it's let, so we'll recalculate from the service
        
        // Recalculate metrics with the selected ear
        if let newEar = newEarPoint, let shoulder = editableShoulderPoint {
            let result = postureService.calculateNeckHumpMetrics(
                ear: newEar,
                shoulder: shoulder,
                facingDirection: pose.facingDirection
            )
            analysisResult = result
        }
    }
}

// MARK: - State
enum PostureCheckState {
    case instructions
    case positioning
    case analyzing
    case results
}

// MARK: - Editable Point
enum EditablePoint: String, CaseIterable {
    case ear = "Ear"
    case shoulder = "Shoulder"
    
    var color: Color {
        switch self {
        case .ear: return .cyan
        case .shoulder: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .ear: return "ear"
        case .shoulder: return "figure.arms.open"
        }
    }
}
