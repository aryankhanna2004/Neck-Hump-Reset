//
//  ZoomableImageView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

/// A zoomable and pannable image view
struct ZoomableImageView: View {
    let image: Image
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    
    var body: some View {
        GeometryReader { geometry in
            image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = min(max(newScale, minScale), maxScale)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if scale < minScale {
                                        scale = minScale
                                        lastScale = minScale
                                    }
                                }
                            },
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                // Clamp offset within bounds
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    clampOffset(geometry: geometry)
                                }
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if scale > 1.0 {
                            // Reset to normal
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            // Zoom in to 2x
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func clampOffset(geometry: GeometryProxy) {
        let maxX = (geometry.size.width * (scale - 1)) / 2
        let maxY = (geometry.size.height * (scale - 1)) / 2
        
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

/// A zoomable image view that also shows overlay points
struct ZoomablePostureImageView: View {
    let image: Image
    let earPoint: CGPoint?
    let shoulderPoint: CGPoint?
    let showOverlay: Bool
    let imageSize: CGSize? // Actual image dimensions for correct point scaling
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    
    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size
            
            // Calculate actual displayed image size (accounting for .scaledToFit())
            let displayedImageSize: CGSize = {
                guard let imgSize = imageSize else {
                    // Fallback: use canvas size if image size not provided
                    return viewSize
                }
                
                let imageAspectRatio = imgSize.height / imgSize.width
                let viewAspectRatio = viewSize.height / viewSize.width
                
                if imageAspectRatio > viewAspectRatio {
                    // Image is taller - fit to height
                    return CGSize(
                        width: viewSize.height / imageAspectRatio,
                        height: viewSize.height
                    )
                } else {
                    // Image is wider - fit to width
                    return CGSize(
                        width: viewSize.width,
                        height: viewSize.width * imageAspectRatio
                    )
                }
            }()
            
            ZStack {
                image
                    .resizable()
                    .scaledToFit()
                
                // Overlay points and lines
                if showOverlay, let ear = earPoint, let shoulder = shoulderPoint {
                    Canvas { context, canvasSize in
                        // Calculate offset to center the displayed image in the canvas
                        // (since .scaledToFit() centers the image)
                        let offsetX = (canvasSize.width - displayedImageSize.width) / 2
                        let offsetY = (canvasSize.height - displayedImageSize.height) / 2
                        
                        // Use displayed image size for point calculations, not canvas size
                        // Points are normalized (0-1) based on actual image dimensions
                        // Add offset to account for image centering
                        let earPos = CGPoint(
                            x: offsetX + ear.x * displayedImageSize.width,
                            y: offsetY + ear.y * displayedImageSize.height
                        )
                        let shoulderPos = CGPoint(
                            x: offsetX + shoulder.x * displayedImageSize.width,
                            y: offsetY + shoulder.y * displayedImageSize.height
                        )
                        
                        // Draw line from ear to shoulder
                        var linePath = Path()
                        linePath.move(to: earPos)
                        linePath.addLine(to: shoulderPos)
                        context.stroke(linePath, with: .color(.cyan), lineWidth: 3)
                        
                        // Draw vertical reference line from shoulder
                        var verticalPath = Path()
                        verticalPath.move(to: CGPoint(x: shoulderPos.x, y: offsetY))
                        verticalPath.addLine(to: CGPoint(x: shoulderPos.x, y: offsetY + displayedImageSize.height))
                        context.stroke(verticalPath, with: .color(.green.opacity(0.5)), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        
                        // Draw ear point
                        let earRect = CGRect(x: earPos.x - 8, y: earPos.y - 8, width: 16, height: 16)
                        context.fill(Circle().path(in: earRect), with: .color(.cyan))
                        context.stroke(Circle().path(in: earRect), with: .color(.white), lineWidth: 2)
                        
                        // Draw shoulder point
                        let shoulderRect = CGRect(x: shoulderPos.x - 8, y: shoulderPos.y - 8, width: 16, height: 16)
                        context.fill(Circle().path(in: shoulderRect), with: .color(.orange))
                        context.stroke(Circle().path(in: shoulderRect), with: .color(.white), lineWidth: 2)
                    }
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = min(max(newScale, minScale), maxScale)
                        }
                        .onEnded { _ in
                            lastScale = scale
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if scale < minScale {
                                    scale = minScale
                                    lastScale = minScale
                                }
                            }
                        },
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                clampOffset(geometry: geometry)
                            }
                        }
                )
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.0
                        lastScale = 2.0
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func clampOffset(geometry: GeometryProxy) {
        let maxX = (geometry.size.width * (scale - 1)) / 2
        let maxY = (geometry.size.height * (scale - 1)) / 2
        
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

#Preview {
    ZoomableImageView(image: Image(systemName: "person.fill"))
        .frame(width: 300, height: 400)
        .background(Color.black)
}
