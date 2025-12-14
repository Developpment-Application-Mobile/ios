//
//  EnhancedChildDetailScreen.swift
//  EduKid
//
//  Professional UI with modern design principles
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
    @State private var isGeneratingReport = false
    @State private var generatedReport: ChildReviewResponseDto?
    @State private var showReportView = false
    @State private var reportError: String?
    @EnvironmentObject var authVM: AuthViewModel
    
    let tabs = ["Overview", "Quiz Results", "Puzzle Results", "Game Results"]
    
    var onBackClick: () -> Void = {}
    var onAssignQuizClick: () -> Void = {}
    var onGenerateQRClick: () -> Void = {}
    var onEditClick: () -> Void = {}
    var onCreatePuzzleClick: () -> Void = {}
    
    // ⭐ FIXED: Simplified - no longer needs parentId parameter
    func generateReport() {
        isGeneratingReport = true
        reportError = nil
        
        Task {
            do {
                print("🔍 Generating report for child: \(child.id)")
                
                // ⭐ Only pass kidId - parentId is fetched automatically
                let report = try await ChildReviewService.shared.generateReview(kidId: child.id)
                
                await MainActor.run {
                    self.generatedReport = report
                    self.isGeneratingReport = false
                    self.showReportView = true
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingReport = false
                    self.reportError = error.localizedDescription
                    print("❌ Error generating report: \(error)")
                }
            }
        }
    }
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.isAnswered || $0.answered > 0 }
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
                HStack(spacing: 16) {
                    Button(action: onBackClick) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Text(child.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Generate Report Button
                    Button(action: generateReport) {
                        if isGeneratingReport {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 24, height: 24)
                                .padding(10)
                                .background(Color.gray)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                    .disabled(isGeneratingReport)
                    
                    // Edit Button
                    Button(action: onEditClick) {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                // Show error if report generation failed
                if let error = reportError {
                    Text("Report Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
                
                Spacer().frame(height: 16)
                
                // Child Info Card with Avatar
                HStack(spacing: 16) {
                    // Avatar
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .background(Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.2))
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
                
                // Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = index
                                }
                            }) {
                                Text(tabs[index])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedTab == index ? Color(red: 0.4, green: 0.2, blue: 0.8) : .white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            if selectedTab == index {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.1))
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .background(Color.black.opacity(0.1))
                
                // Content Area
                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                } else {
                    Group {
                        if selectedTab == 0 {
                            OverviewTabView(
                                child: child,
                                quizzesCompleted: completedQuizzes.count,
                                puzzlesCompleted: completedPuzzles.count + completedServerPuzzles.count,
                                gamesPlayed: games.count,
                                totalCompleted: totalCompleted,
                                averageQuizScore: averageQuizScore,
                                averagePuzzleScore: averagePuzzleScore,
                                averageGameScore: averageGameScore,
                                totalScore: calculatedTotalScore,
                                onSchedule: { showActivityScheduler = true },
                                onQR: onGenerateQRClick,
                                onShop: { showGiftManagement = true }
                            )
                        } else if selectedTab == 1 {
                            QuizResultsTabView(quizzes: completedQuizzes) { quiz in
                                selectedQuiz = quiz
                                showQuizDetail = true
                            }
                        } else if selectedTab == 2 {
                            PuzzleResultsTabView(
                                localPuzzles: completedPuzzles,
                                serverPuzzles: completedServerPuzzles,
                                childId: child.id,
                                onDelete: { loadAllData() }
                            )
                        } else if selectedTab == 3 {
                            GameResultsTabView(games: games)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
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
        // ⭐ FIXED: Pass childId instead of report
        .sheet(isPresented: $showReportView) {
            NavigationStack {
                ChildReviewView(childId: child.id)
            }
        }
        .onAppear {
            Task {
                await loadAllData()
            }
        }
    }
    
    private func loadAllData() {
        isLoading = true
        
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        
        Task {
            guard let parentId = AuthService.shared.getParentId() else {
                await MainActor.run { isLoading = false }
                return
            }
            
            // 1. Fetch Quizzes
            do {
                let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
                await MainActor.run {
                    self.quizzes = fetchedQuizzes
                }
            } catch {
                print("Error loading quizzes: \(error)")
            }
            
            // 2. Fetch Puzzles (independently)
            do {
                let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
                await MainActor.run {
                    self.serverPuzzles = fetchedPuzzles
                }
            } catch {
                print("Error loading puzzles: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
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
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.8))
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
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
    
    let onSchedule: () -> Void
    let onQR: () -> Void
    let onShop: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Quick Actions Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Quick Actions")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        ActionButton(title: "Schedule", icon: "calendar.badge.clock", action: onSchedule)
                        ActionButton(title: "QR Code", icon: "qrcode", action: onQR)
                        ActionButton(title: "Shop", icon: "gift.fill", action: onShop)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Overall Performance Card
                VStack(spacing: 16) {
                    HStack {
                            Text("Overall Performance")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        OverviewStatCard(
                            title: "Total Score",
                            value: "\(totalScore)",
                            icon: "star.fill",
                            color: .yellow,
                            gradient: [Color.yellow, Color.orange]
                        )
                        
                        OverviewStatCard(
                            title: "Completed",
                            value: "\(totalCompleted)",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            gradient: [Color.green, Color.mint]
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Activity Breakdown Card
                VStack(spacing: 16) {
                    HStack {
                        
                        Text("Activity Breakdown")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        ActivityRow(
                            icon: "doc.text.fill",
                            title: "Quizzes",
                            completed: quizzesCompleted,
                            avgScore: averageQuizScore,
                            color: .blue,
                            gradient: [Color.blue, Color.cyan]
                        )
                        
                        ActivityRow(
                            icon: "puzzlepiece.fill",
                            title: "Puzzles",
                            completed: puzzlesCompleted,
                            avgScore: averagePuzzleScore,
                            color: .purple,
                            gradient: [Color.purple, Color.pink]
                        )
                        
                        ActivityRow(
                            icon: "gamecontroller.fill",
                            title: "Games",
                            completed: gamesPlayed,
                            avgScore: averageGameScore,
                            color: .orange,
                            gradient: [Color.orange, Color.red]
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Overview Stat Card
struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let completed: Int
    let avgScore: Int
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(completed) completed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(avgScore > 0 ? "\(avgScore)%" : "N/A")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("avg score")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Quiz Results Tab View
struct QuizResultsTabView: View {
    let quizzes: [AIQuizResponse]
    let onQuizTap: (AIQuizResponse) -> Void
    
    var body: some View {
        if quizzes.isEmpty {
            EmptyResultsView(emoji: "📝", message: "No quizzes completed yet", subtitle: "Complete a quiz to see results here")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(quizzes) { quiz in
                        Button(action: { onQuizTap(quiz) }) {
                            EnhancedAIQuizResultCardForParent(quiz: quiz)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Enhanced AI Quiz Result Card
struct EnhancedAIQuizResultCardForParent: View {
    let quiz: AIQuizResponse
    
    var scoreColor: Color {
        if quiz.score >= 80 { return .green }
        else if quiz.score >= 60 { return .orange }
        else { return .red }
    }
    
    var scoreGradient: [Color] {
        if quiz.score >= 80 { return [Color.green, Color.mint] }
        else if quiz.score >= 60 { return [Color.orange, Color.yellow] }
        else { return [Color.red, Color.pink] }
    }
    
    var scoreIcon: String {
        if quiz.score >= 80 { return "🎉" }
        else if quiz.score >= 60 { return "👍" }
        else { return "💪" }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(quiz.meaningfulTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(quiz.subject.capitalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        Label(quiz.difficulty.capitalized, systemImage: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    Text(scoreIcon)
                        .font(.system(size: 28))
                    
                    Text("\(quiz.score)%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: scoreGradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: scoreColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .padding(20)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                QuizStatLabel(icon: "questionmark.circle.fill", value: "\(quiz.questions.count)", label: "questions")
                QuizStatLabel(icon: "checkmark.circle.fill", value: "\(quiz.answered)", label: "answered")
                
                if let date = quiz.createdAt {
                    QuizStatLabel(icon: "calendar", value: formatDate(date), label: "completed")
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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

// MARK: - Quiz Stat Label
struct QuizStatLabel: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
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
            EmptyResultsView(emoji: "🧩", message: "No puzzles completed yet", subtitle: "Complete a puzzle to see results here")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(localPuzzles) { puzzle in
                        LocalPuzzleResultCardWithDelete(puzzle: puzzle) {
                            puzzleToDelete = puzzle.id
                            isLocalPuzzle = true
                            showDeleteAlert = true
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    ForEach(serverPuzzles) { puzzle in
                        ServerPuzzleResultCardWithDelete(puzzle: puzzle) {
                            puzzleToDelete = puzzle.id
                            isLocalPuzzle = false
                            showDeleteAlert = true
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
        withAnimation {
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
}

// MARK: - Local Puzzle Result Card With Delete
struct LocalPuzzleResultCardWithDelete: View {
    let puzzle: LocalPuzzle
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                puzzle.puzzleImage.backgroundColor,
                                puzzle.puzzleImage.backgroundColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: puzzle.puzzleImage.backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(puzzle.puzzleImage.emoji)
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(puzzle.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label(puzzle.difficulty.displayName, systemImage: "star.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Label("\(puzzle.attempts) tries", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.yellow.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Text("\(puzzle.score)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.8))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Server Puzzle Result Card With Delete
struct ServerPuzzleResultCardWithDelete: View {
    let puzzle: PuzzleResponse
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                puzzle.puzzleType.color,
                                puzzle.puzzleType.color.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: puzzle.puzzleType.color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: puzzle.puzzleType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(puzzle.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label(puzzle.puzzleDifficulty.displayName, systemImage: "star.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Label("\(puzzle.attempts) tries", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.yellow.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Text("\(puzzle.score)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.8))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Game Results Tab View
struct GameResultsTabView: View {
    let games: [[String: Any]]
    
    var body: some View {
        if games.isEmpty {
            EmptyResultsView(emoji: "🎮", message: "No games played yet", subtitle: "Play a game to see results here")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(games.indices, id: \.self) { index in
                        GameResultCard(game: games[index])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
    var gameGradient: [Color] {
        switch gameType {
        case "memory": return [Color.purple, Color.pink]
        case "color": return [Color.orange, Color.red]
        case "shape": return [Color.green, Color.mint]
        case "sequence": return [Color.blue, Color.cyan]
        case "puzzle": return [Color.purple, Color.blue]
        default: return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gameGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: gameColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: gameIcon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(gameTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let dateString = game["date"] as? String {
                    Text(formatDate(dateString))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 12) {
                    if let time = game["time"] as? Int {
                        Label(formatTime(time), systemImage: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let moves = game["moves"] as? Int {
                        Label("\(moves)", systemImage: "hand.tap.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else if let rounds = game["rounds"] as? Int {
                        Label("\(rounds) rounds", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else if let level = game["level"] as? Int {
                        Label("Level \(level)", systemImage: "chart.bar.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else if let attempts = game["attempts"] as? Int {
                        Label("\(attempts) tries", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            if let score = game["score"] as? Int {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.yellow.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    VStack(spacing: 2) {
                        Text("⭐")
                            .font(.system(size: 16))
                        Text("\(score)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Text(emoji)
                    .font(.system(size: 64))
            }
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
