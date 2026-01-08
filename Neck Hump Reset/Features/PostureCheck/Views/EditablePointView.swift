//
//  EditablePointView.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI

// MARK: - Editable Point View
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
        let hitAreaSize: CGFloat = 44 / scale
        
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
        .contentShape(Circle().scale(1.5))
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
                    let newPixelPos = CGPoint(
                        x: pixelPosition.x + value.translation.width,
                        y: pixelPosition.y + value.translation.height
                    )
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
