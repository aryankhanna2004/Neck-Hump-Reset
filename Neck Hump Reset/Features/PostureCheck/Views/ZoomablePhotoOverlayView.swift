//
//  ZoomablePhotoOverlayView.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI

// MARK: - Zoomable Photo Overlay View
struct ZoomablePhotoOverlayView: View {
    let photo: CGImage
    @Binding var earPoint: CGPoint?
    @Binding var shoulderPoint: CGPoint?
    let leftEarPoint: CGPoint?
    let rightEarPoint: CGPoint?
    let selectedEar: EarSelection?
    let isEditingPoints: Bool
    let selectedPoint: EditablePoint?
    let analysisResult: NeckHumpAnalysisResult?
    let onSelectPoint: (EditablePoint) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDraggingPoint: Bool = false
    @State private var anchorPoint: CGPoint = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size
            
            // Calculate actual photo aspect ratio
            let photoAspectRatio = CGFloat(photo.height) / CGFloat(photo.width)
            let contentHeight = viewSize.width * photoAspectRatio
            
            ZStack {
                // The captured photo - use actual aspect ratio
                Image(decorative: photo, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: viewSize.width, height: contentHeight)
                
                // Overlay with lines and points
                if let ear = earPoint, let shoulder = shoulderPoint {
                    Canvas { context, canvasSize in
                        // Canvas size should match the frame (viewSize.width x contentHeight)
                        // Coordinates are normalized (0-1) based on actual photo dimensions
                        // Multiply by canvas size to get pixel positions
                        let earPixel = CGPoint(
                            x: ear.x * canvasSize.width,
                            y: ear.y * canvasSize.height
                        )
                        let shoulderPixel = CGPoint(
                            x: shoulder.x * canvasSize.width,
                            y: shoulder.y * canvasSize.height
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
                        
                        // Draw horizontal reference line through C7 (for CVA measurement)
                        // CVA = angle between this horizontal line and the line from C7 to ear
                        let horizontalLineLength: CGFloat = max(50, abs(earPixel.x - shoulderPixel.x) + 30)
                        var horizontalPath = Path()
                        let horizontalStartX = min(shoulderPixel.x, earPixel.x) - 15
                        let horizontalEndX = max(shoulderPixel.x, earPixel.x) + 15
                        horizontalPath.move(to: CGPoint(x: horizontalStartX, y: shoulderPixel.y))
                        horizontalPath.addLine(to: CGPoint(x: horizontalEndX, y: shoulderPixel.y))
                        context.stroke(
                            horizontalPath,
                            with: .color(.red.opacity(0.6)),
                            style: StrokeStyle(lineWidth: 2, dash: [4, 2])
                        )
                        
                        // Draw forward distance indicator (horizontal line from shoulder to ear's X position)
                        if earPixel.x != shoulderPixel.x {
                            var forwardPath = Path()
                            forwardPath.move(to: CGPoint(x: shoulderPixel.x, y: shoulderPixel.y))
                            forwardPath.addLine(to: CGPoint(x: earPixel.x, y: shoulderPixel.y))
                            context.stroke(
                                forwardPath,
                                with: .color(.yellow.opacity(0.7)),
                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])
                            )
                        }
                        
                        // Draw static points when not editing (smaller size)
                        if !isEditingPoints {
                            let pointRadius: CGFloat = 5
                            
                            // Draw unselected ear (faded) if both ears are available
                            if let leftEar = leftEarPoint, let rightEar = rightEarPoint {
                                let unselectedEar: CGPoint
                                if selectedEar == .left {
                                    unselectedEar = CGPoint(x: rightEar.x * canvasSize.width, y: rightEar.y * canvasSize.height)
                                } else {
                                    unselectedEar = CGPoint(x: leftEar.x * canvasSize.width, y: leftEar.y * canvasSize.height)
                                }
                                
                                let unselectedRect = CGRect(
                                    x: unselectedEar.x - pointRadius,
                                    y: unselectedEar.y - pointRadius,
                                    width: pointRadius * 2,
                                    height: pointRadius * 2
                                )
                                context.fill(Circle().path(in: unselectedRect), with: .color(.cyan.opacity(0.3)))
                                context.stroke(Circle().path(in: unselectedRect), with: .color(.white.opacity(0.5)), lineWidth: 1)
                            }
                            
                            // Selected ear point (full opacity)
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
                    .frame(width: viewSize.width, height: contentHeight)
                    .allowsHitTesting(false)
                    
                    // Draggable points (only in edit mode)
                    if isEditingPoints {
                        // Ear point
                        EditablePointView(
                            normalizedPosition: Binding(
                                get: { ear },
                                set: { earPoint = $0 }
                            ),
                            containerSize: CGSize(width: viewSize.width, height: contentHeight),
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
                            containerSize: CGSize(width: viewSize.width, height: contentHeight),
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
            .frame(width: viewSize.width, height: contentHeight)
            .scaleEffect(scale, anchor: .center)
            .offset(offset)
            .contentShape(Rectangle())
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        guard !isDraggingPoint else { return }
                        let newScale = min(max(lastScale * value, minScale), maxScale)
                        let scaleDelta = newScale / scale
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
                                clampOffset(size: CGSize(width: viewSize.width, height: contentHeight))
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
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
                            clampOffset(size: CGSize(width: viewSize.width, height: contentHeight))
                        }
                    }
            )
            .onTapGesture(count: 2) { location in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        let newScale: CGFloat = 2.5
                        let centerX = viewSize.width / 2
                        let centerY = contentHeight / 2
                        let tapOffsetX = (centerX - location.x) * (newScale - 1)
                        let tapOffsetY = (centerY - location.y) * (newScale - 1)
                        scale = newScale
                        lastScale = newScale
                        offset = CGSize(width: tapOffsetX, height: tapOffsetY)
                        lastOffset = offset
                        clampOffset(size: CGSize(width: viewSize.width, height: contentHeight))
                    }
                }
            }
        }
        .aspectRatio(1/1.3, contentMode: .fit)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
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
