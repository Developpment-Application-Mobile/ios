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
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📅 Activity Scheduler")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Schedule activities for \(child.name)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Child Info Card
                HStack(spacing: 16) {
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Age \(child.age) • Level \(child.level)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(scheduledActivities.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Scheduled")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(activity.activityType.color.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: activity.activityType.icon)
                        .font(.title2)
                        .foregroundColor(activity.activityType.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.title)
                        .font(.headline)
                        .foregroundColor(Color(hex: "272052"))
                        .lineLimit(1)
                    
                    Text(activity.description)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "272052").opacity(0.7))
                        .lineLimit(1)
                    
                    // Status
                    if activity.isAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Available Now")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(timeRemainingText)
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .padding(10)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            
            // Scheduled Time
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scheduled Time")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "272052").opacity(0.6))
                    
                    Text(formattedDate(activity.scheduledTime))
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "272052"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "272052").opacity(0.6))
                    
                    Text(formattedDuration(activity.duration))
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "272052"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.95))
        .cornerRadius(20)
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
            return "\(hours)h \(remainingMinutes)m"
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
    @State private var title = ""
    @State private var description = ""
    @State private var selectedHours = 0
    @State private var selectedMinutes = 30
    @State private var duration: TimeInterval = 900 // 15 minutes default
    
    // Quiz-specific states
    @State private var showQuizSelection = false
    @State private var selectedQuiz: AIQuizResponse?
    @State private var availableQuizzes: [AIQuizResponse] = []
    @State private var isLoadingQuizzes = false
    
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
                                        Text(quiz.meaningfulTitle)
                                            .foregroundColor(Color(hex: "272052"))
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
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter activity title", text: $title)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .foregroundColor(Color(hex: "272052"))
                    }
                    .padding(.horizontal, 20)
                    
                    // Description Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter activity description", text: $description)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .foregroundColor(Color(hex: "272052"))
                    }
                    .padding(.horizontal, 20)
                    
                    // Time Delay Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available After")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            VStack {
                                Picker("Hours", selection: $selectedHours) {
                                    ForEach(0..<25) { hour in
                                        Text("\(hour)h").tag(hour)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .clipped()
                            }
                            
                            VStack {
                                Picker("Minutes", selection: $selectedMinutes) {
                                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                                        Text("\(minute)m").tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .clipped()
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
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
                    .disabled(title.isEmpty || (activityType == .quiz && selectedQuiz == nil))
                    .opacity(title.isEmpty || (activityType == .quiz && selectedQuiz == nil) ? 0.5 : 1.0)
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
                    if let quiz = selectedQuiz {
                        title = quiz.meaningfulTitle
                        description = "\(quiz.subject.capitalized) - \(quiz.difficulty.capitalized)"
                    }
                }
            )
        }
    }
    
    private func createActivity() {
        let scheduledTime = Date().addingTimeInterval(TimeInterval(selectedHours * 3600 + selectedMinutes * 60))
        
        let activity = ScheduledActivity(
            id: UUID().uuidString,
            childId: child.id,
            activityType: activityType,
            title: title,
            description: description,
            scheduledTime: scheduledTime,
            duration: duration,
            isCompleted: false,
            quizData: selectedQuiz
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
                    quizzes = fetchedQuizzes.filter { $0.answered == 0 }
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

