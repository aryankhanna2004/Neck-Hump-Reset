//
//  PostureCheckView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

struct PostureCheckView: View {
    @StateObject private var viewModel = PostureCheckViewModel()
    @Environment(\.dismiss) private var dismiss
    
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
    }
    
    // MARK: - Instructions View
    private var instructionsView: some View {
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
            
            Spacer()
            
            // Content
            VStack(spacing: AppTheme.Spacing.xl) {
                // Illustration
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentCyan.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    // Side profile icon
                    Image(systemName: "person.fill.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.accentCyan)
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Neck Hump Check")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    Text("We'll measure your forward head posture\nto track your neck hump progress.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
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
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            Spacer()
            
            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                Text("All analysis happens on your device")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            .padding(.bottom, AppTheme.Spacing.md)
            
            // Button
            PrimaryButton(title: "Start Check", action: { viewModel.beginCheck() })
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xl)
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
        }
    }
    
    // MARK: - Positioning View
    private var positioningView: some View {
        ZStack {
            // Camera preview
            if !viewModel.cameraManager.isAuthorized {
                // Not authorized - show settings prompt
                VStack(spacing: AppTheme.Spacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    
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
                        Text("Open Settings")
                            .font(AppTheme.Typography.button)
                            .foregroundColor(AppTheme.Colors.deepNavy)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(AppTheme.Colors.accentCyan)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.deepNavy)
            } else if viewModel.cameraManager.isCameraReady {
                CameraPreviewView(session: viewModel.cameraManager.session)
                    .ignoresSafeArea()
                
                // Neck hump overlay with lines
                NeckHumpOverlayView(
                    earPoint: viewModel.liveEarPoint,
                    shoulderPoint: viewModel.liveShoulderPoint,
                    hipPoint: viewModel.liveHipPoint,
                    idealLine: viewModel.liveIdealLine,
                    isReady: viewModel.isReadyToCapture
                )
                .ignoresSafeArea()
            } else {
                VStack {
                    ProgressView()
                        .tint(AppTheme.Colors.accentCyan)
                    Text("Starting camera...")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
            }
            
            // UI overlay
            VStack {
                // Top bar
                HStack {
                    Button(action: { viewModel.done() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
                
                Spacer()
                
                // Side profile guide - optimized for upper body/head-shoulder detection
                VStack(spacing: AppTheme.Spacing.md) {
                    // Guide frame - wider and shorter for upper body focus
                    HStack {
                        Spacer()
                        
                        // Profile silhouette guide
                        ZStack {
                            // Wider frame for upper body
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    viewModel.isReadyToCapture ? Color.green : AppTheme.Colors.accentCyan,
                                    lineWidth: 3
                                )
                                .frame(width: 240, height: 280)
                            
                            // Upper body silhouette hint
                            VStack(spacing: 0) {
                                // Head
                                Circle()
                                    .fill(AppTheme.Colors.accentCyan.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                
                                // Neck/shoulders outline
                                Image(systemName: "figure.stand")
                                    .font(.system(size: 100))
                                    .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.15))
                                    .offset(y: -30)
                            }
                            
                            // Ear marker hint
                            Circle()
                                .stroke(AppTheme.Colors.accentCyan.opacity(0.4), lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .offset(x: -60, y: -60)
                            
                            // Shoulder marker hint
                            Circle()
                                .stroke(AppTheme.Colors.accentCyan.opacity(0.4), lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .offset(x: -40, y: 30)
                            
                            // Countdown overlay
                            if let countdown = viewModel.countdownValue {
                                Text("\(countdown)")
                                    .font(.system(size: 100, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 10)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .shadow(color: (viewModel.isReadyToCapture ? Color.green : AppTheme.Colors.accentCyan).opacity(0.3), radius: 10)
                        
                        Spacer()
                    }
                    
                    // Instruction text
                    Text(viewModel.positioningMessage)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(Color.black.opacity(0.7)))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.positioningMessage)
                }
                
                Spacer()
                
                // Bottom guidance (no capture button)
                VStack(spacing: AppTheme.Spacing.md) {
                    // Progress indicator
                    if viewModel.isCountingDown {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                            Text("Auto-capturing...")
                                .font(AppTheme.Typography.body)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Capsule().fill(Color.green.opacity(0.8)))
                    } else {
                        Text("Stand sideways • Show ear & shoulder")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.countdownValue)
    }
    
    // Computed properties for status
    private var statusColor: Color {
        if viewModel.isCountingDown {
            return .green
        } else if viewModel.isReadyToCapture {
            return .yellow
        } else {
            return .orange
        }
    }
    
    private var statusText: String {
        if viewModel.isCountingDown {
            return "Capturing"
        } else if viewModel.isReadyToCapture {
            return "Ready"
        } else {
            return "Positioning"
        }
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
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Analyzing your posture...")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text("Measuring neck alignment")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            Spacer()
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
        GeometryReader { geometry in
            let imageSize = geometry.size
            
            ZStack {
                // The captured photo
                Image(decorative: photo, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize.width, height: imageSize.width * 1.3)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                
                // Overlay with lines and points
                if let ear = viewModel.editableEarPoint, let shoulder = viewModel.editableShoulderPoint {
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
                            style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                        )
                        
                        // Draw actual line from shoulder to ear (cyan/orange based on severity)
                        var actualPath = Path()
                        actualPath.move(to: shoulderPixel)
                        actualPath.addLine(to: earPixel)
                        
                        let lineColor: Color = {
                            if let result = viewModel.analysisResult {
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
                            lineWidth: 4
                        )
                        
                        // Draw forward distance indicator (horizontal line)
                        if earPixel.x != shoulderPixel.x {
                            var forwardPath = Path()
                            forwardPath.move(to: CGPoint(x: shoulderPixel.x, y: earPixel.y))
                            forwardPath.addLine(to: earPixel)
                            context.stroke(
                                forwardPath,
                                with: .color(.yellow),
                                style: StrokeStyle(lineWidth: 2, dash: [4, 2])
                            )
                        }
                    }
                    .frame(width: imageSize.width, height: imageSize.width * 1.3)
                    .allowsHitTesting(false)
                    
                    // Draggable points (only in edit mode)
                    if viewModel.isEditingPoints {
                        // Ear point
                        DraggablePoint(
                            position: Binding(
                                get: { 
                                    CGPoint(
                                        x: ear.x * imageSize.width,
                                        y: ear.y * (imageSize.width * 1.3)
                                    )
                                },
                                set: { newPos in
                                    let normalized = CGPoint(
                                        x: newPos.x / imageSize.width,
                                        y: newPos.y / (imageSize.width * 1.3)
                                    )
                                    viewModel.editableEarPoint = normalized
                                }
                            ),
                            color: .cyan,
                            label: "Ear",
                            isSelected: viewModel.selectedPointToEdit == .ear,
                            onTap: { viewModel.selectPoint(.ear) }
                        )
                        
                        // Shoulder point
                        DraggablePoint(
                            position: Binding(
                                get: { 
                                    CGPoint(
                                        x: shoulder.x * imageSize.width,
                                        y: shoulder.y * (imageSize.width * 1.3)
                                    )
                                },
                                set: { newPos in
                                    let normalized = CGPoint(
                                        x: newPos.x / imageSize.width,
                                        y: newPos.y / (imageSize.width * 1.3)
                                    )
                                    viewModel.editableShoulderPoint = normalized
                                }
                            ),
                            color: .orange,
                            label: "Shoulder",
                            isSelected: viewModel.selectedPointToEdit == .shoulder,
                            onTap: { viewModel.selectPoint(.shoulder) }
                        )
                    } else {
                        // Static points (non-edit mode)
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .position(
                                x: ear.x * imageSize.width,
                                y: ear.y * (imageSize.width * 1.3)
                            )
                        
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .position(
                                x: shoulder.x * imageSize.width,
                                y: shoulder.y * (imageSize.width * 1.3)
                            )
                    }
                }
            }
            .frame(width: imageSize.width, height: imageSize.width * 1.3)
        }
        .frame(height: UIScreen.main.bounds.width * 1.3 - 40)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Edit Mode Controls
    private var editModeControls: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Drag the points to correct their positions")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Point legend
                HStack(spacing: 6) {
                    Circle().fill(Color.cyan).frame(width: 12, height: 12)
                    Text("Ear")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.softWhite)
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color.orange).frame(width: 12, height: 12)
                    Text("Shoulder")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.softWhite)
                }
                
                Spacer()
                
                // Recalculate button
                Button(action: { viewModel.recalculateWithEditedPoints() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Recalculate")
                    }
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.deepNavy)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.Colors.accentCyan))
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                )
        )
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Measurements")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Spacer()
                
                // Research citation indicator
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Research-based")
                    }
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.8))
                }
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                measurementItem(
                    icon: "angle",
                    value: String(format: "%.0f°", result.craniovertebralAngle),
                    label: "CVA",
                    sublabel: result.humpSeverity.cvaThreshold,
                    isGood: result.craniovertebralAngle >= 50
                )
                
                measurementItem(
                    icon: "arrow.up.forward",
                    value: String(format: "%.0f°", abs(result.neckAngle)),
                    label: "Neck Tilt",
                    sublabel: "from vertical",
                    isGood: abs(result.neckAngle) < 15
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
        )
    }
    
    private func measurementItem(icon: String, value: String, label: String, sublabel: String, isGood: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Circle()
                    .fill(isGood ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
            }
            .foregroundColor(isGood ? .green : .orange)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(label)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(sublabel)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
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

// MARK: - Draggable Point Component
struct DraggablePoint: View {
    @Binding var position: CGPoint
    let color: Color
    let label: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Outer ring (shows when selected)
            if isSelected {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .opacity(0.5)
            }
            
            // Main point
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: color.opacity(0.5), radius: isSelected ? 8 : 4)
            
            // Label
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(color))
                .offset(y: -28)
        }
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    position = CGPoint(
                        x: position.x + value.translation.width,
                        y: position.y + value.translation.height
                    )
                    dragOffset = .zero
                }
        )
        .onTapGesture {
            onTap()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PostureCheckView()
}
