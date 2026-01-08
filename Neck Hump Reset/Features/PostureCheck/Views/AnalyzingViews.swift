//
//  AnalyzingViews.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI

// MARK: - Enhanced Analyzing View
struct EnhancedAnalyzingView: View {
    let capturedPhoto: CGImage?
    let isAnalyzing: Bool
    let onCancel: () -> Void
    
    @State private var currentStep: Int = 0
    @State private var cornerBracketScale: CGFloat = 1.0
    @State private var cornerBracketOpacity: Double = 0.6
    @State private var gridOpacity: Double = 0
    @State private var scannerRotation: Double = 0
    @State private var focusRingScale: CGFloat = 0.8
    @State private var focusRingOpacity: Double = 0
    @State private var landmarkOpacities: [Double] = [0, 0, 0]
    @State private var landmarkScales: [CGFloat] = [0.5, 0.5, 0.5]
    @State private var connectionLineProgress: CGFloat = 0
    @State private var angleArcProgress: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @State private var particleOffset: CGFloat = 0
    
    private let steps = [
        (icon: "camera.viewfinder", text: "Scanning image"),
        (icon: "figure.stand", text: "Detecting pose"),
        (icon: "scope", text: "Finding key points"),
        (icon: "angle", text: "Calculating angle")
    ]
    
    private let earPosition = CGPoint(x: 0.48, y: 0.18)
    private let shoulderPosition = CGPoint(x: 0.52, y: 0.32)
    private let hipPosition = CGPoint(x: 0.50, y: 0.52)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)
            
            photoWithOverlays
            
            Spacer().frame(height: 28)
            
            animatedTitle
            
            Spacer().frame(height: 24)
            
            progressSteps
            
            Spacer()
            
            cancelButton
        }
        .background(AppTheme.Colors.deepNavy)
        .onAppear {
            startAnimations()
        }
    }
    
    private var photoWithOverlays: some View {
        ZStack {
            if let photo = capturedPhoto {
                Image(decorative: photo, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(cornerBracketsOverlay)
                    .overlay(scanningGridOverlay)
                    .overlay(scannerCircleOverlay)
                    .overlay(focusRingOverlay)
                    .overlay(landmarksOverlay)
                    .overlay(glowBorderOverlay)
                    .shadow(color: AppTheme.Colors.accentCyan.opacity(glowIntensity * 0.5), radius: 20)
            } else {
                placeholderView
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    private var cornerBracketsOverlay: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                AnimatedCornerBracket(
                    corner: index,
                    scale: cornerBracketScale,
                    opacity: cornerBracketOpacity
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var scanningGridOverlay: some View {
        ScanningGridOverlay(opacity: gridOpacity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var scannerCircleOverlay: some View {
        GeometryReader { geo in
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.Colors.accentCyan.opacity(0), AppTheme.Colors.accentCyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: min(geo.size.width, geo.size.height) * 0.7)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .rotationEffect(.degrees(scannerRotation))
                .opacity(currentStep >= 1 ? 0.8 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var focusRingOverlay: some View {
        GeometryReader { geo in
            Circle()
                .stroke(AppTheme.Colors.accentCyan, lineWidth: 2)
                .frame(width: 60, height: 60)
                .scaleEffect(focusRingScale)
                .opacity(focusRingOpacity)
                .position(
                    x: earPosition.x * geo.size.width,
                    y: earPosition.y * geo.size.height
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var landmarksOverlay: some View {
        GeometryReader { geo in
            // Connection line
            connectionLine(in: geo)
            
            // Horizontal reference line
            if currentStep >= 3 {
                horizontalReferenceLine(in: geo)
                AngleArcView(
                    center: CGPoint(
                        x: shoulderPosition.x * geo.size.width,
                        y: shoulderPosition.y * geo.size.height
                    ),
                    progress: angleArcProgress
                )
            }
            
            // Landmark dots
            ForEach(0..<3, id: \.self) { index in
                landmarkDot(index: index, in: geo)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private func connectionLine(in geo: GeometryProxy) -> some View {
        Path { path in
            let start = CGPoint(
                x: shoulderPosition.x * geo.size.width,
                y: shoulderPosition.y * geo.size.height
            )
            let end = CGPoint(
                x: earPosition.x * geo.size.width,
                y: earPosition.y * geo.size.height
            )
            path.move(to: start)
            let currentEnd = CGPoint(
                x: start.x + (end.x - start.x) * connectionLineProgress,
                y: start.y + (end.y - start.y) * connectionLineProgress
            )
            path.addLine(to: currentEnd)
        }
        .stroke(
            LinearGradient(
                colors: [.green, AppTheme.Colors.accentCyan],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 3])
        )
        .opacity(currentStep >= 2 ? 1 : 0)
    }
    
    private func horizontalReferenceLine(in geo: GeometryProxy) -> some View {
        Path { path in
            let start = CGPoint(
                x: shoulderPosition.x * geo.size.width,
                y: shoulderPosition.y * geo.size.height
            )
            let end = CGPoint(
                x: (shoulderPosition.x - 0.15) * geo.size.width,
                y: shoulderPosition.y * geo.size.height
            )
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            Color.orange.opacity(0.8),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .opacity(angleArcProgress)
    }
    
    private func landmarkDot(index: Int, in geo: GeometryProxy) -> some View {
        let positions = [earPosition, shoulderPosition, hipPosition]
        let colors: [Color] = [.green, .green, AppTheme.Colors.accentCyan.opacity(0.5)]
        
        return ZStack {
            Circle()
                .fill(colors[index].opacity(0.3))
                .frame(width: 24, height: 24)
                .blur(radius: 4)
            
            Circle()
                .fill(colors[index])
                .frame(width: 12, height: 12)
            
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 4, height: 4)
        }
        .scaleEffect(landmarkScales[index])
        .opacity(landmarkOpacities[index])
        .position(
            x: positions[index].x * geo.size.width,
            y: positions[index].y * geo.size.height
        )
    }
    
    private var glowBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.accentCyan.opacity(glowIntensity),
                        AppTheme.Colors.glowBlue.opacity(glowIntensity * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .blur(radius: 2)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
            .frame(height: 350)
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.Colors.accentCyan)
            )
    }
    
    private var animatedTitle: some View {
        HStack(spacing: 8) {
            Text("Analyzing")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.Colors.accentCyan)
                        .frame(width: 6, height: 6)
                        .offset(y: particleOffset * (index == 1 ? -1 : 1) * CGFloat(index + 1))
                }
            }
        }
    }
    
    private var progressSteps: some View {
        VStack(spacing: 10) {
            ForEach(0..<steps.count, id: \.self) { index in
                EnhancedStepRow(
                    icon: steps[index].icon,
                    text: steps[index].text,
                    state: stepState(for: index)
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
    }
    
    private var cancelButton: some View {
        Button(action: onCancel) {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("Cancel")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.Colors.mutedGray)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.Colors.mutedGray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.bottom, 36)
    }
    
    private func stepState(for index: Int) -> EnhancedStepRow.StepState {
        if index < currentStep {
            return .completed
        } else if index == currentStep {
            return .active
        } else {
            return .pending
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            cornerBracketScale = 1.05
            cornerBracketOpacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            particleOffset = 3
        }
        
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            scannerRotation = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                gridOpacity = 0.15
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                currentStep = 1
            }
            withAnimation(.easeOut(duration: 0.4)) {
                focusRingOpacity = 0.8
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                focusRingScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                currentStep = 2
            }
            withAnimation(.easeOut(duration: 0.3)) {
                gridOpacity = 0
            }
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        landmarkOpacities[i] = 1
                        landmarkScales[i] = 1.0
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    connectionLineProgress = 1.0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                currentStep = 3
            }
            withAnimation(.easeOut(duration: 0.3)) {
                focusRingOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.8)) {
                angleArcProgress = 1.0
            }
        }
    }
}

// MARK: - Animated Corner Bracket
struct AnimatedCornerBracket: View {
    let corner: Int
    let scale: CGFloat
    let opacity: Double
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let length: CGFloat = 35
            let offset: CGFloat = 12
            
            Path { path in
                switch corner {
                case 0:
                    path.move(to: CGPoint(x: offset, y: length + offset))
                    path.addLine(to: CGPoint(x: offset, y: offset))
                    path.addLine(to: CGPoint(x: length + offset, y: offset))
                case 1:
                    path.move(to: CGPoint(x: size.width - length - offset, y: offset))
                    path.addLine(to: CGPoint(x: size.width - offset, y: offset))
                    path.addLine(to: CGPoint(x: size.width - offset, y: length + offset))
                case 2:
                    path.move(to: CGPoint(x: size.width - offset, y: size.height - length - offset))
                    path.addLine(to: CGPoint(x: size.width - offset, y: size.height - offset))
                    path.addLine(to: CGPoint(x: size.width - length - offset, y: size.height - offset))
                case 3:
                    path.move(to: CGPoint(x: length + offset, y: size.height - offset))
                    path.addLine(to: CGPoint(x: offset, y: size.height - offset))
                    path.addLine(to: CGPoint(x: offset, y: size.height - length - offset))
                default:
                    break
                }
            }
            .stroke(
                AppTheme.Colors.accentCyan,
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
    }
}

// MARK: - Scanning Grid Overlay
struct ScanningGridOverlay: View {
    let opacity: Double
    
    var body: some View {
        GeometryReader { geo in
            let horizontalLines = 8
            let verticalLines = 6
            
            ZStack {
                ForEach(0..<horizontalLines, id: \.self) { i in
                    let y = geo.size.height * CGFloat(i + 1) / CGFloat(horizontalLines + 1)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(AppTheme.Colors.accentCyan.opacity(opacity), lineWidth: 0.5)
                }
                
                ForEach(0..<verticalLines, id: \.self) { i in
                    let x = geo.size.width * CGFloat(i + 1) / CGFloat(verticalLines + 1)
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    .stroke(AppTheme.Colors.accentCyan.opacity(opacity), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Angle Arc View
struct AngleArcView: View {
    let center: CGPoint
    let progress: CGFloat
    
    var body: some View {
        Path { path in
            path.addArc(
                center: center,
                radius: 25,
                startAngle: .degrees(180),
                endAngle: .degrees(180 - 50 * Double(progress)),
                clockwise: true
            )
        }
        .stroke(
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
    }
}

// MARK: - Enhanced Step Row
struct EnhancedStepRow: View {
    let icon: String
    let text: String
    let state: StepState
    
    enum StepState {
        case pending, active, completed
    }
    
    @State private var progressWidth: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                
                if state == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .font(.system(size: 15, weight: state == .active ? .semibold : .regular))
                    .foregroundColor(textColor)
                
                if state == .active {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.accentCyan, AppTheme.Colors.glowBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: progressWidth * geo.size.width, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            progressWidth = 1.0
                        }
                    }
                }
            }
            
            Spacer()
            
            if state == .active {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(AppTheme.Colors.accentCyan)
            } else if state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(state == .active ? AppTheme.Colors.primaryBlue.opacity(0.25) : AppTheme.Colors.primaryBlue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            state == .active ? AppTheme.Colors.accentCyan.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var backgroundColor: Color {
        switch state {
        case .pending: return AppTheme.Colors.primaryBlue.opacity(0.3)
        case .active: return AppTheme.Colors.accentCyan.opacity(0.2)
        case .completed: return .green
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .pending: return AppTheme.Colors.mutedGray
        case .active: return AppTheme.Colors.accentCyan
        case .completed: return .white
        }
    }
    
    private var textColor: Color {
        switch state {
        case .pending: return AppTheme.Colors.mutedGray
        case .active: return AppTheme.Colors.softWhite
        case .completed: return .green
        }
    }
}

// MARK: - Legacy Analyzing Step View
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
