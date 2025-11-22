//
//  ChildDashboardScreen.swift - COMPLETE with ALL Components
//  EduKid
//

import SwiftUI

// MARK: - Game Type Enum (Must be at top level)
enum SimpleGameType: String, Identifiable {
    case memory = "Memory Match"
    case color = "Color Match"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .memory: return "brain.head.profile"
        case .color: return "paintpalette.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .memory: return .purple
        case .color: return .orange
        }
    }
}

// MARK: - Main Child Dashboard Screen
struct ChildDashboardScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @State private var quizzes: [AIQuizResponse] = []
    @State private var puzzles: [PuzzleResponse] = []
    @State private var isLoading = false
    @State private var selectedMainTab = 0
    @State private var selectedQuizTab = 0
    @State private var selectedGame: SimpleGameType?
    
    var pendingQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered == 0 }
    }
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered > 0 }
    }
    
    var pendingPuzzles: [PuzzleResponse] {
        puzzles.filter { !$0.isCompleted }
    }
    
    var completedPuzzles: [PuzzleResponse] {
        puzzles.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
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
                    VStack(spacing: 24) {
                        Spacer().frame(height: 40)
                        
                        ChildInfoCard(child: child)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 0) {
                            MainTabButton(title: "📝 Quizzes", isSelected: selectedMainTab == 0) {
                                selectedMainTab = 0
                            }
                            MainTabButton(title: "🧩 Puzzles", isSelected: selectedMainTab == 1) {
                                selectedMainTab = 1
                            }
                            MainTabButton(title: "🎮 Games", isSelected: selectedMainTab == 2) {
                                selectedMainTab = 2
                            }
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        if selectedMainTab == 0 {
                            QuizContent(
                                selectedTab: selectedQuizTab,
                                pendingQuizzes: pendingQuizzes,
                                completedQuizzes: completedQuizzes,
                                child: child,
                                onQuizCompleted: { Task { await loadData() } }
                            )
                            .padding(.horizontal, 20)
                        } else if selectedMainTab == 1 {
                            ChildPuzzleContent(
                                pendingPuzzles: pendingPuzzles,
                                completedPuzzles: completedPuzzles,
                                child: child,
                                onPuzzleCompleted: { Task { await loadData() } }
                            )
                            .padding(.horizontal, 20)
                        } else {
                            SimpleGamesContentView(child: child, selectedGame: $selectedGame)
                                .padding(.horizontal, 20)
                        }
                        
                        Button(action: { authVM.signOutChild() }) {
                            HStack {
                                Image(systemName: "arrow.uturn.left.circle.fill")
                                Text("Logout")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 40)
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task { await loadData() }
            }
            .refreshable {
                await loadData()
            }
            .fullScreenCover(item: $selectedGame) { game in
                switch game {
                case .memory:
                    MemoryMatchGame(child: child) { score in
                        selectedGame = nil
                    }
                case .color:
                    ColorMatchGame(child: child) { score in
                        selectedGame = nil
                    }
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        do {
            guard let parentId = AuthService.shared.getParentId() else { return }
            
            async let quizzesTask = AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
            async let puzzlesTask = PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
            
            let (fetchedQuizzes, fetchedPuzzles) = try await (quizzesTask, puzzlesTask)
            
            await MainActor.run {
                quizzes = fetchedQuizzes.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                puzzles = fetchedPuzzles.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("Error loading data: \(error)")
            }
        }
    }
}

// MARK: - Child Info Card
struct ChildInfoCard: View {
    let child: Child
    
    var body: some View {
        VStack(spacing: 16) {
            Image(child.avatarEmoji)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color.white.opacity(0.3))
                .clipShape(Circle())
                .shadow(radius: 8)
            
            Text(child.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                StatBadge(icon: "star.fill", label: "Points", value: "\(child.Score)", color: .yellow)
                StatBadge(icon: "chart.bar.fill", label: "Level", value: child.level, color: .green)
                StatBadge(icon: "calendar", label: "Age", value: "\(child.age)", color: .blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Quiz Content
struct QuizContent: View {
    let selectedTab: Int
    let pendingQuizzes: [AIQuizResponse]
    let completedQuizzes: [AIQuizResponse]
    let child: Child
    let onQuizCompleted: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Sub-tabs for pending/completed
            HStack(spacing: 0) {
                Button(action: {}) {
                    Text("Pending (\(pendingQuizzes.count))")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            // Quiz List
            if pendingQuizzes.isEmpty {
                EmptyStateView(icon: "checkmark.seal.fill", title: "All caught up!", message: "No pending quizzes. Great job!")
            } else {
                ForEach(pendingQuizzes) { quiz in
                    NavigationLink(destination:
                        QuizTakingScreen(quiz: quiz, child: child, onQuizCompleted: onQuizCompleted)
                    ) {
                        AIQuizCardForChild(quiz: quiz)
                    }
                }
            }
        }
    }
}

// MARK: - AI Quiz Card for Child
struct AIQuizCardForChild: View {
    let quiz: AIQuizResponse
    
    var subjectIcon: String {
        switch quiz.subject.lowercased() {
        case "math": return "function"
        case "science": return "flask.fill"
        case "english": return "book.fill"
        case "history": return "clock.fill"
        case "geography": return "globe"
        default: return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch quiz.subject.lowercased() {
        case "math": return .blue
        case "science": return .green
        case "english": return .purple
        case "history": return .orange
        case "geography": return .cyan
        default: return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(iconColor.opacity(0.3)).frame(width: 70, height: 70)
                Image(systemName: subjectIcon).font(.system(size: 28)).foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(quiz.topic.capitalized).font(.title3.bold()).foregroundColor(.white)
                Text(quiz.subject.capitalized).font(.subheadline).foregroundColor(.white.opacity(0.8))
                HStack(spacing: 12) {
                    Label("\(quiz.questions.count) questions", systemImage: "questionmark.circle.fill")
                    Label(quiz.difficulty.capitalized, systemImage: "star")
                }
                .font(.caption).foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .background(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(20)
    }
}

// MARK: - Child Puzzle Content (Uses Local Puzzles)
struct ChildPuzzleContent: View {
    let pendingPuzzles: [PuzzleResponse]
    let completedPuzzles: [PuzzleResponse]
    let child: Child
    let onPuzzleCompleted: () -> Void
    
    @State private var selectedPuzzle: PuzzleResponse?
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var selectedLocalPuzzle: LocalPuzzle?
    @State private var showGenerateOptions = false
    
    var pendingLocalPuzzles: [LocalPuzzle] {
        localPuzzles.filter { !$0.isCompleted }
    }
    
    var completedLocalPuzzles: [LocalPuzzle] {
        localPuzzles.filter { $0.isCompleted }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Generate Your Own Button
            Button(action: { showGenerateOptions = true }) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                    Text("Create Your Own Puzzle")
                        .font(.headline)
                }
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(16)
            }
            
            // Local Puzzles
            if !pendingLocalPuzzles.isEmpty {
                SectionHeader(title: "Your Puzzles", icon: "play.circle.fill")
                ForEach(pendingLocalPuzzles) { puzzle in
                    LocalPuzzleCard(puzzle: puzzle) {
                        selectedLocalPuzzle = puzzle
                    }
                }
            }
            
            if !completedLocalPuzzles.isEmpty {
                SectionHeader(title: "Completed", icon: "checkmark.circle.fill")
                ForEach(completedLocalPuzzles) { puzzle in
                    LocalPuzzleCard(puzzle: puzzle, showScore: true) {
                        selectedLocalPuzzle = puzzle
                    }
                }
            }
            
            // Parent Puzzles (if any)
            if !pendingPuzzles.isEmpty {
                SectionHeader(title: "From Parents", icon: "gift.fill")
                ForEach(pendingPuzzles) { puzzle in
                    PuzzleCard(puzzle: puzzle) {
                        selectedPuzzle = puzzle
                    }
                }
            }
        }
        .onAppear {
            loadLocalPuzzles()
        }
        .sheet(isPresented: $showGenerateOptions) {
            QuickPuzzleGeneratorSheet(child: child) {
                loadLocalPuzzles()
            }
        }
        .fullScreenCover(item: $selectedLocalPuzzle) { puzzle in
            LocalPuzzlePlayScreen(
                puzzle: puzzle,
                child: child,
                onComplete: {
                    selectedLocalPuzzle = nil
                    loadLocalPuzzles()
                    onPuzzleCompleted()
                }
            )
        }
        .fullScreenCover(item: $selectedPuzzle) { puzzle in
            PuzzlePlayScreen(
                puzzle: puzzle,
                child: child,
                onComplete: {
                    selectedPuzzle = nil
                    onPuzzleCompleted()
                }
            )
        }
    }
    
    private func loadLocalPuzzles() {
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
    }
}

// MARK: - Local Puzzle Card
struct LocalPuzzleCard: View {
    let puzzle: LocalPuzzle
    var showScore: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(puzzle.type.color.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: puzzle.type.icon)
                        .font(.title2)
                        .foregroundColor(puzzle.type.color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(puzzle.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Label(puzzle.type.displayName, systemImage: puzzle.type.icon)
                        Label("\(puzzle.gridSize)x\(puzzle.gridSize)", systemImage: "square.grid.2x2")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                    Text(puzzle.difficulty.displayName)
                        .font(.caption.bold())
                        .foregroundColor(puzzle.difficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(puzzle.difficulty.color.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if showScore && puzzle.isCompleted {
                    VStack(spacing: 4) {
                        Text("⭐")
                            .font(.title2)
                        Text("\(puzzle.score)")
                            .font(.headline.bold())
                            .foregroundColor(.yellow)
                    }
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
        }
    }
}

// MARK: - Quick Puzzle Generator Sheet
struct QuickPuzzleGeneratorSheet: View {
    let child: Child
    let onGenerated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.153, green: 0.125, blue: 0.322)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Choose Puzzle Type")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    ForEach(PuzzleType.allCases, id: \.self) { type in
                        Button(action: {
                            generatePuzzle(type: type)
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .foregroundColor(type.color)
                                    .frame(width: 50, height: 50)
                                    .background(type.color.opacity(0.2))
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.displayName)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(getDescription(for: type))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Create Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func generatePuzzle(type: PuzzleType) {
        let _ = LocalPuzzleManager.shared.generateLocalPuzzle(for: child, type: type)
        onGenerated()
        dismiss()
    }
    
    private func getDescription(for type: PuzzleType) -> String {
        switch type {
        case .word: return "Unscramble letters to form words"
        case .number: return "Arrange numbers in order"
        case .sequence: return "Put items in correct order"
        case .pattern: return "Complete the pattern"
        case .image: return "Assemble the picture"
        }
    }
}

// Note: SectionHeader and PuzzleCard are defined in PuzzleViews.swift
// If they don't exist there, uncomment these:

/*
// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Puzzle Card
struct PuzzleCard: View {
    let puzzle: PuzzleResponse
    var showScore: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(puzzle.puzzleType.color.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: puzzle.puzzleType.icon)
                        .font(.title2)
                        .foregroundColor(puzzle.puzzleType.color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(puzzle.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(puzzle.puzzleType.displayName, systemImage: puzzle.puzzleType.icon)
                        Label("\(puzzle.gridSize)x\(puzzle.gridSize)", systemImage: "square.grid.2x2")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                    Text(puzzle.puzzleDifficulty.displayName)
                        .font(.caption.bold())
                        .foregroundColor(puzzle.puzzleDifficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(puzzle.puzzleDifficulty.color.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if showScore && puzzle.isCompleted {
                    VStack(spacing: 4) {
                        Text("⭐")
                            .font(.title2)
                        Text("\(puzzle.score)")
                            .font(.headline.bold())
                            .foregroundColor(.yellow)
                    }
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
        }
    }
}
*/

// MARK: - Simple Games Content View
struct SimpleGamesContentView: View {
    let child: Child
    @Binding var selectedGame: SimpleGameType?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎮 Fun Games")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GameCard(
                title: "Memory Match",
                description: "Find matching pairs and train your memory!",
                icon: "brain.head.profile",
                color: .purple,
                difficulty: "Easy"
            ) {
                selectedGame = .memory
            }
            
            GameCard(
                title: "Color Match",
                description: "Match colors with their names!",
                icon: "paintpalette.fill",
                color: .orange,
                difficulty: "Easy"
            ) {
                selectedGame = .color
            }
            
            GameHistoryView(child: child)
        }
    }
}

// MARK: - Game Card
struct GameCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let difficulty: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    Text(difficulty)
                        .font(.caption.bold())
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(Color.white.opacity(0.15))
            .cornerRadius(20)
        }
    }
}

// MARK: - Game History View
struct GameHistoryView: View {
    let child: Child
    @State private var games: [[String: Any]] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Recent Games")
                .font(.headline)
                .foregroundColor(.white)
            
            if games.isEmpty {
                Text("No games played yet. Start playing to see your history!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            } else {
                ForEach(games.indices, id: \.self) { index in
                    if let game = games[index] as? [String: Any] {
                        GameHistoryCard(game: game)
                    }
                }
            }
        }
        .onAppear {
            loadGameHistory()
        }
    }
    
    private func loadGameHistory() {
        games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games = Array(games.reversed().prefix(5))
    }
}

// MARK: - Game History Card
struct GameHistoryCard: View {
    let game: [String: Any]
    
    var gameTitle: String {
        if let type = game["type"] as? String {
            return type == "memory" ? "Memory Match" : "Color Match"
        }
        return "Game"
    }
    
    var gameIcon: String {
        if let type = game["type"] as? String {
            return type == "memory" ? "brain.head.profile" : "paintpalette.fill"
        }
        return "gamecontroller.fill"
    }
    
    var gameColor: Color {
        if let type = game["type"] as? String {
            return type == "memory" ? .purple : .orange
        }
        return .blue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: gameIcon)
                .font(.title3)
                .foregroundColor(gameColor)
                .frame(width: 40, height: 40)
                .background(gameColor.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gameTitle)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    if let score = game["score"] as? Int {
                        Label("\(score) pts", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    if let time = game["time"] as? Int {
                        Label(formatTime(time), systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Main Tab Button
struct MainTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? Color.white.opacity(0.25) : Color.clear)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
            Text(title)
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}
