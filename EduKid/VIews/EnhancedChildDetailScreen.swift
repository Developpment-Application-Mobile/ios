//
//  EnhancedChildDetailScreen.swift
//  EduKid
//
//  COMPLETE: Shows ALL results - Quizzes, Puzzles, and Games
//

import SwiftUI

struct EnhancedChildDetailScreen: View {
    let child: Child
    
    @State private var selectedTab = 0
    @State private var quizzes: [AIQuizResponse] = []
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var isLoading = false
    @State private var selectedQuiz: AIQuizResponse?
    @State private var showQuizDetail = false
    @State private var showActivityScheduler = false
    @State private var showGiftManagement = false
    @EnvironmentObject var authVM: AuthViewModel
    
    let tabs = ["Overview", "Quiz Results", "Puzzle Results", "Game Results"]
    
    var onBackClick: () -> Void = {}
    var onAssignQuizClick: () -> Void = {}
    var onGenerateQRClick: () -> Void = {}
    var onEditClick: () -> Void = {}
    var onCreatePuzzleClick: () -> Void = {}
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered > 0 }
    }
    
    var allPuzzles: [LocalPuzzle] {
        localPuzzles
    }
    
    var completedPuzzles: [LocalPuzzle] {
        localPuzzles.filter { $0.isCompleted }
    }
    
    var completedServerPuzzles: [PuzzleResponse] {
        serverPuzzles.filter { $0.isCompleted }
    }
    
    var totalCompleted: Int {
        completedQuizzes.count + completedPuzzles.count + completedServerPuzzles.count + games.count
    }
    
    var averageQuizScore: Int {
        guard !completedQuizzes.isEmpty else { return 0 }
        return completedQuizzes.reduce(0) { $0 + $1.score } / completedQuizzes.count
    }
    
    var averagePuzzleScore: Int {
        let localScores = completedPuzzles.map { $0.score }
        let serverScores = completedServerPuzzles.map { $0.score }
        
        let allScores = localScores + serverScores
        guard !allScores.isEmpty else { return 0 }
        
        return allScores.reduce(0, +) / allScores.count
    }
    
    
    var averageGameScore: Int {
        let scores = games.compactMap { $0["score"] as? Int }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }
    
    var calculatedTotalScore: Int {
        let quizScore = completedQuizzes.reduce(0) { $0 + $1.score }
        let localPuzzleScore = completedPuzzles.reduce(0) { $0 + $1.score }
        let serverPuzzleScore = completedServerPuzzles.reduce(0) { $0 + $1.score }
        let gameScore = games.compactMap { $0["score"] as? Int }.reduce(0, +)
        
        return quizScore + localPuzzleScore + serverPuzzleScore + gameScore
    }
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button(action: onBackClick) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Text("\(child.name)'s Activity")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onEditClick) {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 20)
                
                // Child Info Card
                HStack(spacing: 16) {
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(child.name)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Text("Age \(child.age) • Level \(child.level)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 8) {
                            Label("\(calculatedTotalScore) pts", systemImage: "star.fill")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
                
                // Action Buttons Row 1
                HStack(spacing: 16) {
                    // Programme Enfant Button
                    Button(action: { showActivityScheduler = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                            }
                            
                            Text("Schedule")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    // QR Code Button
                    Button(action: { onGenerateQRClick() }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "qrcode")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Code\nQR")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
                
                // Gifts Button Row
                HStack(spacing: 16) {
                    Button(action: { showGiftManagement = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                            }
                            
                            Text("Shop")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
                
                // Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: { selectedTab = index }) {
                                Text(tabs[index])
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedTab == index ? Color.white.opacity(0.25) : Color.clear)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .background(Color.white.opacity(0.1))
                
                Spacer().frame(height: 16)
                
                // Tab Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        Group {
                            switch selectedTab {
                            case 0:
                                OverviewTabView(
                                    child: child,
                                    quizzesCompleted: completedQuizzes.count,
                                    puzzlesCompleted: completedPuzzles.count + completedServerPuzzles.count,
                                    gamesPlayed: games.count,
                                    totalCompleted: totalCompleted,
                                    averageQuizScore: averageQuizScore,
                                    averagePuzzleScore: averagePuzzleScore,
                                    averageGameScore: averageGameScore,
                                    totalScore: calculatedTotalScore
                                )
                            case 1:
                                QuizResultsTabView(quizzes: completedQuizzes) { quiz in
                                    selectedQuiz = quiz
                                    showQuizDetail = true
                                }
                            case 2:
                                PuzzleResultsTabView(
                                    localPuzzles: completedPuzzles,
                                    serverPuzzles: completedServerPuzzles,
                                    childId: child.id,
                                    onDelete: { loadAllData() }
                                )
                            case 3:
                                GameResultsTabView(games: games)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .sheet(isPresented: $showQuizDetail) {
                if let quiz = selectedQuiz {
                    ParentQuizDetailView(quiz: quiz, child: child)
                }
            }
            .sheet(isPresented: $showActivityScheduler) {
                NavigationStack {
                    ParentActivitySchedulerScreen(child: child)
                }
            }
            .sheet(isPresented: $showGiftManagement) {
                if let parentId = AuthService.shared.getParentId() {
                    GiftManagementView(childId: child.id, parentId: parentId)
                }
            }
            .onAppear { loadAllData() }
        }
    }
    
    // MARK: - Helper Methods
    private func loadAllData() {
        isLoading = true
        
        // Load local puzzles
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        
        // Load games from UserDefaults
        games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                
                async let quizzesTask = AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
                async let puzzlesTask = PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
                
                let (fetchedQuizzes, fetchedPuzzles) = try await (quizzesTask, puzzlesTask)
                
                await MainActor.run {
                    quizzes = fetchedQuizzes
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

// MARK: - Action Button
struct ActionButton: View {
        let title: String
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title3)
                    Text(title)
                        .font(.caption.bold())
                }
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Overview Tab View
    struct OverviewTabView: View {
        let child: Child
        let quizzesCompleted: Int
        let puzzlesCompleted: Int
        let gamesPlayed: Int
        let totalCompleted: Int
        let averageQuizScore: Int
        let averagePuzzleScore: Int
        let averageGameScore: Int
        let totalScore: Int
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    // Overall Stats
                    VStack(spacing: 12) {
                        Text("📊 Overall Performance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            OverviewStatCard(title: "Total Score", value: "\(totalScore)", icon: "star.fill", color: .yellow)
                            OverviewStatCard(title: "Completed", value: "\(totalCompleted)", icon: "checkmark.circle.fill", color: .green)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    
                    // Activity Breakdown
                    VStack(spacing: 12) {
                        Text("🎯 By Activity Type")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ActivityRow(icon: "doc.text.fill", title: "Quizzes", completed: quizzesCompleted, avgScore: averageQuizScore, color: .blue)
                        ActivityRow(icon: "puzzlepiece.fill", title: "Puzzles", completed: puzzlesCompleted, avgScore: averagePuzzleScore, color: .purple)
                        ActivityRow(icon: "gamecontroller.fill", title: "Games", completed: gamesPlayed, avgScore: averageGameScore, color: .orange)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    
    // MARK: - Overview Stat Card
    struct OverviewStatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(value)
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Activity Row
    struct ActivityRow: View {
        let icon: String
        let title: String
        let completed: Int
        let avgScore: Int
        let color: Color
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("\(completed) completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(avgScore > 0 ? "\(avgScore)%" : "N/A")
                        .font(.title3.bold())
                        .foregroundColor(color)
                    Text("avg score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Quiz Results Tab View
    struct QuizResultsTabView: View {
        let quizzes: [AIQuizResponse]
        let onQuizTap: (AIQuizResponse) -> Void
        
        var body: some View {
            if quizzes.isEmpty {
                EmptyResultsView(emoji: "📝", message: "No quizzes completed yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(quizzes) { quiz in
                            Button(action: { onQuizTap(quiz) }) {
                                EnhancedAIQuizResultCardForParent(quiz: quiz)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Enhanced AI Quiz Result Card For Parent (avec titre significatif)
    struct EnhancedAIQuizResultCardForParent: View {
        let quiz: AIQuizResponse
        
        var scoreColor: Color {
            if quiz.score >= 80 { return Color(red: 0.298, green: 0.686, blue: 0.314) }
            else if quiz.score >= 60 { return Color(red: 1.0, green: 0.655, blue: 0.149) }
            else { return Color(red: 0.937, green: 0.325, blue: 0.314) }
        }
        
        var scoreIcon: String {
            if quiz.score >= 80 { return "🎉" }
            else if quiz.score >= 60 { return "👍" }
            else { return "💪" }
        }
        
        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        // CHANGÉ: Utiliser meaningfulTitle
                        Text(quiz.meaningfulTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        
                        Text(quiz.subject.capitalized)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        
                        HStack(spacing: 8) {
                            Text(quiz.difficulty.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(scoreIcon)
                            .font(.system(size: 24))
                        
                        Text("\(quiz.score)%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(scoreColor)
                    }
                    .frame(width: 70, height: 70)
                    .background(scoreColor.opacity(0.15))
                    .clipShape(Circle())
                }
                
                Divider()
                    .background(Color(red: 0.88, green: 0.88, blue: 0.88))
                
                HStack {
                    HStack(spacing: 4) {
                        Text("❓")
                            .font(.system(size: 14))
                        Text("\(quiz.questions.count) questions")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("✅")
                            .font(.system(size: 14))
                        Text("\(quiz.answered) answered")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    
                    Spacer()
                    
                    if let date = quiz.createdAt {
                        HStack(spacing: 4) {
                            Text("📅")
                                .font(.system(size: 14))
                            Text(formatDate(date))
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        }
                    }
                }
                
                // "View Details" indicator
                HStack {
                    Spacer()
                    Text("Tap to view details")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.95))
            .cornerRadius(16)
        }
        
        private func formatDate(_ dateString: String) -> String {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMM d"
                return displayFormatter.string(from: date)
            }
            return "Recent"
        }
    }
    
    
    
    // MARK: - Puzzle Results Tab View
    struct PuzzleResultsTabView: View {
        let localPuzzles: [LocalPuzzle]
        let serverPuzzles: [PuzzleResponse]
        let childId: String
        let onDelete: () -> Void
        
        @State private var puzzleToDelete: String?
        @State private var showDeleteAlert = false
        @State private var isLocalPuzzle = false
        
        var body: some View {
            if localPuzzles.isEmpty && serverPuzzles.isEmpty {
                EmptyResultsView(emoji: "🧩", message: "No puzzles completed yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(localPuzzles) { puzzle in
                            LocalPuzzleResultCardWithDelete(puzzle: puzzle) {
                                puzzleToDelete = puzzle.id
                                isLocalPuzzle = true
                                showDeleteAlert = true
                            }
                        }
                        ForEach(serverPuzzles) { puzzle in
                            ServerPuzzleResultCardWithDelete(puzzle: puzzle) {
                                puzzleToDelete = puzzle.id
                                isLocalPuzzle = false
                                showDeleteAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .alert("Delete Puzzle", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {
                        puzzleToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let id = puzzleToDelete {
                            deletePuzzle(id: id, isLocal: isLocalPuzzle)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this puzzle?")
                }
            }
        }
        
        private func deletePuzzle(id: String, isLocal: Bool) {
            if isLocal {
                LocalPuzzleManager.shared.deletePuzzle(id: id, childId: childId)
                onDelete()
            } else {
                Task {
                    do {
                        guard let parentId = AuthService.shared.getParentId() else { return }
                        try await PuzzleService.shared.deletePuzzle(
                            parentId: parentId,
                            kidId: childId,
                            puzzleId: id
                        )
                        await MainActor.run {
                            onDelete()
                        }
                    } catch {
                        print("❌ Failed to delete server puzzle: \(error)")
                    }
                }
            }
            puzzleToDelete = nil
        }
    }
    
    // MARK: - Local Puzzle Result Card With Delete
    struct LocalPuzzleResultCardWithDelete: View {
        let puzzle: LocalPuzzle
        let onDelete: () -> Void
        
        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(puzzle.puzzleImage.backgroundColor.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Text(puzzle.puzzleImage.emoji)
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(puzzle.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Label(puzzle.difficulty.displayName, systemImage: "star.fill")
                        Label("\(puzzle.attempts) tries", systemImage: "arrow.counterclockwise")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.title3)
                    Text("\(puzzle.score)")
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Server Puzzle Result Card With Delete
    struct ServerPuzzleResultCardWithDelete: View {
        let puzzle: PuzzleResponse
        let onDelete: () -> Void
        
        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(puzzle.puzzleType.color.opacity(0.3))
                        .frame(width: 60, height: 60)
                    Image(systemName: puzzle.puzzleType.icon)
                        .font(.title3)
                        .foregroundColor(puzzle.puzzleType.color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(puzzle.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Label(puzzle.puzzleDifficulty.displayName, systemImage: "star.fill")
                        Label("\(puzzle.attempts) tries", systemImage: "arrow.counterclockwise")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.title3)
                    Text("\(puzzle.score)")
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Game Results Tab View
    struct GameResultsTabView: View {
        let games: [[String: Any]]
        
        var body: some View {
            if games.isEmpty {
                EmptyResultsView(emoji: "🎮", message: "No games played yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(games.indices, id: \.self) { index in
                            GameResultCard(game: games[index])
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Game Result Card
    struct GameResultCard: View {
        let game: [String: Any]
        
        var gameType: String { (game["type"] as? String) ?? "game" }
        var gameTitle: String {
            switch gameType {
            case "memory": return "Memory Match"
            case "color": return "Color Match"
            case "shape": return "Shape Match"
            case "sequence": return "Number Sequence"
            case "puzzle": return "Puzzle"
            default: return "Game"
            }
        }
        var gameIcon: String {
            switch gameType {
            case "memory": return "brain.head.profile"
            case "color": return "paintpalette.fill"
            case "shape": return "square.on.circle"
            case "sequence": return "number.circle"
            case "puzzle": return "puzzlepiece.fill"
            default: return "gamecontroller.fill"
            }
        }
        var gameColor: Color {
            switch gameType {
            case "memory": return .purple
            case "color": return .orange
            case "shape": return .green
            case "sequence": return .blue
            case "puzzle": return Color(red: 0.686, green: 0.494, blue: 0.906)
            default: return .gray
            }
        }
        
        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gameColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                    Image(systemName: gameIcon)
                        .font(.title3)
                        .foregroundColor(gameColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(gameTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                    
                    if let dateString = game["date"] as? String {
                        Text(formatDate(dateString))
                            .font(.caption)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    
                    HStack(spacing: 8) {
                        if let time = game["time"] as? Int {
                            Label(formatTime(time), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        }
                        
                        if let moves = game["moves"] as? Int {
                            Label("\(moves)", systemImage: "hand.tap")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        } else if let rounds = game["rounds"] as? Int {
                            Label("\(rounds) rounds", systemImage: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        } else if let level = game["level"] as? Int {
                            Label("Level \(level)", systemImage: "chart.bar")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        } else if let attempts = game["attempts"] as? Int {
                            Label("\(attempts) tries", systemImage: "arrow.counterclockwise")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.title3)
                    if let score = game["score"] as? Int {
                        Text("\(score)")
                            .font(.headline.bold())
                            .foregroundColor(gameColor)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.95))
            .cornerRadius(16)
        }
        
        private func formatDate(_ dateString: String) -> String {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMM d, HH:mm"
                return displayFormatter.string(from: date)
            }
            return "Recent"
        }
        
        private func formatTime(_ seconds: Int) -> String {
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", mins, secs)
        }
    }
    
    
    // MARK: - Empty Results View
    struct EmptyResultsView: View {
        let emoji: String
        let message: String
        
        var body: some View {
            VStack(spacing: 16) {
                Spacer()
                Text(emoji)
                    .font(.system(size: 60))
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
        }
    }

