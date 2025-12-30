//
//  PhotoHistoryView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

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
                        Text(String(format: "%.1f°", cva))
                            .font(AppTheme.Typography.small)
                    }
                    .foregroundColor(AppTheme.Colors.accentCyan)
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.deepNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Zoomable photo with overlay
                        if let image = photo.image {
                            ZoomablePostureImageView(
                                image: Image(uiImage: image),
                                earPoint: photo.earPoint,
                                shoulderPoint: photo.shoulderPoint,
                                showOverlay: showOverlay
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
                        
                        // Delete button
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Photo", systemImage: "trash")
                                .font(AppTheme.Typography.button)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)
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
            .confirmationDialog(
                "Delete this photo?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deletePhoto()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
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
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Craniovertebral Angle")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                        Text("Ideal: 50°+")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
                    }
                    Spacer()
                    Text(String(format: "%.1f°", cva))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.accentCyan)
                }
            }
            
            Divider().background(AppTheme.Colors.mutedGray.opacity(0.3))
            
            // Forward distance
            if let distance = photo.forwardHeadDistance {
                HStack {
                    Text("Forward Distance")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    Spacer()
                    Text(String(format: "~%.1f cm", distance))
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.softWhite)
                }
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
        modelContext.delete(photo)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    PhotoHistoryView()
        .modelContainer(for: PosturePhoto.self, inMemory: true)
}
