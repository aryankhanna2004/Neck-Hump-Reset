//
//  PostureCheckView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

// Notification for navigating to exercises tab
extension Notification.Name {
    static let navigateToExercises = Notification.Name("navigateToExercises")
}

struct PostureCheckView: View {
    @StateObject private var viewModel = PostureCheckViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showFullscreenVideo = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            switch viewModel.currentState {
            case .instructions:
                instructionsView
                    .transition(.opacity)
                
            case .positioning:
                positioningView
                    .transition(.opacity)
                
            case .analyzing:
                analyzingView
                    .transition(.opacity)
                
            case .results:
                resultsView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentState)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showFullscreenVideo) {
            FullscreenVideoPlayer()
        }
        .sheet(isPresented: $viewModel.showLowConfidenceWarning) {
            LowConfidenceWarningSheet(
                confidence: viewModel.detectionConfidence,
                onRetake: { viewModel.retakeForBetterDetection() },
                onContinue: { viewModel.dismissLowConfidenceWarning() }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Instructions View
    private var instructionsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(AppTheme.Colors.primaryBlue.opacity(0.3)))
                    }
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
                
                // Content
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Title
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Neck Hump Check")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        Text("We'll measure your forward head posture to track your neck hump progress.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                    
                    // Video Player - tap to fullscreen
                    Button(action: { showFullscreenVideo = true }) {
                        ZStack {
                            SidePoseVideoPlayer()
                                .frame(height: 200)
                            
                            // Fullscreen hint overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.system(size: 10))
                                        Text("Tap to expand")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.black.opacity(0.6)))
                                    .padding(8)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Setup tips
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Setup")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        setupTip(number: "1", text: "Stand up straight, feet shoulder-width apart")
                        setupTip(number: "2", text: "Turn sideways to show your profile")
                        setupTip(number: "3", text: "Position camera at shoulder height")
                        setupTip(number: "4", text: "Make sure your ear & shoulder are visible")
                    }
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                    )
                    
                    // Privacy note
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("All analysis happens on your device")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                    
                    // Button
                    PrimaryButton(title: "Start Check", action: { viewModel.beginCheck() })
                        .padding(.top, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }
    
    private func setupTip(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.Colors.deepNavy)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.Colors.accentCyan))
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.softWhite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Positioning View
    private var positioningView: some View {
        ZStack {
            // Camera preview - full screen
            if !viewModel.cameraManager.isAuthorized {
                cameraNotAuthorizedView
            } else if viewModel.cameraManager.isCameraReady {
                CameraPreviewView(session: viewModel.cameraManager.session)
                    .ignoresSafeArea()
            } else {
                cameraLoadingView
            }
            
            // Modern overlay UI
            VStack(spacing: 0) {
                topCameraBar
                Spacer()
                centerGuideFrame
                Spacer()
                bottomCameraControls
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.countdownValue)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCountingDown)
    }
    
    // MARK: - Camera Sub-Views
    
    private var cameraNotAuthorizedView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red.opacity(0.8))
            }
            
            Text("Camera Access Required")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text("Please enable camera access in Settings to use posture detection.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(AppTheme.Typography.button)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AppTheme.Colors.accentCyan, AppTheme.Colors.glowBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.deepNavy)
    }
    
    private var cameraLoadingView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.Colors.accentCyan)
            Text("Starting camera...")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.deepNavy)
    }
    
    private var topCameraBar: some View {
        HStack {
            Button(action: { viewModel.done() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            Spacer()
            
            if viewModel.isCountingDown {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(viewModel.countdownValue != nil ? 1 : 0.5)
                    Text("Recording")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            Spacer()
            
            Button(action: { viewModel.flipCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(viewModel.isCountingDown)
            .opacity(viewModel.isCountingDown ? 0.5 : 1)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.md)
    }
    
    private var centerGuideFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: viewModel.isCountingDown
                            ? [Color.green, Color.green.opacity(0.6)]
                            : [AppTheme.Colors.accentCyan, AppTheme.Colors.glowBlue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: viewModel.isCountingDown ? 4 : 2
                )
                .frame(width: 240, height: 300)
                .shadow(color: (viewModel.isCountingDown ? Color.green : AppTheme.Colors.accentCyan).opacity(0.4), radius: 15)
            
            ForEach(0..<4, id: \.self) { index in
                CornerBracket(index: index, isActive: viewModel.isCountingDown)
            }
            .frame(width: 240, height: 300)
            
            if !viewModel.isCountingDown {
                VStack(spacing: -10) {
                    Circle()
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "figure.stand")
                        .font(.system(size: 100))
                        .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.1))
                }
            }
            
            if let countdown = viewModel.countdownValue {
                Text("\(countdown)")
                    .font(.system(size: 100, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var bottomCameraControls: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text(viewModel.isCountingDown ? "Hold still..." : "Stand sideways • Show ear & shoulder")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial, in: Capsule())
            
            if !viewModel.isCountingDown {
                HStack(spacing: 4) {
                    TimerOptionButton(title: "Instant", value: 0, selectedValue: $viewModel.selectedTimerDuration)
                    TimerOptionButton(title: "3s", value: 3, selectedValue: $viewModel.selectedTimerDuration)
                    TimerOptionButton(title: "5s", value: 5, selectedValue: $viewModel.selectedTimerDuration)
                    TimerOptionButton(title: "10s", value: 10, selectedValue: $viewModel.selectedTimerDuration)
                }
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            HStack(spacing: 40) {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 54, height: 54)
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        Text("Upload")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                    Task {
                        await viewModel.handleSelectedPhoto(newItem)
                    }
                }
                .disabled(viewModel.isCountingDown)
                .opacity(viewModel.isCountingDown ? 0.4 : 1)
                
                Button(action: {
                    if viewModel.isCountingDown {
                        viewModel.cancelCountdown()
                    } else {
                        viewModel.startTimerCapture()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(
                                viewModel.isCountingDown ? Color.red : Color.white,
                                lineWidth: 4
                            )
                            .frame(width: 76, height: 76)
                        
                        if viewModel.isCountingDown {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 64, height: 64)
                        }
                    }
                    .shadow(color: (viewModel.isCountingDown ? Color.red : Color.white).opacity(0.3), radius: 10)
                }
                
                Button(action: { viewModel.flipCamera() }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 54, height: 54)
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        Text(viewModel.cameraManager.isUsingFrontCamera ? "Back" : "Front")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .disabled(viewModel.isCountingDown)
                .opacity(viewModel.isCountingDown ? 0.4 : 1)
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Analyzing View
    private var analyzingView: some View {
        EnhancedAnalyzingView(
            capturedPhoto: viewModel.capturedPhoto,
            isAnalyzing: viewModel.isAnalyzing,
            onCancel: { viewModel.retake() }
        )
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    HStack {
                        Button(action: { viewModel.done() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.red.opacity(0.6)))
                        }
                        Spacer()
                    }
                    .padding(.top, AppTheme.Spacing.md)
                    
                    // Score card at the top
                    if let result = viewModel.analysisResult {
                        scoreCard(result: result)
                    }
                    
                    // Photo with overlay
                    if let photo = viewModel.capturedPhoto {
                        photoWithOverlay(photo: photo)
                            .id("photoSection")
                    }
                    
                    if let result = viewModel.analysisResult {
                        // Ear selector (show if both ears detected)
                        if viewModel.leftEarPoint != nil && viewModel.rightEarPoint != nil {
                            earSelectorCard
                        }
                        
                        if viewModel.isEditingPoints {
                            editModeControls
                                .id("editControls")
                        } else {
                            pointsVerificationCard
                        }
                        
                        measurementCard(result: result)
                        severityCard(result: result)
                        suggestionsCard(result: result)
                    }
                    
                    // Actions
                    actionButtons
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .onChange(of: viewModel.isEditingPoints) { _, newValue in
                    if newValue {
                        withAnimation(.easeOut(duration: 0.3)) {
                            scrollProxy.scrollTo("photoSection", anchor: .top)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Photo with Overlay
    private func photoWithOverlay(photo: CGImage) -> some View {
        ZoomablePhotoOverlayView(
            photo: photo,
            earPoint: $viewModel.editableEarPoint,
            shoulderPoint: $viewModel.editableShoulderPoint,
            leftEarPoint: viewModel.leftEarPoint,
            rightEarPoint: viewModel.rightEarPoint,
            selectedEar: viewModel.selectedEar,
            isEditingPoints: viewModel.isEditingPoints,
            selectedPoint: viewModel.selectedPointToEdit,
            analysisResult: viewModel.analysisResult,
            onSelectPoint: { viewModel.selectPoint($0) }
        )
    }
    
    // MARK: - Ear Selector Card
    private var earSelectorCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "ear.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                
                Text("Select Ear")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Spacer()
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Left Ear Button
                Button(action: { viewModel.switchToLeftEar() }) {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Left")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text("Conf: \(Int(viewModel.leftEarConfidence * 100))%")
                            .font(.system(size: 11))
                            .opacity(0.7)
                    }
                    .foregroundColor(viewModel.selectedEar == .left ? .white : AppTheme.Colors.mutedGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.selectedEar == .left ? Color.cyan.opacity(0.3) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.selectedEar == .left ? Color.cyan : Color.gray.opacity(0.3), lineWidth: viewModel.selectedEar == .left ? 2 : 1)
                            )
                    )
                }
                
                // Right Ear Button
                Button(action: { viewModel.switchToRightEar() }) {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text("Right")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Text("Conf: \(Int(viewModel.rightEarConfidence * 100))%")
                            .font(.system(size: 11))
                            .opacity(0.7)
                    }
                    .foregroundColor(viewModel.selectedEar == .right ? .white : AppTheme.Colors.mutedGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.selectedEar == .right ? Color.cyan.opacity(0.3) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.selectedEar == .right ? Color.cyan : Color.gray.opacity(0.3), lineWidth: viewModel.selectedEar == .right ? 2 : 1)
                            )
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
        )
    }
    
    // MARK: - Points Verification Card
    private var pointsVerificationCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                
                Text("Are the points correct?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Spacer()
            }
            
            Text("Check that the green points match your ear and base of neck (C7). Use the reference image below.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.mutedGray)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Reference")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.mutedGray)
                
                Image("CVA")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Button(action: { viewModel.toggleEditMode() }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                    Text("Correct Points")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
                        )
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
        )
    }
    
    // MARK: - Edit Mode Controls
    private var editModeControls: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Editing Points")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Spacer()
                
                Button(action: { viewModel.toggleEditMode() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Cancel")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.Colors.primaryBlue.opacity(0.5)))
                }
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                instructionRow(icon: "hand.draw", text: "Drag points to correct positions")
                instructionRow(icon: "hand.pinch", text: "Pinch to zoom for precision")
            }
            
            HStack(spacing: AppTheme.Spacing.lg) {
                Button(action: { viewModel.selectPoint(.ear) }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: viewModel.selectedPointToEdit == .ear ? 2 : 0)
                            )
                        Text("Ear")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(viewModel.selectedPointToEdit == .ear ? .white : AppTheme.Colors.mutedGray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedPointToEdit == .ear ? Color.cyan.opacity(0.3) : Color.clear)
                    )
                }
                
                Button(action: { viewModel.selectPoint(.shoulder) }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: viewModel.selectedPointToEdit == .shoulder ? 2 : 0)
                            )
                        Text("C7")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(viewModel.selectedPointToEdit == .shoulder ? .white : AppTheme.Colors.mutedGray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedPointToEdit == .shoulder ? Color.orange.opacity(0.3) : Color.clear)
                    )
                }
                
                Spacer()
            }
            
            if viewModel.isLowConfidence {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("Low detection confidence - please verify points")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
            }
            
            Button(action: { viewModel.recalculateWithEditedPoints() }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Recalculate")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Reference: Where to place points")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.Colors.mutedGray)
                
                Image("CVA")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.top, AppTheme.Spacing.sm)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.Colors.accentCyan.opacity(0.4), AppTheme.Colors.glowBlue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.8))
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
    
    // MARK: - Result Cards
    
    private func scoreCard(result: NeckHumpAnalysisResult) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Colored indicator dot
            Circle()
                .fill(severityColor(result.humpSeverity))
                .frame(width: 16, height: 16)
                .shadow(color: severityColor(result.humpSeverity).opacity(0.6), radius: 4)
            
            // Score number
            Text("\(result.overallScore)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(severityColor(result.humpSeverity))
            
            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(result.humpSeverity.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text("Posture Score")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            Spacer()
            
            // Emoji
            Text(result.humpSeverity.emoji)
                .font(.system(size: 32))
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(severityColor(result.humpSeverity).opacity(0.4), lineWidth: 1.5)
                )
        )
    }
    
    private func measurementCard(result: NeckHumpAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                Text("Your Measurements")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            MeasurementDetailRow(
                icon: "angle",
                title: "Craniovertebral Angle (CVA)",
                value: String(format: "%.0f°", result.craniovertebralAngle),
                explanation: "The angle between your shoulder and ear. Higher is better. Normal posture is above 53°.",
                threshold: result.humpSeverity.cvaThreshold,
                isGood: result.craniovertebralAngle >= 50
            )
            
            MeasurementDetailRow(
                icon: "arrow.left.and.right",
                title: "Forward Head Position",
                value: String(format: "%.1f cm", result.forwardHeadDistance),
                explanation: "How far your head sits in front of your shoulders. Less is better.",
                threshold: result.forwardHeadDistance < 2 ? "Aligned" : (result.forwardHeadDistance < 4 ? "Slightly forward" : "Forward"),
                isGood: result.forwardHeadDistance < 3
            )
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
        )
    }
    
    private func severityCard(result: NeckHumpAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("What this means")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(result.humpSeverity.description)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
        )
    }
    
    private func suggestionsCard(result: NeckHumpAnalysisResult) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 4)
            
            Text("Ready to improve?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text("Get a personalized exercise routine based on your results")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.mutedGray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Post notification to switch to exercises tab
                NotificationCenter.default.post(name: .navigateToExercises, object: nil)
                dismiss()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                    Text("Start Exercises")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.purple.opacity(0.4), radius: 8, y: 4)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Button(action: {
                viewModel.savePhoto(modelContext: modelContext)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                        .font(.system(size: 20))
                    Text(viewModel.isSaved ? "Saved to Progress!" : "Save to Progress")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(viewModel.isSaved ? .green : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if viewModel.isSaved {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
                        }
                    }
                )
            }
            .disabled(viewModel.isSaved)
            
            HStack(spacing: 12) {
                Button(action: { viewModel.retake() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Take Another")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.accentCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.accentCyan.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.accentCyan.opacity(0.5), lineWidth: 1.5)
                            )
                    )
                }
                
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Done")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                    )
                }
            }
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
    
    private func severityColor(_ severity: HumpSeverity) -> Color {
        switch severity {
        case .minimal: return .green
        case .mild: return AppTheme.Colors.accentCyan
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

#Preview {
    PostureCheckView()
}
