//
//  ChildDashboardScreen.swift
//  EduKid
//
//  FIXED: All 4 games now working - NO placeholders
//

import SwiftUI

// MARK: - Game Type Enum
enum SimpleGameType: String, Identifiable, CaseIterable {
    case memory = "Memory Match"
    case color = "Color Match"
    case shape = "Shape Match"
    case sequence = "Number Sequence"
    case math = "Math Quiz"
    case emoji = "Emoji Match"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .memory: return "brain.head.profile"
        case .color: return "paintpalette.fill"
        case .shape: return "square.on.circle"
        case .sequence: return "number.circle"
        case .math: return "function"
        case .emoji: return "face.smiling.fill"
        }
    }
    var color: Color {
        switch self {
        case .memory: return .purple
        case .color: return .orange
        case .shape: return .green
        case .sequence: return .blue
        case .math: return .cyan
        case .emoji: return .pink
        }
    }
    var description: String {
        switch self {
        case .memory: return "Match pairs of cards"
        case .color: return "Match colors and patterns"
        case .shape: return "Identify matching shapes"
        case .sequence: return "Complete number patterns"
        case .math: return "Solve math problems"
        case .emoji: return "Match emoji to name"
        }
    }
}

// MARK: - Main Child Dashboard Screen
struct ChildDashboardScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var selectedMainTab = 0
    @State private var selectedGame: SimpleGameType?
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    
    var calculatedTotalScore: Int {
        let quizScore = completedQuizzes.reduce(0) { $0 + $1.score }
        let localPuzzleScore = localPuzzles.filter { $0.isCompleted }.reduce(0) { $0 + $1.score }
        let serverPuzzleScore = serverPuzzles.filter { $0.isCompleted }.reduce(0) { $0 + $1.score }
        let gameScore = games.compactMap { $0["score"] as? Int }.reduce(0, +)
        
        return quizScore + localPuzzleScore + serverPuzzleScore + gameScore
    }
    
    var pendingQuizzes: [AIQuizResponse] {
        let pending = quizzes.filter { !$0.isAnswered }
        print("🔍 PENDING QUIZZES: \(pending.count) quizzes from total \(quizzes.count)")
        return pending
    }
    var completedQuizzes: [AIQuizResponse] {
        let completed = quizzes.filter { $0.isAnswered }
        print("🔍 COMPLETED QUIZZES: \(completed.count) quizzes")
        return completed
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
                        
                        ChildInfoCardView(child: child, totalScore: calculatedTotalScore)
                            .padding(.horizontal, 20)
                        
                        // Tab Selector
                        HStack(spacing: 0) {
                            TabButton(title: "📅 My Tasks", isSelected: selectedMainTab == 0) { selectedMainTab = 0 }
                            TabButton(title: "📝 Quizzes", isSelected: selectedMainTab == 1) { selectedMainTab = 1 }
                            TabButton(title: "🧩 Puzzles", isSelected: selectedMainTab == 2) { selectedMainTab = 2 }
                            TabButton(title: "🎮 Games", isSelected: selectedMainTab == 3) { selectedMainTab = 3 }
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Tab Content
                        Group {
                            switch selectedMainTab {
                            case 0:
                                ChildScheduledActivitiesView(
                                    child: child,
                                    onQuizCompleted: { Task { await loadData() } }
                                )
                            case 1:
                                ChildQuizContent(
                                    pendingQuizzes: pendingQuizzes,
                                    completedQuizzes: completedQuizzes,
                                    child: child,
                                    onQuizCompleted: { Task { await loadData() } }
                                )
                            case 2:
                                ChildPuzzleContentView(
                                    child: child,
                                    onPuzzleCompleted: { Task { await loadData() } }
                                )
                            case 3:
                                ChildGamesContent(child: child, selectedGame: $selectedGame)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout Button
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
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5)
                }
            }
            .navigationBarHidden(true)
            .onAppear { Task { await loadData() } }
            .refreshable { await loadData() }
            .fullScreenCover(item: $selectedGame) { game in
                switch game {
                case .memory:
                    MemoryMatchGame(child: child) { _ in selectedGame = nil }
                case .color:
                    ColorMatchGame(child: child) { _ in selectedGame = nil }
                case .shape:
                    ShapeMatchingGame(child: child) { _ in selectedGame = nil }
                case .sequence:
                    NumberSequenceGame(child: child) { _ in selectedGame = nil }
                case .math:
                    MathQuizGame(child: child) { _ in selectedGame = nil }
                case .emoji:
                    EmojiMatchGame(child: child) { _ in selectedGame = nil }
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // Load Games
        if let loadedGames = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] {
            games = loadedGames
        }
        
        // Load Local Puzzles
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        
        guard let parentId = AuthService.shared.getParentId() else {
            print("⚠️ No parentId found in AuthService - cannot load data")
            await MainActor.run { isLoading = false }
            return
        }
        
        print("📚 Loading data for child: \(child.id), parent: \(parentId)")
        
        // Load Quizzes independently
        do {
            let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
            await MainActor.run {
                print("✅ Loaded \(fetchedQuizzes.count) quizzes for child dashboard")
                quizzes = fetchedQuizzes.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
            }
        } catch {
            print("❌ Error loading quizzes: \(error.localizedDescription)")
        }
        
        // Load Server Puzzles independently
        do {
            let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
            await MainActor.run {
                print("✅ Loaded \(fetchedPuzzles.count) puzzles for child dashboard")
                serverPuzzles = fetchedPuzzles
            }
        } catch {
            print("❌ Error loading puzzles: \(error.localizedDescription)")
        }
        
        await MainActor.run { isLoading = false }
    }
}

// MARK: - Tab Button
struct TabButton: View {
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

// MARK: - Child Info Card View
struct ChildInfoCardView: View {
    let child: Child
    let totalScore: Int
    
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
                ChildStatBadge(icon: "star.fill", label: "Points", value: "\(totalScore)", color: .yellow)
                ChildStatBadge(icon: "chart.bar.fill", label: "Level", value: child.level, color: .green)
                ChildStatBadge(icon: "calendar", label: "Age", value: "\(child.age)", color: .blue)
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

// MARK: - Child Stat Badge
struct ChildStatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.3)).frame(width: 50, height: 50)
                Image(systemName: icon).font(.title3).foregroundColor(color)
            }
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Child Quiz Content
struct ChildQuizContent: View {
    let pendingQuizzes: [AIQuizResponse]
    let completedQuizzes: [AIQuizResponse]
    let child: Child
    let onQuizCompleted: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if pendingQuizzes.isEmpty && completedQuizzes.isEmpty {
                ChildEmptyState(icon: "doc.text.fill", title: "No quizzes yet!", message: "Ask your parent to assign quizzes")
            } else {
                if !pendingQuizzes.isEmpty {
                    ChildSectionHeader(title: "Ready to Take", icon: "play.circle.fill")
                    ForEach(pendingQuizzes) { quiz in
                        NavigationLink(destination: QuizTakingScreen(quiz: quiz, child: child, onQuizCompleted: onQuizCompleted)) {
                            ChildQuizCard(quiz: quiz)
                        }
                    }
                }
                if !completedQuizzes.isEmpty {
                    ChildSectionHeader(title: "Completed", icon: "checkmark.circle.fill")
                    ForEach(completedQuizzes.prefix(3)) { quiz in
                        ChildCompletedQuizCard(quiz: quiz)
                    }
                }
            }
        }
    }
}

// MARK: - Child Quiz Card
struct ChildQuizCard: View {
    let quiz: AIQuizResponse
    
    var subjectIcon: String {
        switch quiz.subject.lowercased() {
        case "math": return "function"
        case "science": return "flask.fill"
        case "english": return "book.fill"
        default: return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch quiz.subject.lowercased() {
        case "math": return .blue
        case "science": return .green
        case "english": return .purple
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
                // CHANGÉ: Utiliser meaningfulTitle
                Text(quiz.meaningfulTitle).font(.title3.bold()).foregroundColor(.white)
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

// MARK: - Child Completed Quiz Card
struct ChildCompletedQuizCard: View {
    let quiz: AIQuizResponse
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
                // CHANGÉ: Utiliser meaningfulTitle
                Text(quiz.meaningfulTitle).font(.subheadline.bold()).foregroundColor(.white)
                Text(quiz.subject.capitalized).font(.caption).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("⭐")
                Text("\(quiz.score)%").font(.headline.bold()).foregroundColor(.yellow)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}




// MARK: - Child Empty State
struct ChildEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 50)).foregroundColor(.white.opacity(0.5))
            Text(title).font(.title3).foregroundColor(.white.opacity(0.7))
            Text(message).font(.subheadline).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Child Games Content
struct ChildGamesContent: View {
    let child: Child
    @Binding var selectedGame: SimpleGameType?
    @State private var gameHistory: [[String: Any]] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎮 Fun Games")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // All Game Cards
            ForEach(SimpleGameType.allCases, id: \.self) { game in
                ChildGameCard(
                    title: game.rawValue,
                    description: game.description,
                    icon: game.icon,
                    color: game.color,
                    gamesPlayed: getGamesPlayedCount(type: game.rawValue.lowercased().replacingOccurrences(of: " ", with: ""))
                ) {
                    selectedGame = game
                }
            }
            
            // Game History
            if !gameHistory.isEmpty {
                ChildGameHistory(child: child)
            }
        }
        .onAppear {
            loadGameHistory()
        }
    }
    
    private func loadGameHistory() {
        gameHistory = (UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []).reversed()
    }
    
    private func getGamesPlayedCount(type: String) -> Int {
        let typeKey: String
        switch type {
        case "memorymatch": typeKey = "memory"
        case "colormatch": typeKey = "color"
        case "shapematch": typeKey = "shape"
        case "numbersequence": typeKey = "sequence"
        default: typeKey = type
        }
        return gameHistory.filter { ($0["type"] as? String) == typeKey }.count
    }
}

// MARK: - Child Game Card
struct ChildGameCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gamesPlayed: Int
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
                    if gamesPlayed > 0 {
                        Text("Played \(gamesPlayed) times")
                            .font(.caption)
                            .foregroundColor(color)
                    }
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

// MARK: - Child Game History
struct ChildGameHistory: View {
    let child: Child
    @State private var games: [[String: Any]] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Recent Games").font(.headline).foregroundColor(.white)
            
            if games.isEmpty {
                Text("No games played yet!").font(.subheadline).foregroundColor(.white.opacity(0.7))
                    .padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).cornerRadius(12)
            } else {
                ForEach(games.prefix(3).indices, id: \.self) { index in
                    ChildGameHistoryRow(game: games[index])
                }
            }
        }
        .onAppear {
            games = (UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []).reversed()
        }
    }
}

// MARK: - Child Game History Row
struct ChildGameHistoryRow: View {
    let game: [String: Any]
    
    var gameType: SimpleGameType? {
        guard let typeString = game["type"] as? String else { return nil }
        switch typeString {
        case "memory": return .memory
        case "color": return .color
        case "shape": return .shape
        case "sequence": return .sequence
        case "math": return .math
        case "emoji": return .emoji
        default: return nil
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let gameType = gameType {
                ZStack {
                    Circle().fill(gameType.color.opacity(0.3)).frame(width: 40, height: 40)
                    Image(systemName: gameType.icon).font(.system(size: 18)).foregroundColor(gameType.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let gameType = gameType {
                    Text(gameType.rawValue).font(.subheadline.bold()).foregroundColor(.white)
                } else {
                    Text("Unknown Game").font(.subheadline.bold()).foregroundColor(.white)
                }
                
                if let date = game["date"] as? String {
                    Text("Recently played")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if let score = game["score"] as? Int {
                Text("\(score) pts")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}
