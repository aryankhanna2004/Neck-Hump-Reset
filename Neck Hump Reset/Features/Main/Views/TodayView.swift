//
//  TodayView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @ObservedObject var viewModel: MainViewModel
    @Query(sort: \PosturePhoto.timestamp, order: .reverse) private var photos: [PosturePhoto]
    @State private var contentAppeared = false
    @State private var showPostureCheck = false
    @State private var showSettings = false
    @State private var pulseAnimation = false
    
    // Get today's photos
    private var todayPhotos: [PosturePhoto] {
        let calendar = Calendar.current
        return photos.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    // Get latest photo
    private var latestPhoto: PosturePhoto? {
        photos.first
    }
    
    // Calculate streak
    private var currentStreak: Int {
        guard !photos.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Check if there's a photo today
        let hasPhotoToday = photos.contains { calendar.isDateInToday($0.timestamp) }
        
        // If no photo today, start checking from yesterday
        if !hasPhotoToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else { return 0 }
            currentDate = yesterday
        }
        
        // Count consecutive days with photos
        while true {
            let dayStart = currentDate
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
            
            let hasPhotoOnDay = photos.contains { photo in
                photo.timestamp >= dayStart && photo.timestamp < dayEnd
            }
            
            if hasPhotoOnDay {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    // Average score from last 7 days
    private var weeklyAverageScore: Int? {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return nil }
        
        let recentPhotos = photos.filter { $0.timestamp >= weekAgo && $0.postureScore != nil }
        guard !recentPhotos.isEmpty else { return nil }
        
        let totalScore = recentPhotos.compactMap { $0.postureScore }.reduce(0, +)
        return totalScore / recentPhotos.count
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header with greeting
                    headerSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : -20)
                    
                    // HERO: Posture Check Button
                    postureCheckHero
                        .opacity(contentAppeared ? 1 : 0)
                        .scaleEffect(contentAppeared ? 1 : 0.9)
                    
                    // Today's Progress (if any checks done)
                    if !todayPhotos.isEmpty {
                        todayProgressSection
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                    }
                    
                    // Stats Section
                    statsSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                    
                    // Tips Section
                    tipsSection
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                contentAppeared = true
            }
            // Start pulse animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showPostureCheck) {
            PostureCheckView()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsPlaceholderView()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greetingText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                
                if let name = viewModel.userProfile.firstName, !name.isEmpty {
                    Text("Hi, \(name)!")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.softWhite)
                } else {
                    Text("Ready to reset?")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.softWhite)
                }
            }
            
            Spacer()
            
            // Streak badge
            if currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(currentStreak)")
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.softWhite)
                }
                .font(.system(size: 14))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.2))
                )
            }
            
            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
                    )
            }
        }
        .padding(.top, AppTheme.Spacing.md)
    }
    
    // MARK: - Hero Posture Check
    private var postureCheckHero: some View {
        Button(action: { showPostureCheck = true }) {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Animated icon
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.5)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    // Middle ring
                    Circle()
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.5), lineWidth: 3)
                        .frame(width: 120, height: 120)
                    
                    // Inner circle with gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.Colors.accentCyan.opacity(0.3),
                                    AppTheme.Colors.primaryBlue.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // Icon
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(AppTheme.Colors.accentCyan)
                }
                
                // Text
                VStack(spacing: 8) {
                    Text("Check Your Posture")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    Text("Take a side photo to analyze your neck alignment")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .multilineTextAlignment(.center)
                }
                
                // CTA Button
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Start Check")
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppTheme.Colors.deepNavy)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.buttonGradient)
                .cornerRadius(30)
                .shadow(color: AppTheme.Colors.accentCyan.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.vertical, AppTheme.Spacing.xl)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.primaryBlue.opacity(0.3),
                                AppTheme.Colors.primaryBlue.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppTheme.Colors.accentCyan.opacity(0.5),
                                        AppTheme.Colors.accentCyan.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Today's Progress
    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Today's Progress")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Spacer()
                
                Text("\(todayPhotos.count) check\(todayPhotos.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            // Latest result card
            if let latest = todayPhotos.first, let score = latest.postureScore {
                HStack(spacing: AppTheme.Spacing.md) {
                    // Score circle
                    ZStack {
                        Circle()
                            .stroke(AppTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 6)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(
                                scoreColor(for: score),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(score)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.softWhite)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest Score")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        if let severity = latest.severity {
                            Text(severity.title)
                                .font(AppTheme.Typography.small)
                                .foregroundColor(severityColor(severity))
                        }
                        
                        Text(latest.timeString)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    
                    Spacer()
                    
                    // Improvement indicator
                    if todayPhotos.count > 1,
                       let firstScore = todayPhotos.last?.postureScore,
                       let latestScore = todayPhotos.first?.postureScore {
                        let diff = latestScore - firstScore
                        if diff != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(diff))")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(diff > 0 ? .green : .orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill((diff > 0 ? Color.green : Color.orange).opacity(0.2))
                            )
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                )
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Your Stats")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Streak
                StatCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: .orange
                )
                
                // Total checks
                StatCard(
                    icon: "camera.fill",
                    value: "\(photos.count)",
                    label: "Total Checks",
                    color: AppTheme.Colors.accentCyan
                )
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Weekly average
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: weeklyAverageScore.map { "\($0)" } ?? "-",
                    label: "Weekly Avg",
                    color: .purple
                )
                
                // Best score
                let bestScore = photos.compactMap { $0.postureScore }.max()
                StatCard(
                    icon: "star.fill",
                    value: bestScore.map { "\($0)" } ?? "-",
                    label: "Best Score",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Quick Tips")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                tipRow(icon: "clock", text: "Check your posture every 1-2 hours")
                tipRow(icon: "figure.stand", text: "Stand sideways for best results")
                tipRow(icon: "sun.max", text: "Use good lighting for accurate detection")
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.1))
            )
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Spacer()
        }
    }
    
    private func scoreColor(for score: Int) -> Color {
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
        case .mild: return AppTheme.Colors.accentCyan
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(label)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TodayView(viewModel: MainViewModel())
        .modelContainer(for: PosturePhoto.self, inMemory: true)
}
