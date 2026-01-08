//
//  SettingsPlaceholderView.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var showEditProfile = false
    @State private var showSourcesAndDisclaimer = false
    @State private var showExerciseLibrary = false
    @State private var userProfile = UserProfile.load()
    @Query(sort: \PosturePhoto.timestamp, order: .reverse) private var photos: [PosturePhoto]
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    Text("Settings")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.softWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, AppTheme.Spacing.lg)
                    
                    // Profile Section
                    profileSection
                    
                    // Stats Section
                    statsSection
                    
                    // About Section
                    aboutSection
                    
                    // Debug section - only visible in test mode
                    if AppConfig.testMode {
                        developerOptionsSection
                    }
                    
                    Spacer().frame(height: AppTheme.Spacing.xl)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, 100)
            }
        }
        .alert("Reset Onboarding?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("This will clear your preferences. The app will restart to show onboarding.")
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(userProfile: $userProfile, onSave: {
                userProfile.save()
            })
        }
        .sheet(isPresented: $showSourcesAndDisclaimer) {
            SourcesAndDisclaimerView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppTheme.Colors.accentCyan)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Your Profile")
            
            VStack(spacing: AppTheme.Spacing.md) {
                // Profile summary card
                HStack(spacing: AppTheme.Spacing.md) {
                    // Avatar with initials
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.Colors.accentCyan, AppTheme.Colors.primaryBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        if userProfile.initials.isEmpty {
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        } else {
                            Text(userProfile.initials)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // User's name
                        Text(userProfile.fullName)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        // Situations display
                        if !userProfile.situationsDisplay.isEmpty {
                            Text(userProfile.situationsDisplay.map { $0.icon + " " + $0.title }.joined(separator: ", "))
                                .font(AppTheme.Typography.small)
                                .foregroundColor(AppTheme.Colors.mutedGray)
                                .lineLimit(2)
                        }
                        
                        Text("Member since \(userProfile.memberSince)")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Edit button
                    Button(action: { showEditProfile = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.Colors.accentCyan)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(AppTheme.Colors.accentCyan.opacity(0.2))
                            )
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.Colors.accentCyan.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Profile details
                VStack(spacing: 0) {
                    profileDetailRow(
                        icon: "clock.fill",
                        label: "Screen Time",
                        value: userProfile.screenTimeDisplay?.title ?? "Not set"
                    )
                    
                    Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
                    
                    profileDetailRow(
                        icon: "timer",
                        label: "Daily Commitment",
                        value: userProfile.timeCommitmentDisplay?.title ?? "Not set"
                    )
                    
                    Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
                    
                    profileDetailRow(
                        icon: "figure.walk",
                        label: "Movement Level",
                        value: userProfile.movementComfortDisplay?.title ?? "Not set"
                    )
                    
                    if !userProfile.restrictionsDisplay.isEmpty {
                        Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
                        
                        profileDetailRow(
                            icon: "exclamationmark.triangle.fill",
                            label: "Restrictions",
                            value: userProfile.restrictionsDisplay.map { $0.title }.joined(separator: ", ")
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                )
            }
        }
    }
    
    private func profileDetailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 24)
            
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.softWhite)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(AppTheme.Spacing.md)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Your Progress")
            
            HStack(spacing: AppTheme.Spacing.md) {
                statCard(
                    icon: "camera.fill",
                    value: "\(photos.count)",
                    label: "Checks"
                )
                
                statCard(
                    icon: "flame.fill",
                    value: "\(calculateStreak())",
                    label: "Day Streak"
                )
                
                if let bestScore = photos.compactMap({ $0.postureScore }).max() {
                    statCard(
                        icon: "star.fill",
                        value: "\(bestScore)",
                        label: "Best Score"
                    )
                } else {
                    statCard(
                        icon: "star.fill",
                        value: "-",
                        label: "Best Score"
                    )
                }
            }
        }
    }
    
    private func statCard(icon: String, value: String, label: String) -> some View {
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
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
        )
    }
    
    private func calculateStreak() -> Int {
        guard !photos.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Get unique days with photos
        let photoDays = Set(photos.map { calendar.startOfDay(for: $0.timestamp) })
        
        // Check if today or yesterday has a photo
        if !photoDays.contains(currentDate) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            if !photoDays.contains(yesterday) {
                return 0
            }
            currentDate = yesterday
        }
        
        // Count consecutive days
        while photoDays.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Features")
            
            VStack(spacing: 0) {
                NavigationLink(destination: ExercisesView()) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exercise Library")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.softWhite)
                            
                            Text("Research-backed neck exercises")
                                .font(AppTheme.Typography.small)
                                .foregroundColor(AppTheme.Colors.mutedGray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
            )
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("About")
            
            VStack(spacing: 0) {
                settingsRow(
                    icon: "info.circle.fill",
                    title: "App Version",
                    subtitle: "1.0.0"
                ) {}
                
                Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
                
                settingsRow(
                    icon: "book.fill",
                    title: "Sources & Citations",
                    subtitle: "Research & references"
                ) {
                    showSourcesAndDisclaimer = true
                }
                
                Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
                
                settingsRow(
                    icon: "doc.text.fill",
                    title: "Privacy Policy",
                    subtitle: nil
                ) {
                    // Open privacy policy
                }
                
                Divider().background(AppTheme.Colors.mutedGray.opacity(0.2))
                
                settingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: nil
                ) {
                    // Open help
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
            )
        }
    }
    
    private func settingsRow(icon: String, title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            .padding(AppTheme.Spacing.md)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Colors.mutedGray)
            .textCase(.uppercase)
            .tracking(1)
    }
    
    // MARK: - Developer Options
    private var developerOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header with badge
            HStack {
                Text("Developer Options")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                
                Text("TEST MODE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.Colors.deepNavy)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
            }
            
            // Reset onboarding button
            Button(action: { showResetAlert = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18))
                    Text("Reset Onboarding")
                        .font(AppTheme.Typography.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                .foregroundColor(AppTheme.Colors.softWhite)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                )
            }
            
            Text("Clears preferences and restarts to show onboarding.")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
            
            // Config info
            VStack(alignment: .leading, spacing: 4) {
                configRow(label: "testMode", value: "\(AppConfig.testMode)")
                configRow(label: "alwaysShowOnboarding", value: "\(AppConfig.alwaysShowOnboarding)")
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.top, AppTheme.Spacing.sm)
        }
    }
    
    private func configRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.Colors.mutedGray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(value == "true" ? Color.green : AppTheme.Colors.softWhite)
        }
    }
    
    private func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "user_profile")
        exit(0)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userProfile: UserProfile
    let onSave: () -> Void
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedScreenTime: ScreenTime?
    @State private var selectedSituations: Set<UserSituation> = []
    @State private var selectedTimeCommitment: TimeCommitment?
    @State private var selectedMovementComfort: MovementComfort?
    @State private var selectedRestrictions: Set<ExerciseRestriction> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.deepNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Name Section
                        editSection(title: "Your Name", subtitle: "How should we call you?") {
                            VStack(spacing: AppTheme.Spacing.md) {
                                // First name
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("First Name")
                                        .font(AppTheme.Typography.small)
                                        .foregroundColor(AppTheme.Colors.mutedGray)
                                    
                                    TextField("", text: $firstName)
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.softWhite)
                                        .padding(AppTheme.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                        .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .textContentType(.givenName)
                                }
                                
                                // Last name
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Last Name")
                                            .font(AppTheme.Typography.small)
                                            .foregroundColor(AppTheme.Colors.mutedGray)
                                        Text("(optional)")
                                            .font(AppTheme.Typography.small)
                                            .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.6))
                                    }
                                    
                                    TextField("", text: $lastName)
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.softWhite)
                                        .padding(AppTheme.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                        .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .textContentType(.familyName)
                                }
                            }
                        }
                        
                        // Screen Time
                        editSection(title: "Screen Time", subtitle: "Daily screen/sitting time") {
                            ForEach(ScreenTime.allCases) { time in
                                SelectionCard(
                                    icon: time.icon,
                                    title: time.title,
                                    isSelected: selectedScreenTime == time,
                                    action: { selectedScreenTime = time }
                                )
                            }
                        }
                        
                        // Situations (Multi-select)
                        editSection(title: "Your Situation", subtitle: "Select all that apply") {
                            ForEach(UserSituation.allCases) { situation in
                                MultiSelectCard(
                                    icon: situation.icon,
                                    title: situation.title,
                                    isSelected: selectedSituations.contains(situation),
                                    action: {
                                        if selectedSituations.contains(situation) {
                                            selectedSituations.remove(situation)
                                        } else {
                                            selectedSituations.insert(situation)
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Time Commitment
                        editSection(title: "Daily Commitment", subtitle: "Time you can dedicate") {
                            ForEach(TimeCommitment.allCases) { time in
                                SelectionCard(
                                    icon: time.icon,
                                    title: time.title,
                                    isSelected: selectedTimeCommitment == time,
                                    action: { selectedTimeCommitment = time }
                                )
                            }
                        }
                        
                        // Movement Comfort
                        editSection(title: "Movement Level", subtitle: "Your exercise experience") {
                            ForEach(MovementComfort.allCases) { comfort in
                                SelectionCard(
                                    icon: comfort.icon,
                                    title: comfort.title,
                                    isSelected: selectedMovementComfort == comfort,
                                    action: { selectedMovementComfort = comfort }
                                )
                            }
                        }
                        
                        // Restrictions (if applicable)
                        if selectedMovementComfort == .restrictions {
                            editSection(title: "Restrictions", subtitle: "Select all that apply") {
                                ForEach(ExerciseRestriction.allCases) { restriction in
                                    MultiSelectCard(
                                        icon: restriction.icon,
                                        title: restriction.title,
                                        isSelected: selectedRestrictions.contains(restriction),
                                        action: {
                                            if selectedRestrictions.contains(restriction) {
                                                selectedRestrictions.remove(restriction)
                                            } else {
                                                selectedRestrictions.insert(restriction)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.mutedGray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accentCyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private func editSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text(subtitle)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            content()
        }
    }
    
    private func loadCurrentProfile() {
        firstName = userProfile.firstName ?? ""
        lastName = userProfile.lastName ?? ""
        selectedScreenTime = userProfile.screenTimeDisplay
        selectedSituations = Set(userProfile.situationsDisplay)
        selectedTimeCommitment = userProfile.timeCommitmentDisplay
        selectedMovementComfort = userProfile.movementComfortDisplay
        selectedRestrictions = Set(userProfile.restrictionsDisplay)
    }
    
    private func saveProfile() {
        userProfile.firstName = firstName.trimmingCharacters(in: .whitespaces)
        userProfile.lastName = lastName.trimmingCharacters(in: .whitespaces)
        userProfile.screenTime = selectedScreenTime?.rawValue
        userProfile.situations = selectedSituations.map { $0.rawValue }
        userProfile.timeCommitment = selectedTimeCommitment?.rawValue
        userProfile.movementComfort = selectedMovementComfort?.rawValue
        userProfile.restrictions = selectedRestrictions.map { $0.rawValue }
        onSave()
    }
}

// MARK: - Sources and Disclaimer View
struct SourcesAndDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.deepNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                        // Disclaimer Section
                        disclaimerCard
                        
                        // Research Sources
                        sourcesCard
                    }
                    .padding(AppTheme.Spacing.lg)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Sources & Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accentCyan)
                }
            }
        }
    }
    
    // MARK: - Disclaimer Card
    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                
                Text("Important Disclaimer")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                disclaimerPoint(
                    icon: "graduationcap.fill",
                    title: "Educational Purpose Only",
                    description: "This app is designed for educational and informational purposes only. It is not intended to diagnose, treat, cure, or prevent any disease or health condition."
                )
                
                disclaimerPoint(
                    icon: "stethoscope",
                    title: "Consult Healthcare Professionals",
                    description: "Always seek the advice of a licensed healthcare professional, such as a physician, physical therapist, or chiropractor, for any questions regarding your posture, neck pain, or spinal health."
                )
                
                disclaimerPoint(
                    icon: "person.fill.questionmark",
                    title: "Not Medical Advice",
                    description: "The posture analysis and scores provided by this app should not be used as a substitute for professional medical advice, diagnosis, or treatment."
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    private func disclaimerPoint(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text(description)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Sources Card
    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.accentCyan)
                
                Text("Research Sources")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
            }
            
            // Algorithm Methodology Section
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Measurement Methodology")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text("This app uses the Craniovertebral Angle (CVA) method to assess forward head posture. The CVA is measured as the angle between a horizontal line through C7 (shoulder) and a line from the tragus (ear) to C7.")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: 4) {
                    cvaThresholdRow("CVA > 53°", "Normal posture")
                    cvaThresholdRow("CVA 45-53°", "Mild forward head")
                    cvaThresholdRow("CVA < 45°", "Severe forward head")
                }
                .padding(.vertical, 8)
                
                Text("Based on research by Titcomb et al. (2024): CVA > 53° indicates normal head posture, while CVA < 45° indicates severe forward head posture.")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.8))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.accentCyan.opacity(0.1))
            )
            
            Text("The following peer-reviewed research has informed the development of this app:")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            
            // Primary CVA Research - Titcomb et al. 2024
            researchPaperCard(
                title: "Evaluation of the Craniovertebral Angle in Standing versus Sitting Positions in Young Adults with and without Severe Forward Head Posture",
                authors: "Titcomb DA, Melton BF, Bland HW, Miyashita T",
                journal: "International Journal of Exercise Science",
                year: "2024",
                volume: "17(1):73-85",
                doi: "10.70252/GDNN4363",
                pmcid: "PMC11042887",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11042887/"
            )
            
            // Secondary CVA Research
            researchPaperCard(
                title: "Association between forward head, rounded shoulders, and increased thoracic kyphosis: A review of the literature",
                authors: "Singla D, Veqar Z",
                journal: "Journal of Chiropractic Medicine",
                year: "2017",
                volume: "16(3):220-229",
                doi: "10.1016/j.jcm.2017.03.004",
                pmcid: "PMC5596950",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5596950/"
            )
            
            // Background Research on Cervical Spine
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Background Research:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .padding(.top, 8)
                
                Text("Additional studies on cervical spine health and risk factors:")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            // The paper you provided - as background context
            researchPaperCard(
                title: "Comparison of neck length, relative neck length and height with incidence of cervical spondylosis",
                authors: "Ahmed SB, Qamar A, Imram M, Fahim MF",
                journal: "Pakistan Journal of Medical Sciences",
                year: "2020",
                volume: "36(2):219-223",
                doi: "10.12669/pjms.36.2.832",
                pmcid: "PMC6994911",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6994911/"
            )
            
            // Exercise Protocol Research
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Exercise Protocol Research:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .padding(.top, 8)
                
                Text("The exercise routines in this app are based on the following clinical trials:")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            // Isometric Exercise Research - Sadeghi et al. 2022
            researchPaperCard(
                title: "Effectiveness of isometric exercises on disability and pain of cervical spondylosis: a randomized controlled trial",
                authors: "Sadeghi A, Rostami M, Ameri S, Karimi Moghaddam A, Karimi Moghaddam Z, Zeraatchi A",
                journal: "BMC Sports Science, Medicine and Rehabilitation",
                year: "2022",
                volume: "14:108",
                doi: "10.1186/s13102-022-00500-7",
                pmcid: nil,
                url: "https://bmcsportsscimedrehabil.biomedcentral.com/articles/10.1186/s13102-022-00500-7"
            )
            
            // CCF vs Proprioception Training - Gallego Izquierdo et al. 2016
            researchPaperCard(
                title: "Comparison of cranio-cervical flexion training versus cervical proprioception training in patients with chronic neck pain: A randomized controlled clinical trial",
                authors: "Gallego Izquierdo T, Pecos-Martin D, Lluch Girbés E, Plaza-Manzano G, et al.",
                journal: "Journal of Rehabilitation Medicine",
                year: "2016",
                volume: "48(1):48-55",
                doi: "10.2340/16501977-2034",
                pmcid: nil,
                url: "https://medicaljournalssweden.se/jrm/article/view/5189"
            )
            
            // Deep Neck Flexor Assessment - Jull et al. 2008
            researchPaperCard(
                title: "Clinical assessment of the deep cervical flexor muscles: the craniocervical flexion test",
                authors: "Jull GA, O'Leary SP, Falla DL",
                journal: "Journal of Manipulative and Physiological Therapeutics",
                year: "2008",
                volume: "31(7):525-533",
                doi: "10.1016/j.jmpt.2008.08.003",
                pmcid: nil,
                url: "https://pubmed.ncbi.nlm.nih.gov/18804003/"
            )
            
            // Additional references
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Additional References:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .padding(.top, 8)
                
                referenceRow("Kwon Y, et al. Effect of sitting posture on cervico-thoracic loads - Technology and Health Care (2018)")
                referenceRow("Singh S, et al. Risk factors in cervical spondylosis - J Clin Orthop Trauma (2014)")
                referenceRow("Jull G, et al. A randomized controlled trial of exercise and manipulative therapy for cervicogenic headache - Spine (2002)")
                referenceRow("Falla D, et al. Recruitment of the deep cervical flexor muscles - Manual Therapy (2007)")
                referenceRow("ML Kit Pose Detection - Google Developers Documentation")
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.primaryBlue.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func cvaThresholdRow(_ threshold: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Text(threshold)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.Colors.accentCyan)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
        }
    }
    
    private func researchPaperCard(
        title: String,
        authors: String,
        journal: String,
        year: String,
        volume: String,
        doi: String,
        pmcid: String?,
        url: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.softWhite)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(authors)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Text("\(journal). \(year); \(volume)")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .italic()
            
            HStack {
                Text("DOI: \(doi)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.8))
                
                Spacer()
                
                if let pmcid = pmcid {
                    Text("PMCID: \(pmcid)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.8))
                }
            }
            
            Button(action: {
                if let url = URL(string: url) {
                    openURL(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                    Text(pmcid != nil ? "View on PubMed Central" : "View Full Paper")
                        .font(AppTheme.Typography.small)
                }
                .foregroundColor(AppTheme.Colors.accentCyan)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.Colors.accentCyan.opacity(0.15))
                )
            }
            .padding(.top, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.deepNavy.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.mutedGray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func referenceRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(AppTheme.Colors.mutedGray)
            Text(text)
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SettingsPlaceholderView()
        .modelContainer(for: PosturePhoto.self, inMemory: true)
}
