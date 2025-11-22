//
//  EnhancedChildDetailScreen.swift
//  EduKid
//
//  Fixed: All compilation errors resolved
//

import SwiftUI

struct EnhancedChildDetailScreen: View {
    let child: Child
    
    @State private var selectedTab = 0
    @State private var quizzes: [AIQuizResponse] = []
    @State private var puzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var isLoading = false
    @State private var selectedQuiz: AIQuizResponse?
    @State private var showQuizDetail = false
    @EnvironmentObject var authVM: AuthViewModel
    
    let tabs = ["Overview", "Quizzes", "Puzzles", "Games"]
    
    var onBackClick: () -> Void = {}
    var onAssignQuizClick: () -> Void = {}
    var onGenerateQRClick: () -> Void = {}
    var onEditClick: () -> Void = {}
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered > 0 }
    }
    
    var completedPuzzles: [PuzzleResponse] {
        puzzles.filter { $0.isCompleted }
    }
    
    var averageQuizScore: Int {
        guard !completedQuizzes.isEmpty else { return 0 }
        return completedQuizzes.reduce(0) { $0 + $1.score } / completedQuizzes.count
    }
    
    var averagePuzzleScore: Int {
        guard !completedPuzzles.isEmpty else { return 0 }
        return completedPuzzles.reduce(0) { $0 + $1.score } / completedPuzzles.count
    }
    
    var averageGameScore: Int {
        guard !games.isEmpty else { return 0 }
        let total = games.compactMap { $0["score"] as? Int }.reduce(0, +)
        return total / games.count
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
                            Label("\(child.Score) pts", systemImage: "star.fill")
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
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onAssignQuizClick) {
                        Label("Assign Quiz", systemImage: "doc.badge.plus")
                            .font(.subheadline.bold())
                            .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onGenerateQRClick) {
                        Label("Show QR", systemImage: "qrcode")
                            .font(.subheadline.bold())
                            .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(12)
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
                    Group {
                        switch selectedTab {
                        case 0:
                            OverviewTabContent(
                                child: child,
                                quizzesCompleted: completedQuizzes.count,
                                puzzlesCompleted: completedPuzzles.count,
                                gamesPlayed: games.count,
                                averageQuizScore: averageQuizScore,
                                averagePuzzleScore: averagePuzzleScore,
                                averageGameScore: averageGameScore
                            )
                        case 1:
                            QuizResultsTabContent(quizzes: completedQuizzes) { quiz in
                                selectedQuiz = quiz
                                showQuizDetail = true
                            }
                        case 2:
                            PuzzleResultsTabContent(puzzles: completedPuzzles)
                        case 3:
                            GameResultsTabContent(games: games)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showQuizDetail) {
            if let quiz = selectedQuiz {
                ParentQuizDetailView(quiz: quiz, child: child)
            }
        }
        .onAppear {
            loadAllData()
        }
    }
    
    private func loadAllData() {
        isLoading = true
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                
                async let quizzesTask = AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
                async let puzzlesTask = PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
                
                let (fetchedQuizzes, fetchedPuzzles) = try await (quizzesTask, puzzlesTask)
                
                await MainActor.run {
                    quizzes = fetchedQuizzes
                    puzzles = fetchedPuzzles
                    games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Failed to load data: \(error)")
                }
            }
        }
    }
}

// MARK: - Overview Tab Content
struct OverviewTabContent: View {
    let child: Child
    let quizzesCompleted: Int
    let puzzlesCompleted: Int
    let gamesPlayed: Int
    let averageQuizScore: Int
    let averagePuzzleScore: Int
    let averageGameScore: Int
    
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
                        ParentStatCard(title: "Total Score", value: "\(child.Score)", icon: "star.fill", color: .yellow)
                        ParentStatCard(title: "Activities", value: "\(quizzesCompleted + puzzlesCompleted + gamesPlayed)", icon: "checkmark.circle.fill", color: .green)
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
                    
                    ActivityBreakdownRow(
                        icon: "doc.text.fill",
                        title: "Quizzes",
                        completed: quizzesCompleted,
                        avgScore: averageQuizScore,
                        color: .blue
                    )
                    
                    ActivityBreakdownRow(
                        icon: "puzzlepiece.fill",
                        title: "Puzzles",
                        completed: puzzlesCompleted,
                        avgScore: averagePuzzleScore,
                        color: .purple
                    )
                    
                    ActivityBreakdownRow(
                        icon: "gamecontroller.fill",
                        title: "Games",
                        completed: gamesPlayed,
                        avgScore: averageGameScore,
                        color: .orange
                    )
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

// MARK: - Activity Breakdown Row
struct ActivityBreakdownRow: View {
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
                Text("\(avgScore)%")
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

// MARK: - Parent Stat Card (renamed to avoid conflict)
struct ParentStatCard: View {
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

// MARK: - Quiz Results Tab Content
struct QuizResultsTabContent: View {
    let quizzes: [AIQuizResponse]
    let onQuizTap: (AIQuizResponse) -> Void
    
    var body: some View {
        if quizzes.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Text("📝")
                    .font(.system(size: 60))
                Text("No quizzes completed yet")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(quizzes) { quiz in
                        Button(action: { onQuizTap(quiz) }) {
                            AIQuizResultCard(quiz: quiz)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Puzzle Results Tab Content
struct PuzzleResultsTabContent: View {
    let puzzles: [PuzzleResponse]
    
    var body: some View {
        if puzzles.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Text("🧩")
                    .font(.system(size: 60))
                Text("No puzzles completed yet")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(puzzles) { puzzle in
                        ParentPuzzleResultCard(puzzle: puzzle)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Parent Puzzle Result Card
struct ParentPuzzleResultCard: View {
    let puzzle: PuzzleResponse
    
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
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Game Results Tab Content
struct GameResultsTabContent: View {
    let games: [[String: Any]]
    
    var body: some View {
        if games.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Text("🎮")
                    .font(.system(size: 60))
                Text("No games played yet")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(games.indices, id: \.self) { index in
                        if let game = games[index] as? [String: Any] {
                            ParentGameResultCard(game: game)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Parent Game Result Card
struct ParentGameResultCard: View {
    let game: [String: Any]
    
    var gameType: String {
        (game["type"] as? String) ?? "game"
    }
    
    var gameTitle: String {
        gameType == "memory" ? "Memory Match" : "Color Match"
    }
    
    var gameIcon: String {
        gameType == "memory" ? "brain.head.profile" : "paintpalette.fill"
    }
    
    var gameColor: Color {
        gameType == "memory" ? .purple : .orange
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
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    if let time = game["time"] as? Int {
                        Label(formatTime(time), systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let moves = game["moves"] as? Int {
                        Label("\(moves) moves", systemImage: "hand.tap.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            if let score = game["score"] as? Int {
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.title3)
                    Text("\(score)")
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
