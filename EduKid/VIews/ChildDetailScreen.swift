//
//  ChildDetailScreen.swift - Enhanced with Full Quiz Results for Parents
//  EduKid
//
//  Updated: November 16, 2025
//

import Foundation
import SwiftUI

struct ChildDetailScreen: View {
    let child: Child
    
    @State private var quizzes: [AIQuizResponse] = []
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var isLoading = false
    @State private var selectedQuiz: AIQuizResponse?
    @State private var showQuizDetail = false
    @State private var showGamesSheet = false
    @EnvironmentObject var authVM: AuthViewModel
    
    var onBackClick: () -> Void = {}
    var onGenerateQRClick: () -> Void = {}
    var onEditClick: () -> Void = {}
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered > 0 }
    }
    
    var completedPuzzles: [LocalPuzzle] {
        localPuzzles.filter { $0.isCompleted }
    }
    
    var completedServerPuzzles: [PuzzleResponse] {
        serverPuzzles.filter { $0.isCompleted }
    }
    
    var averageQuizScore: Int {
        guard !completedQuizzes.isEmpty else { return 0 }
        let total = completedQuizzes.reduce(0) { $0 + $1.score }
        return total / completedQuizzes.count
    }
    
    var averagePuzzleScore: Int {
        let localScores = completedPuzzles.map { $0.score }
        let serverScores = completedServerPuzzles.map { $0.score }
        let allScores = localScores + serverScores
        guard !allScores.isEmpty else { return 0 }
        return allScores.reduce(0, +) / allScores.count
    }
    
    var totalGamesCompleted: Int {
        games.count + completedPuzzles.count + completedServerPuzzles.count
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
            
            // Decorative elements
            DecorativeElementsDetail()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack(spacing: 16) {
                    Button(action: onBackClick) {
                        Text("←")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Text("\(child.name)'s Profile")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Edit button
                    Button(action: onEditClick) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 24)
                
                // Child info card
                HStack(spacing: 16) {
                    // Avatar
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .background(Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(child.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        
                        Text("\(child.age) years old")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        
                        HStack {
                            Text("Level \(child.level)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(Color.white.opacity(0.95))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { /* Scroll to top of overview */ }) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                            Text("Overview")
                        }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onGenerateQRClick) {
                        Text("📱 Show QR")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Overview Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ComprehensiveOverview(
                        child: child,
                        completedQuizzes: completedQuizzes.count,
                        totalQuizzes: quizzes.count,
                        completedPuzzles: completedPuzzles.count + completedServerPuzzles.count,
                        totalPuzzles: localPuzzles.count + serverPuzzles.count,
                        totalGamesCompleted: totalGamesCompleted,
                        averageQuizScore: averageQuizScore,
                        averagePuzzleScore: averagePuzzleScore,
                        quizzes: completedQuizzes,
                        games: games,
                        onQuizTap: { quiz in
                            selectedQuiz = quiz
                            showQuizDetail = true
                        },
                        onGamesTap: {
                            showGamesSheet = true
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showQuizDetail) {
            if let quiz = selectedQuiz {
                ParentQuizDetailView(quiz: quiz, child: child)
            }
        }
        .sheet(isPresented: $showGamesSheet) {
            GamesListSheet(games: games, child: child)
        }
        .onAppear {
            loadQuizzes()
        }
    }
    
    private func loadQuizzes() {
        isLoading = true
        
        // Load local data
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
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
                    print("Failed to load data: \(error)")
                }
            }
        }
    }
}

// MARK: - Comprehensive Overview
struct ComprehensiveOverview: View {
    let child: Child
    let completedQuizzes: Int
    let totalQuizzes: Int
    let completedPuzzles: Int
    let totalPuzzles: Int
    let totalGamesCompleted: Int
    let averageQuizScore: Int
    let averagePuzzleScore: Int
    let quizzes: [AIQuizResponse]
    let games: [[String: Any]]
    let onQuizTap: (AIQuizResponse) -> Void
    let onGamesTap: () -> Void
    
    var totalCompleted: Int { completedQuizzes + completedPuzzles }
    var totalActivities: Int { totalQuizzes + totalPuzzles }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Overall Stats (Glassmorphism)
                VStack(spacing: 12) {
                    Text("📊 Overall Performance")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        Button(action: onGamesTap) {
                            OverviewStatCard(title: "Games", value: "\(totalGamesCompleted)", icon: "gamecontroller.fill", color: .orange)
                        }
                        
                        OverviewStatCard(title: "Score", value: "\(child.Score)", icon: "star.fill", color: .yellow)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                // Overall Progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Overall Progress")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(totalCompleted) of \(totalActivities) completed")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(totalActivities == 0 ? 0 : (totalCompleted * 100 / totalActivities))%")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.green)
                                .frame(
                                    width: totalActivities == 0 ? 0 : geometry.size.width * CGFloat(totalCompleted) / CGFloat(totalActivities),
                                    height: 10
                                )
                        }
                    }
                    .frame(height: 10)
                }
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                // Quiz Results Section
                VStack(spacing: 12) {
                    HStack {
                        Text("📝 Quiz Results")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    if !quizzes.isEmpty {
                        ForEach(quizzes) { quiz in
                            Button(action: { onQuizTap(quiz) }) {
                                AIQuizResultCard(quiz: quiz)
                            }
                        }
                    } else {
                        Text("No completed quizzes yet")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }
}



// MARK: - Games List Sheet
struct GamesListSheet: View {
    let games: [[String: Any]]
    let child: Child
    @Environment(\.dismiss) var dismiss
    @State private var selectedSegment = 0
    
    var completedGames: [[String: Any]] {
        games.filter { game in
            // Games with score are considered completed
            (game["score"] as? Int) != nil
        }
    }
    
    var pendingGames: [[String: Any]] {
        games.filter { game in
            // Games without score are pending (if we ever save pending games)
            (game["score"] as? Int) == nil
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
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
                    // Segment Control
                    Picker("", selection: $selectedSegment) {
                        Text("Completed (\(completedGames.count))").tag(0)
                        Text("Pending (\(pendingGames.count))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                    
                    // Content
                    if selectedSegment == 0 {
                        if completedGames.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Text("🎮")
                                    .font(.system(size: 60))
                                Text("No completed games yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Complete some games to see them here!")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(completedGames.indices.reversed(), id: \.self) { index in
                                        GameResultCardSimple(game: completedGames[index])
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        if pendingGames.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Text("⏳")
                                    .font(.system(size: 60))
                                Text("No pending games")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("All games are completed!")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(pendingGames.indices, id: \.self) { index in
                                        GameResultCardSimple(game: pendingGames[index])
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(child.name)'s Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Game Result Card Simple
struct GameResultCardSimple: View {
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
                    .fill(gameColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: gameIcon)
                    .font(.title2)
                    .foregroundColor(gameColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(gameTitle)
                    .font(.headline)
                
                if let dateString = game["date"] as? String {
                    Text(formatDate(dateString))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    if let time = game["time"] as? Int {
                        Label(formatTime(time), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let moves = game["moves"] as? Int {
                        Label("\(moves)", systemImage: "hand.tap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let attempts = game["attempts"] as? Int {
                        Label("\(attempts) tries", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let score = game["score"] as? Int {
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.title3)
                    Text("\(score)")
                        .font(.title3.bold())
                        .foregroundColor(gameColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
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




// MARK: - AI Quiz Result Card
struct AIQuizResultCard: View {
    let quiz: AIQuizResponse
    
    var scoreColor: Color {
        if quiz.score >= 80 {
            return Color(red: 0.298, green: 0.686, blue: 0.314)
        } else if quiz.score >= 60 {
            return Color(red: 1.0, green: 0.655, blue: 0.149)
        } else {
            return Color(red: 0.937, green: 0.325, blue: 0.314)
        }
    }
    
    var scoreIcon: String {
        if quiz.score >= 80 {
            return "🎉"
        } else if quiz.score >= 60 {
            return "👍"
        } else {
            return "💪"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
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

// MARK: - Parent Quiz Detail View
struct ParentQuizDetailView: View {
    let quiz: AIQuizResponse
    let child: Child
    
    @Environment(\.dismiss) var dismiss
    @State private var showAllQuestions = false
    
    // Calculate results from quiz data
    var totalQuestions: Int {
        quiz.questions.count
    }
    
    var correctAnswers: Int {
        // Since we don't have individual answer tracking, use the score
        Int(Double(quiz.score) / 100.0 * Double(totalQuestions))
    }
    
    var incorrectAnswers: Int {
        totalQuestions - correctAnswers
    }
    
    var body: some View {
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
                VStack(spacing: 32) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Text("Quiz Results")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Child Info
                    HStack(spacing: 12) {
                        Image(child.avatarEmoji)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(child.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(child.age) years old")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Score Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 20)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: Double(quiz.score) / 100.0)
                            .stroke(
                                quiz.score >= 80 ? Color.green :
                                quiz.score >= 60 ? Color.orange : Color.red,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 8) {
                            Text("\(quiz.score)%")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(correctAnswers)/\(totalQuestions)")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Quiz Info
                    VStack(spacing: 16) {
                        HStack {
                            Text("Topic")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(quiz.topic.capitalized)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Subject")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(quiz.subject.capitalized)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Difficulty")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(quiz.difficulty.capitalized)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        HStack {
                            Text("Correct Answers")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(correctAnswers)")
                                .font(.subheadline.bold())
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Incorrect Answers")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(incorrectAnswers)")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // All Questions Button
                    Button(action: { showAllQuestions.toggle() }) {
                        HStack {
                            Image(systemName: showAllQuestions ? "chevron.up" : "chevron.down")
                            Text(showAllQuestions ? "Hide All Questions" : "View All Questions")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    // Questions List
                    if showAllQuestions {
                        VStack(spacing: 16) {
                            ForEach(Array(quiz.questions.enumerated()), id: \.offset) { index, question in
                                ParentQuestionCard(
                                    questionNumber: index + 1,
                                    question: question
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
    }
}

// MARK: - Parent Question Card
struct ParentQuestionCard: View {
    let questionNumber: Int
    let question: AIQuestion
    
    let letters = ["A", "B", "C", "D"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question
            HStack(alignment: .top, spacing: 8) {
                Text("\(questionNumber).")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(question.questionText)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Options
            VStack(spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(index == question.correctAnswerIndex ? Color.green.opacity(0.3) : Color.white.opacity(0.2))
                                .frame(width: 30, height: 30)
                            
                            Text(letters[index])
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text(option)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        if index == question.correctAnswerIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Explanation
            if let explanation = question.explanation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Explanation")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    
                    Text(explanation)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Decorative Elements Detail
struct DecorativeElementsDetail: View {
    var body: some View {
        ZStack {
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .offset(x: 150, y: -350)
            
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .rotationEffect(.degrees(38.66))
                .offset(x: -150, y: 360)
        }
    }
}
