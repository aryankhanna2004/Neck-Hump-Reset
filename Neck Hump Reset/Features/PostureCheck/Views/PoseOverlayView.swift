//
//  PoseOverlayView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI

/// Overlay view that draws real-time neck hump visualization
/// Shows: ear position, shoulder position, ideal alignment line, and forward head distance
struct NeckHumpOverlayView: View {
    let earPoint: CGPoint?
    let shoulderPoint: CGPoint?
    let hipPoint: CGPoint?
    let idealLine: (start: CGPoint, end: CGPoint)?
    let isReady: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw ideal vertical line (where ear should be)
                if let ideal = idealLine {
                    IdealAlignmentLine(
                        start: ideal.start,
                        end: ideal.end,
                        size: geometry.size
                    )
                }
                
                // Draw actual posture line (ear to shoulder)
                if let ear = earPoint, let shoulder = shoulderPoint {
                    ActualPostureLine(
                        ear: ear,
                        shoulder: shoulder,
                        size: geometry.size,
                        isGood: isReady
                    )
                }
                
                // Draw body points
                if let hip = hipPoint {
                    BodyPointMarker(
                        point: hip,
                        size: geometry.size,
                        color: .blue.opacity(0.6),
                        label: nil
                    )
                }
                
                if let shoulder = shoulderPoint {
                    BodyPointMarker(
                        point: shoulder,
                        size: geometry.size,
                        color: AppTheme.Colors.accentCyan,
                        label: "Shoulder"
                    )
                }
                
                if let ear = earPoint {
                    BodyPointMarker(
                        point: ear,
                        size: geometry.size,
                        color: isReady ? .green : .orange,
                        label: "Head"
                    )
                }
                
                // Draw forward distance indicator
                if let ear = earPoint, let shoulder = shoulderPoint {
                    ForwardDistanceIndicator(
                        ear: ear,
                        shoulder: shoulder,
                        size: geometry.size
                    )
                }
            }
        }
    }
}

// MARK: - Ideal Alignment Line
struct IdealAlignmentLine: View {
    let start: CGPoint
    let end: CGPoint
    let size: CGSize
    
    var body: some View {
        Path { path in
            let startPos = CGPoint(x: start.x * size.width, y: start.y * size.height)
            let endPos = CGPoint(x: end.x * size.width, y: end.y * size.height)
            
            path.move(to: startPos)
            path.addLine(to: endPos)
        }
        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
        .foregroundColor(.green.opacity(0.7))
        .shadow(color: .green.opacity(0.3), radius: 4)
    }
}

// MARK: - Actual Posture Line
struct ActualPostureLine: View {
    let ear: CGPoint
    let shoulder: CGPoint
    let size: CGSize
    let isGood: Bool
    
    var body: some View {
        Path { path in
            let earPos = CGPoint(x: ear.x * size.width, y: ear.y * size.height)
            let shoulderPos = CGPoint(x: shoulder.x * size.width, y: shoulder.y * size.height)
            
            path.move(to: shoulderPos)
            path.addLine(to: earPos)
        }
        .stroke(
            LinearGradient(
                colors: [
                    isGood ? .green : .orange,
                    isGood ? .green.opacity(0.6) : .red.opacity(0.6)
                ],
                startPoint: .bottom,
                endPoint: .top
            ),
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .shadow(color: (isGood ? Color.green : Color.orange).opacity(0.5), radius: 6)
    }
}

// MARK: - Body Point Marker
struct BodyPointMarker: View {
    let point: CGPoint
    let size: CGSize
    let color: Color
    let label: String?
    
    var body: some View {
        let position = CGPoint(x: point.x * size.width, y: point.y * size.height)
        
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 30, height: 30)
            
            // Inner circle
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
            
            // Center dot
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
            
            // Label
            if let label = label {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color.opacity(0.8)))
                    .offset(y: -28)
            }
        }
        .position(position)
    }
}

// MARK: - Forward Distance Indicator
struct ForwardDistanceIndicator: View {
    let ear: CGPoint
    let shoulder: CGPoint
    let size: CGSize
    
    var forwardDistance: CGFloat {
        // Horizontal distance between ear and shoulder
        abs(ear.x - shoulder.x) * size.width
    }
    
    var isForward: Bool {
        // In typical camera view, forward head means ear.x < shoulder.x
        ear.x < shoulder.x
    }
    
    var body: some View {
        let earPos = CGPoint(x: ear.x * size.width, y: ear.y * size.height)
        let idealX = shoulder.x * size.width
        
        // Only show if there's noticeable forward head
        if forwardDistance > 10 {
            ZStack {
                // Horizontal line showing the gap
                Path { path in
                    path.move(to: CGPoint(x: earPos.x, y: earPos.y))
                    path.addLine(to: CGPoint(x: idealX, y: earPos.y))
                }
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                
                // Arrow indicators
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(4)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .position(x: (earPos.x + idealX) / 2, y: earPos.y - 20)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        NeckHumpOverlayView(
            earPoint: CGPoint(x: 0.35, y: 0.25),
            shoulderPoint: CGPoint(x: 0.45, y: 0.45),
            hipPoint: CGPoint(x: 0.47, y: 0.7),
            idealLine: (
                start: CGPoint(x: 0.45, y: 0.45),
                end: CGPoint(x: 0.45, y: 0.25)
            ),
            isReady: false
        )
    }
}
