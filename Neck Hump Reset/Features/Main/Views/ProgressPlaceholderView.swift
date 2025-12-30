//
//  ProgressPlaceholderView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

struct ProgressPlaceholderView: View {
    @Query(sort: \PosturePhoto.timestamp, order: .reverse) private var photos: [PosturePhoto]
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented control
                Picker("View", selection: $selectedTab) {
                    Text("Photos").tag(0)
                    Text("Stats").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
                
                if selectedTab == 0 {
                    PhotoHistoryView()
                } else {
                    statsView
                }
            }
        }
        .navigationTitle("Progress")
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                if photos.isEmpty {
                    emptyStatsView
                } else {
                    // Summary card
                    summaryCard
                    
                    // Progress chart placeholder
                    progressChartCard
                    
                    // Recent checks
                    recentChecksCard
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Empty Stats
    private var emptyStatsView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.accentCyan.opacity(0.4))
            
            Text("No Data Yet")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text("Complete your first posture check to\nstart tracking your progress")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Summary")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            HStack(spacing: AppTheme.Spacing.lg) {
                // Total checks
                statItem(
                    value: "\(photos.count)",
                    label: "Total Checks",
                    icon: "camera.fill"
                )
                
                // Average CVA
                if let avgCVA = averageCVA {
                    statItem(
                        value: String(format: "%.1f°", avgCVA),
                        label: "Avg CVA",
                        icon: "angle"
                    )
                }
                
                // Latest score
                if let latestScore = photos.first?.postureScore {
                    statItem(
                        value: "\(latestScore)",
                        label: "Latest Score",
                        icon: "star.fill"
                    )
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
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.accentCyan)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(label)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Progress Chart Card
    private var progressChartCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("CVA Over Time")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            if photos.count >= 2 {
                // Simple line chart representation
                GeometryReader { geometry in
                    let cvaValues = photos.reversed().compactMap { $0.craniovertebralAngle }
                    if cvaValues.count >= 2 {
                        let minCVA = (cvaValues.min() ?? 30) - 5
                        let maxCVA = (cvaValues.max() ?? 60) + 5
                        let range = maxCVA - minCVA
                        
                        Path { path in
                            for (index, cva) in cvaValues.enumerated() {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(cvaValues.count - 1)
                                let y = geometry.size.height * (1 - CGFloat((cva - minCVA) / range))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(AppTheme.Colors.accentCyan, lineWidth: 2)
                        
                        // Dots
                        ForEach(0..<cvaValues.count, id: \.self) { index in
                            let cva = cvaValues[index]
                            let x = geometry.size.width * CGFloat(index) / CGFloat(cvaValues.count - 1)
                            let y = geometry.size.height * (1 - CGFloat((cva - minCVA) / range))
                            
                            Circle()
                                .fill(AppTheme.Colors.accentCyan)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                        
                        // Ideal line at 50°
                        let idealY = geometry.size.height * (1 - CGFloat((50 - minCVA) / range))
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: idealY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: idealY))
                        }
                        .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    }
                }
                .frame(height: 150)
                
                // Legend
                HStack {
                    Circle()
                        .fill(AppTheme.Colors.accentCyan)
                        .frame(width: 8, height: 8)
                    Text("Your CVA")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    
                    Spacer().frame(width: 20)
                    
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 20, height: 2)
                    Text("Ideal (50°)")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
            } else {
                Text("Take at least 2 posture checks to see your progress chart")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                    .frame(height: 100)
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
    }
    
    // MARK: - Recent Checks Card
    private var recentChecksCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Recent Checks")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            ForEach(photos.prefix(5)) { photo in
                HStack {
                    // Date
                    VStack(alignment: .leading, spacing: 2) {
                        Text(photo.shortDate)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.softWhite)
                        Text(photo.timeString)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    
                    Spacer()
                    
                    // CVA
                    if let cva = photo.craniovertebralAngle {
                        Text(String(format: "%.1f°", cva))
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.accentCyan)
                    }
                    
                    // Severity indicator
                    if let severity = photo.severity {
                        Circle()
                            .fill(severityColor(severity))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.vertical, 8)
                
                if photo.id != photos.prefix(5).last?.id {
                    Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
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
    }
    
    // MARK: - Helpers
    private var averageCVA: Double? {
        let cvaValues = photos.compactMap { $0.craniovertebralAngle }
        guard !cvaValues.isEmpty else { return nil }
        return cvaValues.reduce(0, +) / Double(cvaValues.count)
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

#Preview {
    ProgressPlaceholderView()
        .modelContainer(for: PosturePhoto.self, inMemory: true)
}
