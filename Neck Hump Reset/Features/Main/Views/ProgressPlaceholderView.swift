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
    @State private var selectedTimeRange: TimeRange = .allTime
    
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
                    // Time range selector
                    timeRangeSelector
                    
                    // Summary cards
                    summaryCards
                    
                    // CVA Progress Chart
                    cvaProgressChartCard
                    
                    // Forward Head Distance Chart
                    forwardHeadDistanceChartCard
                    
                    // Posture Score Chart
                    postureScoreChartCard
                    
                    // Detailed Statistics
                    detailedStatsCard
                    
                    // Recent checks
                    recentChecksCard
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Filtered Photos
    private var filteredPhotos: [PosturePhoto] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .lastWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return photos.filter { $0.timestamp >= weekAgo }
        case .lastMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return photos.filter { $0.timestamp >= monthAgo }
        case .allTime:
            return photos
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            timeRangeButton(
                range: .lastWeek,
                icon: "calendar",
                label: "Week",
                subtitle: weekCountText
            )
            
            timeRangeButton(
                range: .lastMonth,
                icon: "calendar.badge.clock",
                label: "Month",
                subtitle: monthCountText
            )
            
            timeRangeButton(
                range: .allTime,
                icon: "infinity",
                label: "All Time",
                subtitle: "\(photos.count) checks"
            )
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
    
    private var weekCountText: String {
        let now = Date()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let count = photos.filter { $0.timestamp >= weekAgo }.count
        return count > 0 ? "\(count) checks" : "7 days"
    }
    
    private var monthCountText: String {
        let now = Date()
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let count = photos.filter { $0.timestamp >= monthAgo }.count
        return count > 0 ? "\(count) checks" : "30 days"
    }
    
    private func timeRangeButton(
        range: TimeRange,
        icon: String,
        label: String,
        subtitle: String
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTimeRange = range
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTimeRange == range ? AppTheme.Colors.accentCyan : AppTheme.Colors.mutedGray)
                
                Text(label)
                    .font(.system(size: 13, weight: selectedTimeRange == range ? .semibold : .regular))
                    .foregroundColor(selectedTimeRange == range ? AppTheme.Colors.softWhite : AppTheme.Colors.mutedGray)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(selectedTimeRange == range ? AppTheme.Colors.accentCyan.opacity(0.7) : AppTheme.Colors.mutedGray.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedTimeRange == range ? AppTheme.Colors.accentCyan.opacity(0.15) : AppTheme.Colors.deepNavy.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedTimeRange == range ? AppTheme.Colors.accentCyan.opacity(0.5) : AppTheme.Colors.mutedGray.opacity(0.2),
                                lineWidth: selectedTimeRange == range ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Top row
            HStack(spacing: AppTheme.Spacing.md) {
                // Total checks
                statCard(
                    value: "\(filteredPhotos.count)",
                    label: "Checks",
                    icon: "camera.fill",
                    color: .cyan
                )
                
                // Average CVA
                if let avgCVA = averageCVA {
                    statCard(
                        value: String(format: "%.1f°", avgCVA),
                        label: "Avg CVA",
                        icon: "angle",
                        color: avgCVA >= 50 ? .green : .orange,
                        trend: cvaTrend
                    )
                }
            }
            
            // Bottom row
            HStack(spacing: AppTheme.Spacing.md) {
                // Best CVA
                if let bestCVA = bestCVA {
                    statCard(
                        value: String(format: "%.1f°", bestCVA),
                        label: "Best CVA",
                        icon: "arrow.up.circle.fill",
                        color: .green
                    )
                }
                
                // Latest score
                if let latestScore = filteredPhotos.first?.postureScore {
                    statCard(
                        value: "\(latestScore)",
                        label: "Latest Score",
                        icon: "star.fill",
                        color: scoreColor(latestScore)
                    )
                }
            }
        }
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color, trend: Trend? = nil) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12))
                        .foregroundColor(trend.color)
                }
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(label)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.deepNavy.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
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
    
    // MARK: - CVA Progress Chart Card
    private var cvaProgressChartCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CVA Over Time")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    if let trend = cvaTrend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10))
                            Text(trend.description)
                                .font(AppTheme.Typography.small)
                        }
                        .foregroundColor(trend.color)
                    }
                }
                Spacer()
            }
            
            if filteredPhotos.count >= 2 {
                enhancedLineChart(
                    values: filteredPhotos.reversed().compactMap { $0.craniovertebralAngle },
                    dates: filteredPhotos.reversed().map { $0.timestamp },
                    color: AppTheme.Colors.accentCyan,
                    minValue: 30,
                    maxValue: 70,
                    referenceLine: 50,
                    referenceLabel: "Ideal (50°)",
                    yAxisLabel: "CVA (°)"
                )
            } else {
                Text("Take at least 2 posture checks to see your progress chart")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                    .frame(height: 150)
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
    
    // MARK: - Forward Head Distance Chart Card
    private var forwardHeadDistanceChartCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Forward Head Distance")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            if filteredPhotos.count >= 2 {
                let distances = filteredPhotos.reversed().compactMap { $0.forwardHeadDistance }
                if !distances.isEmpty {
                    enhancedLineChart(
                        values: distances,
                        dates: filteredPhotos.reversed().map { $0.timestamp },
                        color: .orange,
                        minValue: 0,
                        maxValue: max(distances.max() ?? 10, 10),
                        referenceLine: nil,
                        referenceLabel: nil,
                        yAxisLabel: "Distance (cm)",
                        invertY: true // Lower is better
                    )
                }
            } else {
                Text("Take at least 2 posture checks to see your progress chart")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                    .frame(height: 150)
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
    
    // MARK: - Posture Score Chart Card
    private var postureScoreChartCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Posture Score")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            if filteredPhotos.count >= 2 {
                let scores = filteredPhotos.reversed().compactMap { $0.postureScore }.map { Double($0) }
                if !scores.isEmpty {
                    enhancedLineChart(
                        values: scores,
                        dates: filteredPhotos.reversed().map { $0.timestamp },
                        color: .green,
                        minValue: 0,
                        maxValue: 100,
                        referenceLine: 80,
                        referenceLabel: "Good (80)",
                        yAxisLabel: "Score"
                    )
                }
            } else {
                Text("Take at least 2 posture checks to see your progress chart")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .multilineTextAlignment(.center)
                    .frame(height: 150)
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
    
    // MARK: - Enhanced Line Chart
    private func enhancedLineChart(
        values: [Double],
        dates: [Date],
        color: Color,
        minValue: Double,
        maxValue: Double,
        referenceLine: Double?,
        referenceLabel: String?,
        yAxisLabel: String,
        invertY: Bool = false
    ) -> some View {
        GeometryReader { geometry in
            let chartHeight: CGFloat = 180
            let chartWidth = geometry.size.width - 40 // Padding for Y-axis
            let padding: CGFloat = 20
            
            let range = maxValue - minValue
            let adjustedMin = minValue - (range * 0.1) // Add 10% padding
            let adjustedMax = maxValue + (range * 0.1)
            let adjustedRange = adjustedMax - adjustedMin
            
            ZStack {
                // Grid lines
                ForEach(0..<5) { i in
                    let yValue = adjustedMin + (adjustedRange * Double(i) / 4)
                    let y = padding + chartHeight * (1 - CGFloat((yValue - adjustedMin) / adjustedRange))
                    
                    Path { path in
                        path.move(to: CGPoint(x: padding, y: y))
                        path.addLine(to: CGPoint(x: padding + chartWidth, y: y))
                    }
                    .stroke(AppTheme.Colors.mutedGray.opacity(0.2), lineWidth: 0.5)
                    
                    // Y-axis labels
                    Text(String(format: "%.0f", yValue))
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .position(x: padding - 15, y: y)
                }
                
                // Reference line
                if let refLine = referenceLine, refLine >= adjustedMin && refLine <= adjustedMax {
                    let refY = padding + chartHeight * (1 - CGFloat((refLine - adjustedMin) / adjustedRange))
                    
                    // Draw line in two segments with gap for label
                    if let label = referenceLabel {
                        let labelX = padding + chartWidth - 50
                        let labelWidth: CGFloat = 45
                        
                        // Left segment
                        Path { path in
                            path.move(to: CGPoint(x: padding, y: refY))
                            path.addLine(to: CGPoint(x: labelX - 5, y: refY))
                        }
                        .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        
                        // Right segment (after label)
                        Path { path in
                            path.move(to: CGPoint(x: labelX + labelWidth + 5, y: refY))
                            path.addLine(to: CGPoint(x: padding + chartWidth, y: refY))
                        }
                        .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        
                        // Label with background
                        Text(label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.Colors.deepNavy.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .position(x: labelX + labelWidth / 2, y: refY - 2)
                    } else {
                        // No label, draw full line
                        Path { path in
                            path.move(to: CGPoint(x: padding, y: refY))
                            path.addLine(to: CGPoint(x: padding + chartWidth, y: refY))
                        }
                        .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    }
                }
                
                // Data line
                if values.count >= 2 {
                    Path { path in
                        for (index, value) in values.enumerated() {
                            let x = padding + chartWidth * CGFloat(index) / CGFloat(values.count - 1)
                            let normalizedValue = invertY ? (adjustedMax - value) : (value - adjustedMin)
                            let y = padding + chartHeight * (1 - CGFloat(normalizedValue / adjustedRange))
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, lineWidth: 3)
                    
                    // Fill area under curve
                    Path { path in
                        for (index, value) in values.enumerated() {
                            let x = padding + chartWidth * CGFloat(index) / CGFloat(values.count - 1)
                            let normalizedValue = invertY ? (adjustedMax - value) : (value - adjustedMin)
                            let y = padding + chartHeight * (1 - CGFloat(normalizedValue / adjustedRange))
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: padding + chartHeight))
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        // Close the path
                        if let lastValue = values.last {
                            let lastX = padding + chartWidth
                            let normalizedValue = invertY ? (adjustedMax - lastValue) : (lastValue - adjustedMin)
                            let lastY = padding + chartHeight * (1 - CGFloat(normalizedValue / adjustedRange))
                            path.addLine(to: CGPoint(x: lastX, y: padding + chartHeight))
                            path.addLine(to: CGPoint(x: padding, y: padding + chartHeight))
                        }
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Data points
                    ForEach(0..<values.count, id: \.self) { index in
                        let value = values[index]
                        let x = padding + chartWidth * CGFloat(index) / CGFloat(values.count - 1)
                        let normalizedValue = invertY ? (adjustedMax - value) : (value - adjustedMin)
                        let y = padding + chartHeight * (1 - CGFloat(normalizedValue / adjustedRange))
                        
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .frame(height: 220)
    }
    
    // MARK: - Detailed Stats Card
    private var detailedStatsCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Detailed Statistics")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                Spacer()
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                if let bestCVA = bestCVA, let worstCVA = worstCVA {
                    statRow(label: "Best CVA", value: String(format: "%.1f°", bestCVA), color: .green)
                    statRow(label: "Worst CVA", value: String(format: "%.1f°", worstCVA), color: .red)
                }
                
                if let avgDistance = averageForwardHeadDistance {
                    statRow(label: "Avg Forward Head", value: String(format: "%.1f cm", avgDistance), color: .orange)
                }
                
                if let improvement = cvaImprovement {
                    statRow(
                        label: "CVA Improvement",
                        value: String(format: "%.1f°", abs(improvement)),
                        color: improvement > 0 ? .green : .red,
                        showTrend: true,
                        isPositive: improvement > 0
                    )
                }
                
                statRow(label: "Total Checks", value: "\(filteredPhotos.count)", color: .cyan)
                
                if let streak = currentStreak {
                    statRow(label: "Current Streak", value: "\(streak) days", color: .yellow)
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
    
    private func statRow(label: String, value: String, color: Color, showTrend: Bool = false, isPositive: Bool = true) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Spacer()
            
            if showTrend {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10))
                    .foregroundColor(isPositive ? .green : .red)
            }
            
            Text(value)
                .font(AppTheme.Typography.headline)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
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
            
            ForEach(filteredPhotos.prefix(5)) { photo in
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
                
                if photo.id != filteredPhotos.prefix(5).last?.id {
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
        let cvaValues = filteredPhotos.compactMap { $0.craniovertebralAngle }
        guard !cvaValues.isEmpty else { return nil }
        return cvaValues.reduce(0, +) / Double(cvaValues.count)
    }
    
    private var bestCVA: Double? {
        filteredPhotos.compactMap { $0.craniovertebralAngle }.max()
    }
    
    private var worstCVA: Double? {
        filteredPhotos.compactMap { $0.craniovertebralAngle }.min()
    }
    
    private var averageForwardHeadDistance: Double? {
        let distances = filteredPhotos.compactMap { $0.forwardHeadDistance }
        guard !distances.isEmpty else { return nil }
        return distances.reduce(0, +) / Double(distances.count)
    }
    
    private var cvaTrend: Trend? {
        guard filteredPhotos.count >= 2 else { return nil }
        let cvaValues = filteredPhotos.compactMap { $0.craniovertebralAngle }
        guard cvaValues.count >= 2 else { return nil }
        
        let firstHalf = Array(cvaValues.prefix(cvaValues.count / 2))
        let secondHalf = Array(cvaValues.suffix(cvaValues.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let diff = secondAvg - firstAvg
        if abs(diff) < 1.0 {
            return Trend(icon: "minus", color: .gray, description: "Stable")
        } else if diff > 0 {
            return Trend(icon: "arrow.up.right", color: .green, description: "Improving")
        } else {
            return Trend(icon: "arrow.down.right", color: .red, description: "Declining")
        }
    }
    
    private var cvaImprovement: Double? {
        guard filteredPhotos.count >= 2 else { return nil }
        let sorted = filteredPhotos.sorted { $0.timestamp < $1.timestamp }
        guard let first = sorted.first?.craniovertebralAngle,
              let last = sorted.last?.craniovertebralAngle else { return nil }
        return last - first
    }
    
    private var currentStreak: Int? {
        guard !filteredPhotos.isEmpty else { return nil }
        let calendar = Calendar.current
        let sorted = filteredPhotos.sorted { $0.timestamp > $1.timestamp }
        
        // Group photos by day
        var datesWithPhotos = Set<Date>()
        for photo in sorted {
            let day = calendar.startOfDay(for: photo.timestamp)
            datesWithPhotos.insert(day)
        }
        
        // Count consecutive days from today backwards
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while datesWithPhotos.contains(checkDate) {
            streak += 1
            if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                checkDate = previousDay
            } else {
                break
            }
        }
        
        return streak > 0 ? streak : nil
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
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

// MARK: - Supporting Types
enum TimeRange {
    case lastWeek
    case lastMonth
    case allTime
}

struct Trend {
    let icon: String
    let color: Color
    let description: String
}

#Preview {
    ProgressPlaceholderView()
        .modelContainer(for: PosturePhoto.self, inMemory: true)
}
