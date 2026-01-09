//
//  PhotoHistoryView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

// MARK: - Image Rendering Helper (non-isolated for background thread use)
enum ImageRenderer {
    static func renderWithOverlay(
        baseImage: UIImage?,
        showOverlay: Bool,
        ear: CGPoint?,
        shoulder: CGPoint?
    ) -> UIImage? {
        guard let baseImage = baseImage else { return nil }
        
        if !showOverlay {
            return baseImage
        }
        
        let size = baseImage.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            baseImage.draw(at: .zero)
            
            if let ear = ear, let shoulder = shoulder {
                let earPixel = CGPoint(x: ear.x * size.width, y: ear.y * size.height)
                let shoulderPixel = CGPoint(x: shoulder.x * size.width, y: shoulder.y * size.height)
                
                let linePath = UIBezierPath()
                linePath.move(to: shoulderPixel)
                linePath.addLine(to: earPixel)
                UIColor.cyan.setStroke()
                linePath.lineWidth = 4
                linePath.stroke()
                
                let idealPath = UIBezierPath()
                idealPath.move(to: shoulderPixel)
                idealPath.addLine(to: CGPoint(x: shoulderPixel.x, y: earPixel.y))
                UIColor.green.withAlphaComponent(0.7).setStroke()
                idealPath.lineWidth = 2
                idealPath.setLineDash([8, 4], count: 2, phase: 0)
                idealPath.stroke()
                
                let pointRadius: CGFloat = max(size.width * 0.015, 8)
                
                let earRect = CGRect(
                    x: earPixel.x - pointRadius,
                    y: earPixel.y - pointRadius,
                    width: pointRadius * 2,
                    height: pointRadius * 2
                )
                UIColor.cyan.setFill()
                UIBezierPath(ovalIn: earRect).fill()
                UIColor.white.setStroke()
                let earCircle = UIBezierPath(ovalIn: earRect)
                earCircle.lineWidth = 2
                earCircle.stroke()
                
                let shoulderRect = CGRect(
                    x: shoulderPixel.x - pointRadius,
                    y: shoulderPixel.y - pointRadius,
                    width: pointRadius * 2,
                    height: pointRadius * 2
                )
                UIColor.orange.setFill()
                UIBezierPath(ovalIn: shoulderRect).fill()
                UIColor.white.setStroke()
                let shoulderCircle = UIBezierPath(ovalIn: shoulderRect)
                shoulderCircle.lineWidth = 2
                shoulderCircle.stroke()
            }
        }
    }
}

/// View showing all saved posture photos with timestamps
struct PhotoHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PosturePhoto.timestamp, order: .reverse) private var photos: [PosturePhoto]
    
    @State private var selectedPhoto: PosturePhoto?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationStack {
            Group {
                if photos.isEmpty {
                    emptyStateView
                } else {
                    photoGrid
                }
            }
            .navigationTitle("Progress Photos")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Text("No Photos Yet")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text("Complete a posture check to save your first progress photo.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.deepNavy)
    }
    
    // MARK: - Photo Grid
    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(photos) { photo in
                    PhotoCard(photo: photo)
                        .onTapGesture {
                            selectedPhoto = photo
                        }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.deepNavy)
    }
}

// MARK: - Photo Card
struct PhotoCard: View {
    let photo: PosturePhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo thumbnail
            ZStack {
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppTheme.Colors.mutedGray.opacity(0.3))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(AppTheme.Colors.mutedGray)
                        )
                }
                
                // Severity badge
                if let severity = photo.severity {
                    VStack {
                        HStack {
                            Spacer()
                            Text(severity.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(severityColor(severity)))
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(photo.shortDate)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text(photo.timeString)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                
                if let cva = photo.craniovertebralAngle {
                    HStack(spacing: 4) {
                        Image(systemName: "angle")
                            .font(.system(size: 10))
                        Text("CVA: \(String(format: "%.0f°", cva))")
                            .font(AppTheme.Typography.small)
                    }
                    .foregroundColor(cva >= 50 ? .green : .orange)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.deepNavy.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.mutedGray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func severityColor(_ severity: HumpSeverity) -> Color {
        switch severity {
        case .minimal: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: PosturePhoto
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var showOverlay = true
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var isSharing = false
    @State private var isSaving = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.deepNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Zoomable photo with overlay
                        if let image = photo.image {
                            // Get actual pixel dimensions from CGImage (orientation-independent)
                            let imageSize: CGSize? = image.cgImage.map { 
                                CGSize(width: $0.width, height: $0.height) 
                            }
                            
                            ZoomablePostureImageView(
                                image: Image(uiImage: image),
                                earPoint: photo.earPoint,
                                shoulderPoint: photo.shoulderPoint,
                                showOverlay: showOverlay,
                                imageSize: imageSize
                            )
                            .frame(height: 400)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.Colors.mutedGray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                        }
                        
                        // Toggle overlay
                        Toggle(isOn: $showOverlay) {
                            Label("Show Detection Points", systemImage: "eye")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.softWhite)
                        }
                        .tint(AppTheme.Colors.accentCyan)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        
                        // Date info
                        VStack(spacing: 4) {
                            Text(photo.formattedDate)
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.softWhite)
                            
                            Text(photo.relativeDate)
                                .font(AppTheme.Typography.small)
                                .foregroundColor(AppTheme.Colors.mutedGray)
                        }
                        
                        // Metrics
                        metricsCard
                        
                        // Share/Save buttons
                        shareAndSaveButtons
                        
                        // Delete button
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 8) {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "trash")
                                }
                                Text("Delete Photo")
                            }
                            .font(AppTheme.Typography.button)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .disabled(isDeleting)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Delete this photo?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePhoto()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Saved!", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Photo saved to your photo library.")
            }
            .alert("Error", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Could not save photo. Please check your privacy settings.")
            }
        }
    }
    
    // MARK: - Share and Save Buttons
    private var shareAndSaveButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Share button
            Button(action: shareResults) {
                HStack(spacing: 8) {
                    if isSharing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.softWhite))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                    }
                    Text("Share")
                        .font(AppTheme.Typography.button)
                }
                .foregroundColor(AppTheme.Colors.softWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.primaryBlue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Colors.accentCyan.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .disabled(isSharing || isSaving)
            
            // Save to Photos button
            Button(action: saveToPhotos) {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.deepNavy))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 16))
                    }
                    Text("Save")
                        .font(AppTheme.Typography.button)
                }
                .foregroundColor(AppTheme.Colors.deepNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.accentCyan)
                )
            }
            .disabled(isSharing || isSaving)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.md)
    }
    
    // MARK: - Share Text
    private var shareText: String {
        var text = "My Posture Check Results\n"
        text += "📅 \(photo.formattedDate)\n"
        
        if let severity = photo.severity {
            text += "📊 Assessment: \(severity.rawValue)\n"
        }
        if let cva = photo.craniovertebralAngle {
            text += "📐 CVA: \(String(format: "%.1f°", cva))\n"
        }
        if let score = photo.postureScore {
            text += "⭐ Score: \(score)/100\n"
        }
        
        text += "\n#PostureCheck #NeckHumpReset"
        return text
    }
    
    // MARK: - Actions
    private func shareResults() {
        guard !isSharing && !isSaving else { return }
        isSharing = true
        
        // Capture values needed for background processing
        let baseImage = photo.image
        let shouldShowOverlay = showOverlay
        let ear = photo.earPoint
        let shoulder = photo.shoulderPoint
        let text = shareText
        
        Task {
            let image = await Task.detached(priority: .userInitiated) {
                ImageRenderer.renderWithOverlay(
                    baseImage: baseImage,
                    showOverlay: shouldShowOverlay,
                    ear: ear,
                    shoulder: shoulder
                )
            }.value
            
            isSharing = false
            if let image = image {
                presentShareSheet(items: [image, text])
            }
        }
    }
    
    private func saveToPhotos() {
        guard !isSharing && !isSaving else { return }
        isSaving = true
        
        // Capture values needed for background processing
        let baseImage = photo.image
        let shouldShowOverlay = showOverlay
        let ear = photo.earPoint
        let shoulder = photo.shoulderPoint
        
        Task {
            let image = await Task.detached(priority: .userInitiated) {
                ImageRenderer.renderWithOverlay(
                    baseImage: baseImage,
                    showOverlay: shouldShowOverlay,
                    ear: ear,
                    shoulder: shoulder
                )
            }.value
            
            isSaving = false
            if let image = image {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                showSaveSuccess = true
            } else {
                showSaveError = true
            }
        }
    }
    
    // MARK: - Metrics Card
    private var metricsCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Severity
            if let severity = photo.severity {
                HStack {
                    Text("Assessment")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Spacer()
                    Text(severity.rawValue)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(severityColor(severity))
                }
            }
            
            Divider().background(AppTheme.Colors.mutedGray.opacity(0.3))
            
            // CVA
            if let cva = photo.craniovertebralAngle {
                HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                    // Left side - Label and explanation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CVA")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        Text("Craniovertebral Angle")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.mutedGray)
                        
                        Text("Normal: >53°")
                            .font(.system(size: 10))
                            .foregroundColor(cva >= 50 ? .green.opacity(0.8) : .orange.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Right side - Big value
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f°", cva))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(cva >= 50 ? .green : .orange)
                        
                        Text(cva >= 53 ? "Good" : (cva >= 45 ? "Mild" : "Needs work"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(cva >= 50 ? .green.opacity(0.8) : .orange.opacity(0.8))
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                )
            }
            
            // Forward distance
            if let distance = photo.forwardHeadDistance {
                HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                    // Left side - Label
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Forward Head")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        Text("Distance from ideal")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.mutedGray)
                        
                        Text("Less is better")
                            .font(.system(size: 10))
                            .foregroundColor(distance < 3 ? .green.opacity(0.8) : .orange.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Right side - Value
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f", distance))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(distance < 3 ? .green : .orange)
                        + Text(" cm")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(distance < 3 ? .green.opacity(0.7) : .orange.opacity(0.7))
                        
                        Text(distance < 2 ? "Aligned" : (distance < 4 ? "Slight" : "Forward"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(distance < 3 ? .green.opacity(0.8) : .orange.opacity(0.8))
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                )
            }
            
            // Score
            if let score = photo.postureScore {
                Divider().background(AppTheme.Colors.mutedGray.opacity(0.3))
                
                HStack {
                    Text("Posture Score")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Spacer()
                    Text("\(score)/100")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(scoreColor(score))
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.deepNavy.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.mutedGray.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    private func severityColor(_ severity: HumpSeverity) -> Color {
        switch severity {
        case .minimal: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private func deletePhoto() {
        isDeleting = true
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            modelContext.delete(photo)
            try? modelContext.save()
            dismiss()
        }
    }
    
    private func presentShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            let bounds = rootViewController.view.bounds
            popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(activityVC, animated: true)
    }
}

// MARK: - Preview
#Preview {
    PhotoHistoryView()
        .modelContainer(for: PosturePhoto.self, inMemory: true)
}
