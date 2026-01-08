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
                // Not authorized - show settings prompt
                cameraNotAuthorizedView
            } else if viewModel.cameraManager.isCameraReady {
                CameraPreviewView(session: viewModel.cameraManager.session)
                    .ignoresSafeArea()
            } else {
                cameraLoadingView
            }
            
            // Modern overlay UI
            VStack(spacing: 0) {
                // Top bar with glassmorphism
                topCameraBar
                
                Spacer()
                
                // Center guide frame
                centerGuideFrame
                
                Spacer()
                
                // Bottom controls with modern design
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
            // Close button
                    Button(action: { viewModel.done() }) {
                        Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
            // Timer indicator when counting down
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
                
            // Camera flip button
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
            // Animated guide frame
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
            
            // Corner brackets for modern look
            ForEach(0..<4, id: \.self) { index in
                CornerBracket(index: index, isActive: viewModel.isCountingDown)
            }
            .frame(width: 240, height: 300)
            
            // Silhouette hint (only when not counting down)
            if !viewModel.isCountingDown {
                VStack(spacing: -10) {
                    // Head outline
                                Circle()
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.25), lineWidth: 1.5)
                                    .frame(width: 60, height: 60)
                                
                    // Body silhouette
                                Image(systemName: "figure.stand")
                                    .font(.system(size: 100))
                        .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.1))
                }
            }
            
            // Countdown display
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
            // Instruction pill
            Text(viewModel.isCountingDown ? "Hold still..." : "Stand sideways • Show ear & shoulder")
                .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                .background(.ultraThinMaterial, in: Capsule())
            
            // Timer selector (modern segmented style)
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
                    
                    // Action buttons row
            HStack(spacing: 40) {
                        // Photo picker button
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
                
                // Main capture button
                Button(action: {
                    if viewModel.isCountingDown {
                        viewModel.cancelCountdown()
                    } else {
                        viewModel.startTimerCapture()
                    }
                }) {
                            ZStack {
                        // Outer ring
                                Circle()
                            .stroke(
                                viewModel.isCountingDown ? Color.red : Color.white,
                                lineWidth: 4
                            )
                            .frame(width: 76, height: 76)
                        
                        // Inner content
                        if viewModel.isCountingDown {
                            // Stop icon
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 30, height: 30)
                        } else {
                            // Shutter button with gradient
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
                
                // Camera flip button
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
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            ZStack {
                // Animated rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(100 + index * 30), height: CGFloat(100 + index * 30))
                        .scaleEffect(viewModel.isAnalyzing ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: viewModel.isAnalyzing
                        )
                }
                
                // Center icon
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.Colors.accentCyan)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Analyzing your posture...")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                // Processing steps
                VStack(spacing: AppTheme.Spacing.sm) {
                    AnalyzingStepView(icon: "photo.fill", text: "Processing image", isActive: true)
                    AnalyzingStepView(icon: "figure.stand", text: "Detecting pose", isActive: viewModel.isAnalyzing)
                    AnalyzingStepView(icon: "ruler", text: "Measuring alignment", isActive: viewModel.isAnalyzing)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            
            Spacer()
            
            // Cancel button
            Button(action: { viewModel.retake() }) {
                Text("Cancel")
                    .font(AppTheme.Typography.button)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .stroke(AppTheme.Colors.mutedGray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                HStack {
                    Button(action: { viewModel.done() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(AppTheme.Colors.primaryBlue.opacity(0.3)))
                    }
                    Spacer()
                    
                    // Edit button
                    Button(action: { viewModel.toggleEditMode() }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isEditingPoints ? "checkmark" : "pencil")
                                .font(.system(size: 14, weight: .semibold))
                            Text(viewModel.isEditingPoints ? "Done" : "Edit Points")
                                .font(AppTheme.Typography.small)
                        }
                        .foregroundColor(viewModel.isEditingPoints ? .green : AppTheme.Colors.accentCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(viewModel.isEditingPoints ? Color.green.opacity(0.2) : AppTheme.Colors.primaryBlue.opacity(0.3))
                        )
                    }
                }
                .padding(.top, AppTheme.Spacing.md)
                
                // Photo with overlay
                if let photo = viewModel.capturedPhoto {
                    photoWithOverlay(photo: photo)
                }
                
                // Edit mode controls
                if viewModel.isEditingPoints {
                    editModeControls
                }
                
                if let result = viewModel.analysisResult {
                    // Main score card
                    scoreCard(result: result)
                    
                    // Measurement details
                    measurementCard(result: result)
                    
                    // Severity explanation
                    severityCard(result: result)
                    
                    // Suggestions
                    suggestionsCard(result: result)
                }
                
                // Actions
                VStack(spacing: AppTheme.Spacing.md) {
                    // Save button
                    Button(action: {
                        viewModel.savePhoto(modelContext: modelContext)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.system(size: 18))
                            Text(viewModel.isSaved ? "Saved!" : "Save to Progress")
                                .font(AppTheme.Typography.button)
                        }
                        .foregroundColor(viewModel.isSaved ? .green : AppTheme.Colors.deepNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .fill(viewModel.isSaved ? Color.green.opacity(0.2) : AppTheme.Colors.accentCyan)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(viewModel.isSaved ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    .disabled(viewModel.isSaved)
                    
                    PrimaryButton(title: "Take Another", action: { viewModel.retake() })
                    SecondaryButton(title: "Done", action: { dismiss() })
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Photo with Overlay
    private func photoWithOverlay(photo: CGImage) -> some View {
        ZoomablePhotoOverlayView(
            photo: photo,
            earPoint: $viewModel.editableEarPoint,
            shoulderPoint: $viewModel.editableShoulderPoint,
            isEditingPoints: viewModel.isEditingPoints,
            selectedPoint: viewModel.selectedPointToEdit,
            analysisResult: viewModel.analysisResult,
            onSelectPoint: { viewModel.selectPoint($0) }
        )
    }
    
    // MARK: - Edit Mode Controls
    private var editModeControls: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                Text("Adjust Detection Points")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                instructionRow(icon: "hand.draw", text: "Drag points to correct positions")
                instructionRow(icon: "hand.pinch", text: "Pinch to zoom for precision")
                instructionRow(icon: "hand.tap", text: "Double-tap to reset zoom")
            }
            
            // Point legend and selection
            HStack(spacing: AppTheme.Spacing.lg) {
                // Ear point selector
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
                
                // Shoulder point selector
                Button(action: { viewModel.selectPoint(.shoulder) }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: viewModel.selectedPointToEdit == .shoulder ? 2 : 0)
                            )
                        Text("Shoulder")
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
            
            // Low confidence warning if applicable
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
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
            
            // Action button
                Button(action: { viewModel.recalculateWithEditedPoints() }) {
                HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                    Text("Apply Changes & Recalculate")
                    }
                .font(AppTheme.Typography.button)
                    .foregroundColor(AppTheme.Colors.deepNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppTheme.Colors.accentCyan, AppTheme.Colors.glowBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
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
        VStack(spacing: AppTheme.Spacing.md) {
            Text(result.humpSeverity.emoji)
                .font(.system(size: 60))
            
            Text("\(result.overallScore)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(severityColor(result.humpSeverity))
            
            Text(result.humpSeverity.title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text("Posture Score")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.Colors.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .stroke(severityColor(result.humpSeverity).opacity(0.4), lineWidth: 2)
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
            
            // CVA Measurement - Primary metric
            MeasurementDetailRow(
                    icon: "angle",
                title: "Craniovertebral Angle (CVA)",
                    value: String(format: "%.0f°", result.craniovertebralAngle),
                explanation: "The angle between your shoulder and ear. Higher is better. Normal posture is above 53°.",
                threshold: result.humpSeverity.cvaThreshold,
                    isGood: result.craniovertebralAngle >= 50
                )
                
            // Forward Head Distance
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(result.feedback.prefix(4), id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.accentCyan)
                            .padding(.top, 2)
                        
                        Text(suggestion)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.softWhite)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
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

// MARK: - Zoomable Photo Overlay View
struct ZoomablePhotoOverlayView: View {
    let photo: CGImage
    @Binding var earPoint: CGPoint?
    @Binding var shoulderPoint: CGPoint?
    let isEditingPoints: Bool
    let selectedPoint: EditablePoint?
    let analysisResult: NeckHumpAnalysisResult?
    let onSelectPoint: (EditablePoint) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDraggingPoint: Bool = false
    @State private var anchorPoint: CGPoint = .zero // For anchor-point zooming
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            let imageSize = geometry.size
            let contentHeight = imageSize.width * 1.3
            
            ZStack {
                // The captured photo
                Image(decorative: photo, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize.width, height: contentHeight)
                
                // Overlay with lines and points
                if let ear = earPoint, let shoulder = shoulderPoint {
                    Canvas { context, size in
                        let earPixel = CGPoint(
                            x: ear.x * size.width,
                            y: ear.y * size.height
                        )
                        let shoulderPixel = CGPoint(
                            x: shoulder.x * size.width,
                            y: shoulder.y * size.height
                        )
                        
                        // Ideal vertical line from shoulder (where ear should be)
                        let idealEarY = earPixel.y
                        let idealEarPixel = CGPoint(x: shoulderPixel.x, y: idealEarY)
                        
                        // Draw ideal vertical line (green, dashed)
                        var idealPath = Path()
                        idealPath.move(to: shoulderPixel)
                        idealPath.addLine(to: idealEarPixel)
                        context.stroke(
                            idealPath,
                            with: .color(.green.opacity(0.8)),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                        )
                        
                        // Draw actual line from shoulder to ear
                        var actualPath = Path()
                        actualPath.move(to: shoulderPixel)
                        actualPath.addLine(to: earPixel)
                        
                        let lineColor: Color = {
                            if let result = analysisResult {
                                switch result.humpSeverity {
                                case .minimal: return .green
                                case .mild: return .cyan
                                case .moderate: return .orange
                                case .severe: return .red
                                }
                            }
                            return .cyan
                        }()
                        
                        context.stroke(
                            actualPath,
                            with: .color(lineColor),
                            lineWidth: 3
                        )
                        
                        // Draw forward distance indicator (horizontal line)
                        if earPixel.x != shoulderPixel.x {
                            var forwardPath = Path()
                            forwardPath.move(to: CGPoint(x: shoulderPixel.x, y: earPixel.y))
                            forwardPath.addLine(to: earPixel)
                            context.stroke(
                                forwardPath,
                                with: .color(.yellow),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 2])
                            )
                        }
                        
                        // Draw static points when not editing (smaller size)
                        if !isEditingPoints {
                            let pointRadius: CGFloat = 5  // Smaller points
                            
                            // Ear point
                            let earRect = CGRect(
                                x: earPixel.x - pointRadius,
                                y: earPixel.y - pointRadius,
                                width: pointRadius * 2,
                                height: pointRadius * 2
                            )
                            context.fill(Circle().path(in: earRect), with: .color(.cyan))
                            context.stroke(Circle().path(in: earRect), with: .color(.white), lineWidth: 1.5)
                            
                            // Shoulder point
                            let shoulderRect = CGRect(
                                x: shoulderPixel.x - pointRadius,
                                y: shoulderPixel.y - pointRadius,
                                width: pointRadius * 2,
                                height: pointRadius * 2
                            )
                            context.fill(Circle().path(in: shoulderRect), with: .color(.orange))
                            context.stroke(Circle().path(in: shoulderRect), with: .color(.white), lineWidth: 1.5)
                        }
                    }
                    .frame(width: imageSize.width, height: contentHeight)
                    .allowsHitTesting(false)
                    
                    // Draggable points (only in edit mode)
                    if isEditingPoints {
                        // Ear point
                        EditablePointView(
                            normalizedPosition: Binding(
                                get: { ear },
                                set: { earPoint = $0 }
                            ),
                            containerSize: CGSize(width: imageSize.width, height: contentHeight),
                            color: .cyan,
                            label: "E",
                            isSelected: selectedPoint == .ear,
                            scale: scale,
                            onTap: { onSelectPoint(.ear) },
                            onDragStateChanged: { isDragging in
                                isDraggingPoint = isDragging
                            }
                        )
                        
                        // Shoulder point
                        EditablePointView(
                            normalizedPosition: Binding(
                                get: { shoulder },
                                set: { shoulderPoint = $0 }
                            ),
                            containerSize: CGSize(width: imageSize.width, height: contentHeight),
                            color: .orange,
                            label: "S",
                            isSelected: selectedPoint == .shoulder,
                            scale: scale,
                            onTap: { onSelectPoint(.shoulder) },
                            onDragStateChanged: { isDragging in
                                isDraggingPoint = isDragging
                            }
                        )
                    }
                }
            }
            .frame(width: imageSize.width, height: contentHeight)
            .scaleEffect(scale, anchor: .center)
            .offset(offset)
            .contentShape(Rectangle()) // Constrain hit testing to this frame
            .gesture(
                // Pinch to zoom with anchor point
                MagnificationGesture()
                    .onChanged { value in
                        guard !isDraggingPoint else { return }
                        let newScale = min(max(lastScale * value, minScale), maxScale)
                        
                        // Calculate the offset adjustment to zoom toward the pinch point
                        // This keeps the content under the pinch point stationary
                        let scaleDelta = newScale / scale
                        
                        // Adjust offset to zoom toward center (anchor point)
                        // When scale increases, we need to move the offset to keep the pinch point stable
                        let newOffsetX = offset.width * scaleDelta
                        let newOffsetY = offset.height * scaleDelta
                        
                        scale = newScale
                        offset = CGSize(width: newOffsetX, height: newOffsetY)
                    }
                    .onEnded { _ in
                        lastScale = scale
                        lastOffset = offset
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if scale < minScale {
                                scale = minScale
                                lastScale = minScale
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                clampOffset(size: CGSize(width: imageSize.width, height: contentHeight))
                            }
                        }
                    }
            )
            .simultaneousGesture(
                // One finger drag to pan (only when zoomed and not editing points)
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        // Allow panning when zoomed OR when not in edit mode
                        if scale > 1.0 && !isDraggingPoint {
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            clampOffset(size: CGSize(width: imageSize.width, height: contentHeight))
                        }
                    }
            )
            .onTapGesture(count: 2) { location in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if scale > 1.0 {
                        // Reset to normal
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        // Zoom in to 2x centered on tap location
                        let newScale: CGFloat = 2.5
                        
                        // Calculate offset to center on tap point
                        let centerX = imageSize.width / 2
                        let centerY = contentHeight / 2
                        let tapOffsetX = (centerX - location.x) * (newScale - 1)
                        let tapOffsetY = (centerY - location.y) * (newScale - 1)
                        
                        scale = newScale
                        lastScale = newScale
                        offset = CGSize(width: tapOffsetX, height: tapOffsetY)
                        lastOffset = offset
                        
                        // Clamp after setting
                        clampOffset(size: CGSize(width: imageSize.width, height: contentHeight))
                    }
                }
            }
        }
        .aspectRatio(1/1.3, contentMode: .fit)
        .clipped() // Clip content to bounds
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)) // Constrain touch area
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            // Zoom/Pan indicator
            VStack {
                HStack {
                    Spacer()
                    if scale > 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10))
                            Text(String(format: "%.1fx", scale))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                        .padding(8)
                    }
                }
                Spacer()
                // Pan hint when zoomed
                if scale > 1.0 && !isEditingPoints {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 10))
                        Text("Drag to pan")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .padding(.bottom, 8)
                }
            }
        )
    }
    
    private func clampOffset(size: CGSize) {
        let maxX = (size.width * (scale - 1)) / 2
        let maxY = (size.height * (scale - 1)) / 2
        
        var newOffset = offset
        
        if scale <= 1.0 {
            newOffset = .zero
        } else {
            newOffset.width = min(max(newOffset.width, -maxX), maxX)
            newOffset.height = min(max(newOffset.height, -maxY), maxY)
        }
        
        offset = newOffset
        lastOffset = newOffset
    }
}

// MARK: - Editable Point View (Improved dragging)
struct EditablePointView: View {
    @Binding var normalizedPosition: CGPoint
    let containerSize: CGSize
    let color: Color
    let label: String
    let isSelected: Bool
    let scale: CGFloat
    let onTap: () -> Void
    let onDragStateChanged: (Bool) -> Void
    
    @State private var isDragging: Bool = false
    @GestureState private var dragOffset: CGSize = .zero
    
    private var pixelPosition: CGPoint {
        CGPoint(
            x: normalizedPosition.x * containerSize.width,
            y: normalizedPosition.y * containerSize.height
        )
    }
    
    var body: some View {
        let pointSize: CGFloat = 20 / scale
        let hitAreaSize: CGFloat = 44 / scale // Larger hit area for easier tapping
        
        ZStack {
            // Selection ring
            if isSelected || isDragging {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2 / scale)
                    .frame(width: pointSize * 1.8, height: pointSize * 1.8)
            }
            
            // Main point
            Circle()
                .fill(color)
                .frame(width: pointSize, height: pointSize)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2 / scale)
                )
                .shadow(color: color.opacity(0.5), radius: isDragging ? 8 / scale : 4 / scale)
            
            // Label
            Text(label)
                .font(.system(size: max(8, 10 / scale), weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4 / scale)
                .padding(.vertical, 2 / scale)
                .background(Capsule().fill(color))
                .offset(y: -(pointSize + 8 / scale))
        }
        .frame(width: hitAreaSize, height: hitAreaSize)
        .contentShape(Circle().scale(1.5)) // Larger hit area
        .position(
            x: pixelPosition.x + dragOffset.width,
            y: pixelPosition.y + dragOffset.height
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onChanged { _ in
                    if !isDragging {
                        isDragging = true
                        onDragStateChanged(true)
                    }
                }
                .onEnded { value in
                    // Update normalized position
                    let newPixelPos = CGPoint(
                        x: pixelPosition.x + value.translation.width,
                        y: pixelPosition.y + value.translation.height
                    )
                    // Clamp to container bounds
                    let clampedX = max(0, min(containerSize.width, newPixelPos.x))
                    let clampedY = max(0, min(containerSize.height, newPixelPos.y))
                    
                    normalizedPosition = CGPoint(
                        x: clampedX / containerSize.width,
                        y: clampedY / containerSize.height
                    )
                    isDragging = false
                    onDragStateChanged(false)
                }
        )
        .onTapGesture {
            onTap()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isDragging)
    }
}

// MARK: - Side Pose Video Player (Silent - No Audio Track)
struct SidePoseVideoPlayer: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if player != nil {
                SilentVideoPlayerView(player: $player)
                    .onAppear {
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                    }
            } else {
                // Fallback if video not found
                ZStack {
                    AppTheme.Colors.primaryBlue.opacity(0.3)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "person.fill.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.Colors.accentCyan)
                        
                        Text("Stand sideways to the camera")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "SidePose", withExtension: "mp4") else { return }
        
        // Configure audio session to mix with other audio (don't interrupt Spotify, etc.)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0 // Ensure completely silent
        player?.isMuted = true
        
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Silent Video Player UIViewRepresentable
struct SilentVideoPlayerView: UIViewRepresentable {
    @Binding var player: AVPlayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let playerView = uiView as? PlayerUIView else { return }
        playerView.playerLayer.player = player
    }
}

class PlayerUIView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
}

// MARK: - Fullscreen Video Player (Silent)
struct FullscreenVideoPlayer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if player != nil {
                SilentVideoPlayerView(player: $player)
                    .ignoresSafeArea()
                    .onAppear {
                        player?.play()
                    }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "SidePose", withExtension: "mp4") else { return }
        
        // Configure audio session to mix with other audio (don't interrupt Spotify, etc.)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0 // Completely silent
        player?.isMuted = true
        
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Timer Option Button
struct TimerOptionButton: View {
    let title: String
    let value: Int
    @Binding var selectedValue: Int
    
    var isSelected: Bool { selectedValue == value }
    
    var body: some View {
        Button(action: { selectedValue = value }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.clear)
                )
        }
    }
}

// MARK: - Analyzing Step View
struct AnalyzingStepView: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    @State private var opacity: Double = 0.3
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 20)
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Spacer()
            
            if isActive {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(AppTheme.Colors.accentCyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Corner Bracket
struct CornerBracket: View {
    let index: Int
    let isActive: Bool
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let bracketLength: CGFloat = 30
            let offset: CGFloat = 0
            
            Path { path in
                switch index {
                case 0: // Top-left
                    path.move(to: CGPoint(x: offset, y: bracketLength + offset))
                    path.addLine(to: CGPoint(x: offset, y: offset))
                    path.addLine(to: CGPoint(x: bracketLength + offset, y: offset))
                case 1: // Top-right
                    path.move(to: CGPoint(x: size.width - bracketLength - offset, y: offset))
                    path.addLine(to: CGPoint(x: size.width - offset, y: offset))
                    path.addLine(to: CGPoint(x: size.width - offset, y: bracketLength + offset))
                case 2: // Bottom-right
                    path.move(to: CGPoint(x: size.width - offset, y: size.height - bracketLength - offset))
                    path.addLine(to: CGPoint(x: size.width - offset, y: size.height - offset))
                    path.addLine(to: CGPoint(x: size.width - bracketLength - offset, y: size.height - offset))
                case 3: // Bottom-left
                    path.move(to: CGPoint(x: bracketLength + offset, y: size.height - offset))
                    path.addLine(to: CGPoint(x: offset, y: size.height - offset))
                    path.addLine(to: CGPoint(x: offset, y: size.height - bracketLength - offset))
                default:
                    break
                }
            }
            .stroke(
                isActive ? Color.green : AppTheme.Colors.accentCyan,
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Low Confidence Warning Sheet
struct LowConfidenceWarningSheet: View {
    let confidence: Float
    let onRetake: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            .padding(.top, AppTheme.Spacing.lg)
            
            // Title
            Text("Detection Quality Issue")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            // Description
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("We had difficulty detecting your ear and shoulder positions clearly.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                
                // Confidence indicator
                HStack(spacing: 8) {
                    Text("Detection confidence:")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(confidence < 0.5 ? .red : .orange)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            // Tips
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("For better results:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                tipRow(icon: "lightbulb.fill", text: "Ensure good lighting")
                tipRow(icon: "person.fill.turn.right", text: "Stand completely sideways")
                tipRow(icon: "eye.fill", text: "Make sure ear is visible")
                tipRow(icon: "camera.fill", text: "Position camera at shoulder height")
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
            )
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            Spacer()
            
            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Retake Photo")
                    }
                    .font(AppTheme.Typography.button)
                    .foregroundColor(AppTheme.Colors.deepNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.Colors.accentCyan)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                Button(action: onContinue) {
                    Text("Continue Anyway")
                        .font(AppTheme.Typography.button)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.Colors.primaryBlue.opacity(0.3))
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.deepNavy.ignoresSafeArea())
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.softWhite)
        }
    }
}

// MARK: - Measurement Detail Row (Scalable Component)
struct MeasurementDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let explanation: String
    let threshold: String
    let isGood: Bool
    
    @State private var showExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Main row
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                // Icon with status indicator
                ZStack {
                    Circle()
                        .fill(isGood ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isGood ? .green : .orange)
                }
                
                // Title and value
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        // Info button
                        Button(action: { withAnimation(.spring(response: 0.3)) { showExplanation.toggle() } }) {
                            Image(systemName: showExplanation ? "chevron.up.circle.fill" : "questionmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.7))
                        }
                    }
                    
                    Text(threshold)
                        .font(.system(size: 11))
                        .foregroundColor(isGood ? .green.opacity(0.8) : .orange.opacity(0.8))
                }
                
                Spacer()
                
                // Value
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isGood ? .green : .orange)
            }
            
            // Expandable explanation
            if showExplanation {
                Text(explanation)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(.leading, 56) // Align with text after icon
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
        )
    }
}

#Preview {
    PostureCheckView()
}
