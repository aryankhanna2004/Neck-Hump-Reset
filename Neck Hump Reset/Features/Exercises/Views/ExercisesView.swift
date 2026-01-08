//
//  ExercisesView.swift
//  Neck Hump Reset
//
//  Dead simple exercises - Routines contain multiple exercises
//

import SwiftUI

struct ExercisesView: View {
    @State private var selectedRoutine: ExerciseRoutine? = nil
    @State private var showSources = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercises")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        Text("Pick a routine and follow along")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppTheme.Spacing.md)
                    
                    // Featured Routine
                    featuredSection
                    
                    // All Routines
                    routinesSection
                    
                    // Footer - View Research button
                    footerNote
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, 120)
            }
        }
        .sheet(item: $selectedRoutine) { routine in
            RoutinePlayerView(routine: routine)
        }
        .sheet(isPresented: $showSources) {
            SourcesAndDisclaimerView()
        }
    }
    
    // MARK: - Featured
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Label("Quick Pick", systemImage: "bolt.fill")
                .font(AppTheme.Typography.headline)
                .foregroundColor(.yellow)
            
            if let quickRoutine = ExerciseLibrary.routines.first(where: { $0.name == "Quick 5-Minute Reset" }) {
                FeaturedRoutineCard(routine: quickRoutine) {
                    selectedRoutine = quickRoutine
                }
            }
        }
    }
    
    // MARK: - All Routines
    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("All Routines")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text("Each routine has multiple exercises")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            ForEach(ExerciseLibrary.routines.filter { $0.name != "Quick 5-Minute Reset" }) { routine in
                RoutineCard(routine: routine) {
                    selectedRoutine = routine
                }
            }
        }
    }
    
    private var footerNote: some View {
        Button(action: {
            showSources = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 12))
                Text("View Research Sources")
                    .font(.system(size: 12))
            }
            .foregroundColor(AppTheme.Colors.accentCyan)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.accentCyan.opacity(0.15))
            )
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
}

// MARK: - Featured Routine Card
struct FeaturedRoutineCard: View {
    let routine: ExerciseRoutine
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("5-Minute Reset")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                        
                        Text("Perfect for work breaks")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.buttonGradient)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.deepNavy)
                            .offset(x: 2)
                    }
                    .shadow(color: AppTheme.Colors.accentCyan.opacity(0.4), radius: 10)
                }
                
                // Exercise count
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.number")
                            .font(.system(size: 14))
                        Text("\(routine.exercises.count) exercises")
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text("~5 min")
                    }
                }
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.accentCyan)
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.accentCyan.opacity(0.15),
                                AppTheme.Colors.primaryBlue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Routine Card
struct RoutineCard: View {
    let routine: ExerciseRoutine
    let action: () -> Void
    
    private var routineColor: Color {
        routine.category.color
    }
    
    private var simpleDescription: String {
        switch routine.name {
        case "Isometric Neck Strengthening":
            return "Build strength without moving"
        case "Deep Neck Flexor Training":
            return "Strengthen deep neck muscles"
        case "Proprioception & Balance":
            return "Improve neck awareness"
        case "Neck Stretching":
            return "Release tight muscles"
        case "Postural Correction":
            return "Fix forward head posture"
        default:
            return routine.description
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(routineColor)
                    .frame(width: 4, height: 50)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(routineColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: routine.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(routineColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.softWhite)
                        .lineLimit(1)
                    
                    Text(simpleDescription)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                        .lineLimit(1)
                    
                    // Exercise count badge
                    Text("\(routine.exercises.count) exercises • \(routine.formattedTime)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(routineColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Routine Player View (Full Screen)
struct RoutinePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let routine: ExerciseRoutine
    var onRoutineComplete: (() -> Void)?
    
    @State private var completedExercises: Set<Int> = []
    @State private var showExercisePlayer = false
    @State private var selectedExerciseIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.deepNavy.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    progressBar
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Routine header
                            routineHeader
                            
                            // Exercise list
                            exerciseList
                        }
                        .padding(AppTheme.Spacing.lg)
                        .padding(.bottom, 120)
                    }
                }
                
                // Start/Continue button
                VStack {
                    Spacer()
                    startButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accentCyan)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if completedExercises.count == routine.exercises.count {
                        Button("Done") {
                            onRoutineComplete?()
                            dismiss()
                        }
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    }
                }
            }
            .fullScreenCover(isPresented: $showExercisePlayer) {
                ExercisePlayerView(
                    exercises: routine.exercises,
                    startIndex: selectedExerciseIndex,
                    onComplete: { completedIndex in
                        // Mark this exercise as completed
                        completedExercises.insert(completedIndex)
                        
                        // Check if all exercises are done
                        if completedExercises.count == routine.exercises.count {
                            onRoutineComplete?()
                        }
                    }
                )
            }
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.Colors.primaryBlue.opacity(0.3))
                
                Rectangle()
                    .fill(routine.category.color)
                    .frame(width: geo.size.width * CGFloat(completedExercises.count) / CGFloat(routine.exercises.count))
                    .animation(.spring(response: 0.3), value: completedExercises.count)
            }
        }
        .frame(height: 3)
    }
    
    private var routineHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Category badge
            HStack(spacing: 6) {
                Image(systemName: routine.category.icon)
                Text(routine.category.rawValue)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(routine.category.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(routine.category.color.opacity(0.2))
            )
            
            Text(routine.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.softWhite)
            
            Text(simpleRoutineDescription)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            // Stats
            HStack(spacing: AppTheme.Spacing.lg) {
                statBadge(icon: "list.number", value: "\(routine.exercises.count)", label: "Exercises")
                statBadge(icon: "clock", value: routine.formattedTime, label: "Duration")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var simpleRoutineDescription: String {
        switch routine.name {
        case "Isometric Neck Strengthening":
            return "Push your head against your hands in different directions. This builds strength without straining your neck."
        case "Deep Neck Flexor Training":
            return "Gentle chin tucks that target the deep muscles supporting your neck."
        case "Proprioception & Balance":
            return "Simple exercises to help your brain sense where your neck is."
        case "Neck Stretching":
            return "Gentle stretches to release tension in your neck and shoulders."
        case "Postural Correction":
            return "Exercises to pull your shoulders back and align your head."
        case "Quick 5-Minute Reset":
            return "The most effective exercises combined for a quick break."
        default:
            return routine.description
        }
    }
    
    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accentCyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
        }
    }
    
    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Exercises")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Spacer()
                
                Text("\(completedExercises.count)/\(routine.exercises.count) done")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(completedExercises.count == routine.exercises.count ? .green : AppTheme.Colors.mutedGray)
            }
            
            ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseListItem(
                    exercise: exercise,
                    index: index + 1,
                    isCompleted: completedExercises.contains(index)
                ) {
                    selectedExerciseIndex = index
                    showExercisePlayer = true
                }
            }
        }
    }
    
    private var startButton: some View {
        let nextIncompleteIndex = routine.exercises.indices.first { !completedExercises.contains($0) } ?? 0
        let allComplete = completedExercises.count == routine.exercises.count
        
        return Button(action: {
            if allComplete {
                // All done - close
                onRoutineComplete?()
                dismiss()
            } else {
                selectedExerciseIndex = nextIncompleteIndex
                showExercisePlayer = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: allComplete ? "checkmark.circle.fill" : "play.fill")
                Text(allComplete ? "Routine Complete!" : (completedExercises.isEmpty ? "Start Routine" : "Continue"))
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(allComplete ? .white : AppTheme.Colors.deepNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if allComplete {
                        Color.green
                    } else {
                        AppTheme.Colors.buttonGradient
                    }
                }
            )
            .cornerRadius(16)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.deepNavy.opacity(0), AppTheme.Colors.deepNavy],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        )
    }
}

// MARK: - Exercise List Item
struct ExerciseListItem: View {
    let exercise: Exercise
    let index: Int
    let isCompleted: Bool
    let action: () -> Void
    
    private var simpleName: String {
        ExerciseNames.simple(for: exercise.name)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Number circle
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : AppTheme.Colors.primaryBlue.opacity(0.3))
                        .frame(width: 36, height: 36)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(index)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                    }
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 2) {
                    Text(simpleName)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.softWhite)
                    
                    Text("\(exercise.repetitions) reps × \(exercise.holdTime)s hold")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                
                Spacer()
                
                // Always show play button - allow revisiting
                Image(systemName: isCompleted ? "arrow.counterclockwise.circle" : "play.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? Color.green.opacity(0.6) : AppTheme.Colors.accentCyan.opacity(0.6))
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color.green.opacity(0.05) : AppTheme.Colors.primaryBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCompleted ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        // Don't disable - let users revisit completed exercises
    }
}

// MARK: - Simple Exercise Names Helper
struct ExerciseNames {
    static func simple(for name: String) -> String {
        switch name {
        case "Cervical Flexion Isometric": return "Push Forward"
        case "Cervical Extension Isometric": return "Push Backward"
        case "Right Lateral Flexion Isometric": return "Push Right"
        case "Left Lateral Flexion Isometric": return "Push Left"
        case "Right Rotation Isometric": return "Turn Right"
        case "Left Rotation Isometric": return "Turn Left"
        case "Chin Tuck": return "Chin Tuck"
        case "Chin Tuck with Head Lift": return "Chin Tuck + Lift"
        case "Seated Chin Tuck": return "Wall Chin Tuck"
        case "Head Relocation (Eyes Open)": return "Find Center"
        case "Gaze Stability": return "Focus & Move"
        case "Upper Trapezius Stretch": return "Neck Side Stretch"
        case "Levator Scapulae Stretch": return "Corner Stretch"
        case "Wall Angel": return "Wall Slides"
        case "Scapular Retraction": return "Shoulder Squeeze"
        default: return name
        }
    }
}

// MARK: - Exercise Player View
struct ExercisePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let exercises: [Exercise]
    let startIndex: Int
    var onComplete: ((Int) -> Void)?
    
    @State private var currentIndex: Int
    @State private var currentRep = 1
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var isResting = false
    @State private var showInstructions = true
    @State private var timer: Timer?
    
    init(exercises: [Exercise], startIndex: Int = 0, onComplete: ((Int) -> Void)? = nil) {
        self.exercises = exercises
        self.startIndex = startIndex
        self.onComplete = onComplete
        self._currentIndex = State(initialValue: startIndex)
    }
    
    private var currentExercise: Exercise {
        exercises[currentIndex]
    }
    
    private var simpleName: String {
        ExerciseNames.simple(for: currentExercise.name)
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.deepNavy.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                if showInstructions {
                    instructionsView
                } else {
                    timerView
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: { 
                // Don't auto-complete - just close
                dismiss() 
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .padding(12)
                    .background(Circle().fill(AppTheme.Colors.primaryBlue.opacity(0.3)))
            }
            
            Spacer()
            
            Text("\(currentIndex + 1) of \(exercises.count)")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
            
            Spacer()
            
            // Mark Complete button
            Button(action: {
                onComplete?(currentIndex)
                if currentIndex < exercises.count - 1 {
                    nextExercise()
                } else {
                    dismiss()
                }
            }) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.deepNavy)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.md)
    }
    
    private var instructionsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                // Exercise header - centered
                VStack(spacing: AppTheme.Spacing.md) {
                    // Exercise icon
                    ZStack {
                        Circle()
                            .fill(currentExercise.category.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: currentExercise.iconName)
                            .font(.system(size: 36))
                            .foregroundColor(currentExercise.category.color)
                    }
                    
                    // Simple name (big)
                    Text(simpleName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.Colors.softWhite)
                        .multilineTextAlignment(.center)
                    
                    // Official name (smaller, for reference)
                    if simpleName != currentExercise.name {
                        Text(currentExercise.name)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.mutedGray.opacity(0.7))
                            .italic()
                    }
                    
                    // Quick stats
                    HStack(spacing: AppTheme.Spacing.xl) {
                        VStack(spacing: 4) {
                            Text("\(currentExercise.repetitions)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.Colors.accentCyan)
                            Text("Reps")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.mutedGray)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(currentExercise.holdTime)s")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.Colors.accentCyan)
                            Text("Hold")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.mutedGray)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.lg)
                
                // HOW TO DO IT - Better styled
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack {
                        Image(systemName: "list.number")
                            .foregroundColor(AppTheme.Colors.accentCyan)
                        Text("How To Do It")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.Colors.softWhite)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(currentExercise.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 16) {
                                // Step number
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.Colors.accentCyan)
                                        .frame(width: 28, height: 28)
                                    
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.Colors.deepNavy)
                                }
                                
                                // Instruction text - bigger and clearer
                                Text(instruction)
                                    .font(.system(size: 17))
                                    .foregroundColor(AppTheme.Colors.softWhite)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.Colors.primaryBlue.opacity(0.15))
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                Spacer().frame(height: 120)
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .overlay(alignment: .bottom) {
            Button(action: {
                withAnimation {
                    showInstructions = false
                    startTimer()
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Timer")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.Colors.deepNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.Colors.buttonGradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.deepNavy.opacity(0), AppTheme.Colors.deepNavy],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private var timerView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Big timer circle
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 12)
                    .frame(width: 220, height: 220)
                
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        isResting ? Color.orange : AppTheme.Colors.accentCyan,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text(isResting ? "REST" : "HOLD")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.Colors.mutedGray)
                    
                    Text("\(Int((1 - holdProgress) * Double(isResting ? 5 : currentExercise.holdTime)))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.softWhite)
                }
            }
            
            // Exercise name and rep count
            VStack(spacing: 8) {
                Text(simpleName)
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.softWhite)
                
                Text("Rep \(currentRep) of \(currentExercise.repetitions)")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            
            Spacer()
            
            // Control buttons
            HStack(spacing: AppTheme.Spacing.lg) {
                Button(action: toggleTimer) {
                    HStack {
                        Image(systemName: isHolding ? "pause.fill" : "play.fill")
                        Text(isHolding ? "Pause" : "Resume")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.softWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.Colors.primaryBlue.opacity(0.3))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
    
    private func startTimer() {
        isHolding = true
        let duration = Double(isResting ? 5 : currentExercise.holdTime)
        let startTime = Date()
        let startProgress = holdProgress
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let elapsed = Date().timeIntervalSince(startTime)
            let newProgress = startProgress + (elapsed / duration)
            
            if newProgress >= 1.0 {
                timer?.invalidate()
                holdProgress = 0
                isHolding = false
                
                if isResting {
                    isResting = false
                    startTimer()
                } else {
                    if currentRep < currentExercise.repetitions {
                        currentRep += 1
                        isResting = true
                        startTimer()
                    } else {
                        // Exercise complete
                        if currentIndex < exercises.count - 1 {
                            nextExercise()
                        } else {
                            // All exercises complete
                            onComplete?(currentIndex)
                            dismiss()
                        }
                    }
                }
            } else {
                holdProgress = newProgress
            }
        }
    }
    
    private func toggleTimer() {
        if isHolding {
            timer?.invalidate()
            isHolding = false
        } else {
            startTimer()
        }
    }
    
    private func nextExercise() {
        timer?.invalidate()
        // Report that current exercise was completed
        onComplete?(currentIndex)
        currentIndex += 1
        currentRep = 1
        isHolding = false
        holdProgress = 0
        isResting = false
        showInstructions = true
    }
}

#Preview {
    NavigationStack {
        ExercisesView()
    }
}
