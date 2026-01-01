//
//  ParentActivitySchedulerScreen.swift
//  EduKid
//
//  Created on December 1, 2025.
//  Screen for parents to schedule activities (quizzes, games) for their children
//

import SwiftUI

// MARK: - Parent Activity Scheduler Screen
struct ParentActivitySchedulerScreen: View {
    let child: Child
    @Environment(\.dismiss) var dismiss
    
    @State private var scheduledActivities: [ScheduledActivity] = []
    @State private var showCreateActivity = false
    @State private var isLoading = false
    @State private var activityToDelete: ScheduledActivity?
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .init(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                // Create Activity Button
                Button(action: { showCreateActivity = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Schedule New Activity")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "272052"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Activities List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if scheduledActivities.isEmpty {
                    Spacer()
                    EmptyActivitiesView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(scheduledActivities) { activity in
                                ScheduledActivityCard(
                                    activity: activity,
                                    onDelete: {
                                        activityToDelete = activity
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateActivity) {
            CreateActivityScreen(child: child) { newActivity in
                scheduledActivities.append(newActivity)
                saveActivities()
            }
        }
        .alert("Delete Activity", isPresented: .constant(activityToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                activityToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let activity = activityToDelete {
                    deleteActivity(activity)
                }
            }
        } message: {
            Text("Are you sure you want to delete this scheduled activity?")
        }
        .onAppear {
            loadActivities()
        }
    }
    
    private func loadActivities() {
        isLoading = true
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "scheduled_activities_\(child.id)"),
           let activities = try? JSONDecoder().decode([ScheduledActivity].self, from: data) {
            scheduledActivities = activities.sorted { $0.scheduledTime < $1.scheduledTime }
        }
        isLoading = false
    }
    
    private func saveActivities() {
        if let data = try? JSONEncoder().encode(scheduledActivities) {
            UserDefaults.standard.set(data, forKey: "scheduled_activities_\(child.id)")
        }
    }
    
    private func deleteActivity(_ activity: ScheduledActivity) {
        scheduledActivities.removeAll { $0.id == activity.id }
        saveActivities()
        activityToDelete = nil
    }
}

// MARK: - Scheduled Activity Card
struct ScheduledActivityCard: View {
    let activity: ScheduledActivity
    let onDelete: () -> Void
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var activityIcon: String {
        switch activity.activityType {
        case .quiz:
            return "doc.text.fill"
        case .game:
            return "gamecontroller.fill"
        case .puzzle:
            return "puzzlepiece.fill"
        }
    }
    
    private var activityColor: Color {
        switch activity.activityType {
        case .quiz:
            return .blue
        case .game:
            return .orange
        case .puzzle:
            return .purple
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Activity Icon
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: activityIcon)
                    .font(.title2)
                    .foregroundColor(activityColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(activity.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // Scheduled time and status
                HStack(spacing: 8) {
                    if activity.isAvailable {
                        Label("Available Now", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label(timeRemainingText, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Status and Delete
            VStack(spacing: 8) {
                // Duration
                VStack(spacing: 2) {
                    Text(formattedDuration(activity.duration))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Duration")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .padding(10)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var timeRemainingText: String {
        let remaining = activity.timeRemaining
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "Soon"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours) hour"
            }
        }
    }
}

// MARK: - Empty Activities View
struct EmptyActivitiesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("📅")
                .font(.system(size: 60))
            
            Text("No Scheduled Activities")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("Create your first scheduled activity\nfor your child")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Create Activity Screen
struct CreateActivityScreen: View {
    let child: Child
    let onActivityCreated: (ScheduledActivity) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var activityType: ScheduledActivity.ActivityType = .quiz
    @State private var scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var duration: TimeInterval = 900 // 15 minutes default
    
    // Quiz-specific states
    @State private var showQuizSelection = false
    @State private var selectedQuiz: AIQuizResponse?
    
    // Game-specific states
    @State private var showGameSelection = false
    @State private var selectedGame: ScheduledActivity.GameType?
    
    // Puzzle-specific states
    @State private var showPuzzleSelection = false
    @State private var selectedPuzzle: ScheduledActivity.PuzzleType?
    
    private var title: String {
        if activityType == .quiz, let quiz = selectedQuiz {
            return quiz.meaningfulTitle
        } else if activityType == .game, let game = selectedGame {
            return game.rawValue
        } else if activityType == .puzzle, let puzzle = selectedPuzzle {
            return puzzle.title
        }
        return ""
    }
    
    private var description: String {
        if activityType == .quiz, let quiz = selectedQuiz {
            return "\(quiz.subject.capitalized) - \(quiz.difficulty.capitalized)"
        } else if activityType == .game, let game = selectedGame {
            return game.description
        } else if activityType == .puzzle, let puzzle = selectedPuzzle {
            return puzzle.description
        }
        return ""
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .init(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    // Header
                    Text("📅 Schedule Activity")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Activity Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Type")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ActivityTypeButton(
                                type: .quiz,
                                isSelected: activityType == .quiz,
                                action: { activityType = .quiz }
                            )
                            
                            ActivityTypeButton(
                                type: .game,
                                isSelected: activityType == .game,
                                action: { activityType = .game }
                            )
                            
                            ActivityTypeButton(
                                type: .puzzle,
                                isSelected: activityType == .puzzle,
                                action: { activityType = .puzzle }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Quiz Selection (only for quiz type)
                    if activityType == .quiz {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Quiz")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: { showQuizSelection = true }) {
                                HStack {
                                    if let quiz = selectedQuiz {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(quiz.meaningfulTitle)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: "272052"))
                                            Text("\(quiz.subject.capitalized) - \(quiz.difficulty.capitalized)")
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "272052").opacity(0.7))
                                        }
                                    } else {
                                        Text("Choose a quiz...")
                                            .foregroundColor(Color(hex: "272052").opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "272052"))
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Game Selection (only for game type)
                    if activityType == .game {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Game")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: { showGameSelection = true }) {
                                HStack {
                                    if let game = selectedGame {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(game.rawValue)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: "272052"))
                                            Text(game.description)
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "272052").opacity(0.7))
                                        }
                                    } else {
                                        Text("Choose a game...")
                                            .foregroundColor(Color(hex: "272052").opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "272052"))
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Puzzle Selection (only for puzzle type)
                    if activityType == .puzzle {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Puzzle")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: { showPuzzleSelection = true }) {
                                HStack {
                                    if let puzzle = selectedPuzzle {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(puzzle.title)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: "272052"))
                                            Text(puzzle.description)
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "272052").opacity(0.7))
                                        }
                                    } else {
                                        Text("Choose a puzzle...")
                                            .foregroundColor(Color(hex: "272052").opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "272052"))
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Date & Time Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Schedule For")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker(
                            "",
                            selection: $scheduledDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .colorScheme(.light)
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity Duration Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Duration")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            DurationButton(duration: 900, label: "15 min", selected: duration == 900) {
                                duration = 900
                            }
                            DurationButton(duration: 1800, label: "30 min", selected: duration == 1800) {
                                duration = 1800
                            }
                            DurationButton(duration: 3600, label: "1 hour", selected: duration == 3600) {
                                duration = 3600
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Button
                    Button(action: createActivity) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                            Text("Schedule Activity")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "272052"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .disabled((activityType == .quiz && selectedQuiz == nil) ||
                             (activityType == .game && selectedGame == nil) ||
                             (activityType == .puzzle && selectedPuzzle == nil))
                    .opacity((activityType == .quiz && selectedQuiz == nil) ||
                            (activityType == .game && selectedGame == nil) ||
                            (activityType == .puzzle && selectedPuzzle == nil) ? 0.5 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showQuizSelection) {
            QuizSelectionSheet(
                child: child,
                selectedQuiz: $selectedQuiz,
                onSelect: {
                    showQuizSelection = false
                }
            )
        }
        .sheet(isPresented: $showGameSelection) {
            GameSelectionSheet(
                selectedGame: $selectedGame,
                onSelect: {
                    showGameSelection = false
                }
            )
        }
        .sheet(isPresented: $showPuzzleSelection) {
            PuzzleSelectionSheet(
                child: child,
                selectedPuzzle: $selectedPuzzle,
                onSelect: {
                    showPuzzleSelection = false
                }
            )
        }
    }
    
    private func createActivity() {
        let activity = ScheduledActivity(
            id: UUID().uuidString,
            childId: child.id,
            activityType: activityType,
            title: title,
            description: description,
            scheduledTime: scheduledDate,
            duration: duration,
            isCompleted: false,
            quizData: selectedQuiz,
            gameType: selectedGame,
            puzzleType: selectedPuzzle
        )
        
        onActivityCreated(activity)
        dismiss()
    }
}

// MARK: - Activity Type Button
struct ActivityTypeButton: View {
    let type: ScheduledActivity.ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.rawValue.capitalized)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : type.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? type.color : Color.white)
            .cornerRadius(16)
        }
    }
}

// MARK: - Duration Button
struct DurationButton: View {
    let duration: TimeInterval
    let label: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(selected ? .white : Color(hex: "272052"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color(hex: "272052") : Color.white)
                .cornerRadius(12)
        }
    }
}

// MARK: - Quiz Selection Sheet
struct QuizSelectionSheet: View {
    let child: Child
    @Binding var selectedQuiz: AIQuizResponse?
    let onSelect: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                        Color(red: 0.153, green: 0.125, blue: 0.322)
                    ]),
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if quizzes.isEmpty {
                    VStack(spacing: 16) {
                        Text("📚")
                            .font(.system(size: 60))
                        
                        Text("No Quizzes Available")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Create a quiz first to schedule it")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(quizzes) { quiz in
                                Button(action: {
                                    selectedQuiz = quiz
                                    onSelect()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(quiz.meaningfulTitle)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: "272052"))
                                            
                                            Text("\(quiz.subject.capitalized) • \(quiz.questions.count) questions")
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "272052").opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedQuiz?.id == quiz.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Select Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadQuizzes()
            }
        }
    }
    
    private func loadQuizzes() {
        isLoading = true
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(
                    parentId: parentId,
                    kidId: child.id
                )
                await MainActor.run {
                    // Only show quizzes that haven't been answered
                    quizzes = fetchedQuizzes.filter { !$0.isAnswered }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}


// MARK: - Game Selection Sheet
struct GameSelectionSheet: View {
    @Binding var selectedGame: ScheduledActivity.GameType?
    let onSelect: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    let allGames: [ScheduledActivity.GameType] = [
        .memoryMatch, .colorMatch, .shapeMatch,
        .numberSequence, .mathQuiz, .emojiMatch
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                        Color(red: 0.153, green: 0.125, blue: 0.322)
                    ]),
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(allGames, id: \.self) { game in
                            Button(action: {
                                selectedGame = game
                                onSelect()
                            }) {
                                HStack {
                                    Image(systemName: game.icon)
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "272052"))
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(game.rawValue)
                                            .font(.headline)
                                            .foregroundColor(Color(hex: "272052"))
                                        
                                        Text(game.description)
                                            .font(.subheadline)
                                            .foregroundColor(Color(hex: "272052").opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedGame == game {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Puzzle Selection Sheet
struct PuzzleSelectionSheet: View {
    let child: Child
    @Binding var selectedPuzzle: ScheduledActivity.PuzzleType?
    let onSelect: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var isLoading = false
    
    var allPuzzles: [(id: String, title: String, description: String, isLocal: Bool)] {
        var puzzles: [(id: String, title: String, description: String, isLocal: Bool)] = []
        
        // Add local puzzles
        for puzzle in localPuzzles {
            puzzles.append((
                id: puzzle.id,
                title: puzzle.title,
                description: "\(puzzle.difficulty.displayName) • \(puzzle.gridSize)x\(puzzle.gridSize) • Local",
                isLocal: true
            ))
        }
        
        // Add server puzzles that aren't completed
        for puzzle in serverPuzzles.filter({ !$0.isCompleted }) {
            puzzles.append((
                id: puzzle.id,
                title: puzzle.title,
                description: "\(puzzle.difficulty.capitalized) • \(puzzle.gridSize)x\(puzzle.gridSize) • AI Generated",
                isLocal: false
            ))
        }
        
        return puzzles
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                        Color(red: 0.153, green: 0.125, blue: 0.322)
                    ]),
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if allPuzzles.isEmpty {
                    VStack(spacing: 16) {
                        Text("🧩")
                            .font(.system(size: 60))
                        
                        Text("No Puzzles Available")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Create a puzzle first to schedule it")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(allPuzzles, id: \.id) { puzzle in
                                Button(action: {
                                    selectedPuzzle = ScheduledActivity.PuzzleType(
                                        id: puzzle.id,
                                        title: puzzle.title,
                                        description: puzzle.description,
                                        isLocal: puzzle.isLocal
                                    )
                                    onSelect()
                                }) {
                                    HStack {
                                        Image(systemName: "puzzlepiece.fill")
                                            .font(.title2)
                                            .foregroundColor(Color(hex: "272052"))
                                            .frame(width: 40)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(puzzle.title)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: "272052"))
                                            
                                            Text(puzzle.description)
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "272052").opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedPuzzle?.id == puzzle.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Select Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadPuzzles()
            }
        }
    }
    
    private func loadPuzzles() {
        isLoading = true
        
        // Load local puzzles
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        
        // Load server puzzles
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(
                    parentId: parentId,
                    kidId: child.id
                )
                await MainActor.run {
                    serverPuzzles = fetchedPuzzles
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
