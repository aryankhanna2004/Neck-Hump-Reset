//
//  CameraOverlayViews.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI

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
