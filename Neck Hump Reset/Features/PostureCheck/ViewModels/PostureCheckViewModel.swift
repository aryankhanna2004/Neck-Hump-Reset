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
        analysisResult = nil
        errorMessage = nil
        postureService.reset()
        countdownValue = nil
        isCountingDown = false
        capturedPhoto = nil
        capturedPhotoData = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        selectedPointToEdit = nil
        isSaved = false
        cameraManager.clearCapturedImage()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentState = .positioning
        }
    }
    
    func done() {
        stopCamera()
        cancelCountdown()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentState = .instructions
        }
        analysisResult = nil
        postureService.reset()
        capturedPhoto = nil
        capturedPhotoData = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        isSaved = false
        cameraManager.clearCapturedImage()
    }
    
    // MARK: - Photo Library Import
    
    func handleSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Stop camera since we're using an imported photo
                stopCamera()
                
                // Set the image through camera manager (handles orientation)
                cameraManager.setImage(from: uiImage)
                
                // Transition to analyzing state
                await MainActor.run {
                    withAnimation {
                        currentState = .analyzing
                        isAnalyzing = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load photo: \(error.localizedDescription)"
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
        
        let posturePhoto = PosturePhoto(
            imageData: imageData,
            timestamp: Date(),
            result: result
        )
        
        modelContext.insert(posturePhoto)
        
        do {
            try modelContext.save()
            isSaved = true
            print("✅ Photo saved successfully")
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
        await postureService.analyzeImage(image)
        
        await MainActor.run {
            if let result = postureService.analysisResult {
                self.analysisResult = result
                self.editableEarPoint = result.earPosition
                self.editableShoulderPoint = result.shoulderPosition
                
                // Check confidence from the pose
                if let pose = postureService.currentPose {
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
