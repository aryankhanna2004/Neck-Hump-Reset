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
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                image
                    .resizable()
                    .scaledToFit()
                
                // Overlay points and lines
                if showOverlay, let ear = earPoint, let shoulder = shoulderPoint {
                    Canvas { context, size in
                        let earPos = CGPoint(x: ear.x * size.width, y: ear.y * size.height)
                        let shoulderPos = CGPoint(x: shoulder.x * size.width, y: shoulder.y * size.height)
                        
                        // Draw line from ear to shoulder
                        var linePath = Path()
                        linePath.move(to: earPos)
                        linePath.addLine(to: shoulderPos)
                        context.stroke(linePath, with: .color(.cyan), lineWidth: 3)
                        
                        // Draw vertical reference line from shoulder
                        var verticalPath = Path()
                        verticalPath.move(to: CGPoint(x: shoulderPos.x, y: 0))
                        verticalPath.addLine(to: CGPoint(x: shoulderPos.x, y: size.height))
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
