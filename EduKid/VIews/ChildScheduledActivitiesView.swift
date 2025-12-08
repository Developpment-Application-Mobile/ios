//
//  ChildScheduledActivitiesView.swift
//  EduKid
//
//  Created on December 1, 2025.
//  Screen for children to view and start activities scheduled by their parents
//

import SwiftUI
import UIKit


// MARK: - Child Scheduled Activities View
struct ChildScheduledActivitiesView: View {
    let child: Child
    let onQuizCompleted: () -> Void
    
    @State private var scheduledActivities: [ScheduledActivity] = []
    @State private var selectedActivity: ScheduledActivity?
    @State private var showQuizTaking = false
    @State private var showGameScreen = false
    @State private var showPuzzleScreen = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var availableActivities: [ScheduledActivity] {
        scheduledActivities.filter { $0.isAvailable && !$0.isCompleted }
    }
    
    var upcomingActivities: [ScheduledActivity] {
        scheduledActivities.filter { !$0.isAvailable && !$0.isCompleted }
    }
    
    var completedActivities: [ScheduledActivity] {
        scheduledActivities.filter { $0.isCompleted }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if scheduledActivities.isEmpty {
                ChildEmptyState(
                    icon: "calendar.badge.clock",
                    title: "No scheduled activities",
                    message: "Your parent hasn't scheduled any activities yet"
                )
            } else {
                // Available Now Section
                if !availableActivities.isEmpty {
                    ChildSectionHeader(title: "Available Now! 🎉", icon: "play.circle.fill")
                    
                    ForEach(availableActivities) { activity in
                        ChildActivityCard(
                            activity: activity,
                            isAvailable: true,
                            onTap: {
                                startActivity(activity)
                            }
                        )
                    }
                }
                
                // Coming Soon Section
                if !upcomingActivities.isEmpty {
                    ChildSectionHeader(title: "Coming Soon ⏰", icon: "clock.fill")
                    
                    ForEach(upcomingActivities) { activity in
                        ChildActivityCard(
                            activity: activity,
                            isAvailable: false,
                            onTap: nil
                        )
                    }
                }
                
                // Completed Section
                if !completedActivities.isEmpty {
                    ChildSectionHeader(title: "Completed ✅", icon: "checkmark.circle.fill")
                    
                    ForEach(completedActivities.prefix(3)) { activity in
                        ChildCompletedActivityCard(activity: activity)
                    }
                }
            }
        }
        .onAppear {
            loadActivities()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            // Reload to update availability
            if scheduledActivities.contains(where: { !$0.isAvailable && $0.scheduledTime <= Date() }) {
                loadActivities()
            }
        }
        .sheet(isPresented: $showQuizTaking) {
            if let activity = selectedActivity,
               let quizData = activity.quizData {
                NavigationStack {
                    QuizTakingScreen(
                        quiz: quizData,
                        child: child,
                        onQuizCompleted: {
                            markActivityCompleted(activity)
                            onQuizCompleted()
                            showQuizTaking = false
                        }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showGameScreen) {
            if let activity = selectedActivity,
               let gameType = activity.gameType {
                NavigationStack {
                    gameView(for: gameType)
                }
            }
        }
        .fullScreenCover(isPresented: $showPuzzleScreen) {
            if let activity = selectedActivity,
               let puzzleType = activity.puzzleType {
                NavigationStack {
                    puzzleView(for: puzzleType)
                }
            }
        }
    }
    
    @ViewBuilder
    private func gameView(for gameType: ScheduledActivity.GameType) -> some View {
        switch gameType {
        case .memoryMatch:
            MemoryMatchGame(child: child, onComplete: { score in
                if let activity = selectedActivity {
                    markActivityCompleted(activity)
                }
                showGameScreen = false
            })
        case .colorMatch:
            ColorMatchGame(child: child, onComplete: { score in
                if let activity = selectedActivity {
                    markActivityCompleted(activity)
                }
                showGameScreen = false
            })
        case .shapeMatch:
            ShapeMatchingGame(child: child, onComplete: { score in
                if let activity = selectedActivity {
                    markActivityCompleted(activity)
                }
                showGameScreen = false
            })
        case .numberSequence:
            NumberSequenceGame(child: child, onComplete: { score in
                if let activity = selectedActivity {
                    markActivityCompleted(activity)
                }
                showGameScreen = false
            })
        case .mathQuiz:
            MathQuizGame(child: child, onComplete: { score in
                if let activity = selectedActivity {
                    markActivityCompleted(activity)
                }
                showGameScreen = false
            })
        case .emojiMatch:
            EmojiMatchGame(child: child, onComplete: { score in
                if let activity = selectedActivity {
                    markActivityCompleted(activity)
                }
                showGameScreen = false
            })
        }
    }
    
    @ViewBuilder
    private func puzzleView(for puzzleType: ScheduledActivity.PuzzleType) -> some View {
        // Create a temporary puzzle with the scheduled difficulty
        let tempPuzzle = LocalPuzzle(
            id: UUID().uuidString,
            childId: child.id,
            title: "Scheduled Puzzle",
            type: .pattern,
            difficulty: puzzleType == .easy ? .easy : .medium,
            gridSize: puzzleType == .easy ? 3 : 4,
            pieces: [],
            hint: "Complete the puzzle!",
            solution: "",
            puzzleImage: .lion,
            customImagePath: nil,
            isCompleted: false,
            attempts: 0,
            timeSpent: 0,
            score: 0,
            createdAt: Date(),
            completedAt: nil
        )
        
        ImagePuzzlePlayScreen(puzzle: tempPuzzle, child: child) {
            if let activity = selectedActivity {
                markActivityCompleted(activity)
            }
            showPuzzleScreen = false
        }
    }
    
    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: "scheduled_activities_\(child.id)"),
           let activities = try? JSONDecoder().decode([ScheduledActivity].self, from: data) {
            scheduledActivities = activities.sorted { activity1, activity2 in
                // Sort by availability first, then by time
                if activity1.isAvailable != activity2.isAvailable {
                    return activity1.isAvailable
                }
                return activity1.scheduledTime < activity2.scheduledTime
            }
        }
    }
    
    private func startActivity(_ activity: ScheduledActivity) {
        selectedActivity = activity
        
        switch activity.activityType {
        case .quiz:
            if activity.quizData != nil {
                showQuizTaking = true
            }
        case .game:
            // Launch the specific game
            showGameScreen = true
        case .puzzle:
            // Launch the specific puzzle
            showPuzzleScreen = true
        }
    }
    
    private func markActivityCompleted(_ activity: ScheduledActivity) {
        if let index = scheduledActivities.firstIndex(where: { $0.id == activity.id }) {
            scheduledActivities[index].isCompleted = true
            saveActivities()
        }
    }
    
    private func saveActivities() {
        if let data = try? JSONEncoder().encode(scheduledActivities) {
            UserDefaults.standard.set(data, forKey: "scheduled_activities_\(child.id)")
        }
    }
}

// MARK: - Child Activity Card
struct ChildActivityCard: View {
    let activity: ScheduledActivity
    let isAvailable: Bool
    let onTap: (() -> Void)?
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Button(action: {
            if isAvailable {
                onTap?()
            }
        }) {
            HStack(spacing: 16) {
                // Activity Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(activity.activityType.color.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: activity.activityType.icon)
                        .font(.system(size: 32))
                        .foregroundColor(activity.activityType.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(activity.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(activity.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    // Status or time remaining
                    if isAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Tap to start!")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.green)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(timeRemainingText)
                                .font(.caption.bold())
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Play button or lock icon
                if isAvailable {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(isAvailable ? 0.3 : 0.15),
                        Color.white.opacity(isAvailable ? 0.2 : 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isAvailable ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isAvailable)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var timeRemainingText: String {
        let remaining = activity.timeRemaining
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours >= 24 {
            let days = hours / 24
            return "in \(days) day\(days > 1 ? "s" : "")"
        } else if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "Very soon!"
        }
    }
}

// MARK: - Child Completed Activity Card
struct ChildCompletedActivityCard: View {
    let activity: ScheduledActivity
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(activity.activityType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("✅")
                    .font(.title3)
                Text("Done")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ChildScheduledActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
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
                ChildScheduledActivitiesView(
                    child: Child(
                        name: "Emma",
                        age: 8,
                        level: "3",
                        avatarEmoji: "avatar_1",
                        Score: 100,
                        quizzes: [],
                        connectionToken: "test"
                    ),
                    onQuizCompleted: {}
                )
                .padding(.horizontal, 20)
            }
        }
    }
}
