//
//  PostureCheckViewModel.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import Combine
import CoreMedia

@MainActor
class PostureCheckViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: PostureCheckState = .instructions
    @Published var analysisResult: NeckHumpAnalysisResult?
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    @Published var positioningMessage: String = "Stand sideways to the camera"
    @Published var isReadyToCapture: Bool = false
    
    // Countdown for auto-capture
    @Published var countdownValue: Int? = nil
    @Published var isCountingDown: Bool = false
    
    // Live visualization data
    @Published var liveEarPoint: CGPoint?
    @Published var liveShoulderPoint: CGPoint?
    @Published var liveHipPoint: CGPoint?
    @Published var liveIdealLine: (start: CGPoint, end: CGPoint)?
    
    // Captured image and editable points
    @Published var capturedPhoto: CGImage?
    @Published var editableEarPoint: CGPoint?
    @Published var editableShoulderPoint: CGPoint?
    @Published var isEditingPoints: Bool = false
    @Published var selectedPointToEdit: EditablePoint? = nil
    
    // MARK: - Services
    let cameraManager = CameraManager()
    let postureService = PostureDetectionService()
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var frameCount = 0
    private var countdownTimer: Timer?
    private var stableFrameCount = 0
    private let requiredStableFrames = 8 // ~0.5 seconds of stability before countdown
    
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
        
        // Listen for camera errors
        cameraManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
        
        // Setup live frame analysis
        cameraManager.onFrameCaptured = { [weak self] buffer in
            self?.handleFrame(buffer)
        }
        
        // Listen for positioning guidance and trigger auto-capture
        postureService.$positioningGuidance
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] guidance in
                guard let self = self else { return }
                self.positioningMessage = guidance.message
                self.isReadyToCapture = guidance.isGoodPosition
                
                // Handle auto-capture logic
                if guidance.isGoodPosition && !self.isCountingDown && self.currentState == .positioning {
                    self.stableFrameCount += 1
                    if self.stableFrameCount >= self.requiredStableFrames {
                        self.startCountdown()
                    }
                } else if !guidance.isGoodPosition {
                    self.stableFrameCount = 0
                    self.cancelCountdown()
                }
            }
            .store(in: &cancellables)
        
        // Listen for live visualization points
        postureService.$liveEarPoint
            .receive(on: DispatchQueue.main)
            .assign(to: &$liveEarPoint)
        
        postureService.$liveShoulderPoint
            .receive(on: DispatchQueue.main)
            .assign(to: &$liveShoulderPoint)
        
        postureService.$liveHipPoint
            .receive(on: DispatchQueue.main)
            .assign(to: &$liveHipPoint)
        
        postureService.$liveIdealLine
            .receive(on: DispatchQueue.main)
            .sink { [weak self] line in
                self?.liveIdealLine = line
            }
            .store(in: &cancellables)
        
        // Listen for detection state
        postureService.$detectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .searching:
                    if !self.isCountingDown {
                        self.positioningMessage = "Looking for you..."
                    }
                case .positioning:
                    break // Message comes from guidance
                case .ready:
                    if !self.isCountingDown {
                        self.positioningMessage = "Hold still..."
                    }
                case .analyzing:
                    self.positioningMessage = "Analyzing..."
                case .complete:
                    break
                }
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
    
    func beginCheck() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentState = .positioning
        }
        postureService.reset()
        stableFrameCount = 0
        capturedPhoto = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        startCamera()
    }
    
    func retake() {
        analysisResult = nil
        errorMessage = nil
        postureService.reset()
        stableFrameCount = 0
        countdownValue = nil
        isCountingDown = false
        capturedPhoto = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
        selectedPointToEdit = nil
        
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
        stableFrameCount = 0
        capturedPhoto = nil
        editableEarPoint = nil
        editableShoulderPoint = nil
        isEditingPoints = false
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
        }
    }
    
    // MARK: - Private Methods
    
    private func startCountdown() {
        guard !isCountingDown else { return }
        
        isCountingDown = true
        countdownValue = 3
        positioningMessage = "Perfect! Capturing in 3..."
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if let current = self.countdownValue, current > 1 {
                    self.countdownValue = current - 1
                    self.positioningMessage = "Hold still... \(current - 1)"
                } else {
                    // Countdown finished, capture!
                    timer.invalidate()
                    self.countdownTimer = nil
                    self.performAutoCapture()
                }
            }
        }
    }
    
    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownValue = nil
        isCountingDown = false
    }
    
    private func performAutoCapture() {
        guard currentState == .positioning else { return }
        
        withAnimation {
            currentState = .analyzing
            isAnalyzing = true
            countdownValue = nil
            isCountingDown = false
        }
        
        cameraManager.capturePhoto()
    }
    
    private func handleFrame(_ buffer: CMSampleBuffer) {
        frameCount += 1
        // Analyze every 3rd frame for smoother feedback
        guard frameCount % 3 == 0 else { return }
        
        postureService.processLiveFrame(buffer)
    }
    
    private func analyzeImage(_ image: CGImage) async {
        await postureService.analyzeImage(image)
        
        await MainActor.run {
            if let result = postureService.analysisResult {
                self.analysisResult = result
                // Set editable points from the analysis result
                self.editableEarPoint = result.earPosition
                self.editableShoulderPoint = result.shoulderPosition
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.currentState = .results
                }
            } else if let error = postureService.errorMessage {
                self.errorMessage = error
                self.currentState = .positioning
                self.stableFrameCount = 0
            }
            self.isAnalyzing = false
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
