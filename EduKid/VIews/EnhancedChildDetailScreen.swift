//
//  EnhancedChildDetailScreen.swift
//  EduKid
//
//  Professional UI with modern design principles
//

import SwiftUI


struct EnhancedChildDetailScreen: View {
    let child: Child
    

    @State private var quizzes: [AIQuizResponse] = []
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var inventory: [Gift] = []
    @State private var netScore: Int = 0
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
        let stats = ScoreCalculationService.shared.calculateChildStats(
            quizzes: quizzes,
            localPuzzles: localPuzzles,
            serverPuzzles: serverPuzzles,
            games: games
        )
        return stats.totalScore
    }
    
    var displayScore: Int {
        // Return NET score if inventory is loaded, otherwise gross score
        return netScore > 0 ? netScore : calculatedTotalScore
    }
    
    var totalCompleted: Int {
        let stats = ScoreCalculationService.shared.calculateChildStats(
            quizzes: quizzes,
            localPuzzles: localPuzzles,
            serverPuzzles: serverPuzzles,
            games: games
        )
        return stats.totalCompleted
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
                    
                    Spacer()
                    
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
                            Label("\(displayScore) pts", systemImage: "star.fill")
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
                    OverviewTabView(
                        child: child,
                        quizzesCompleted: completedQuizzes.count,
                        puzzlesCompleted: completedPuzzles.count + completedServerPuzzles.count,
                        gamesPlayed: games.count,
                        totalCompleted: totalCompleted,
                        averageQuizScore: averageQuizScore,
                        averagePuzzleScore: averagePuzzleScore,
                        averageGameScore: averageGameScore,
                        totalScore: displayScore,
                        onQR: onGenerateQRClick,
                        onGenerateReport: generateReport,
                        isGeneratingReport: isGeneratingReport,
                        completedQuizzes: completedQuizzes,
                        completedLocalPuzzles: completedPuzzles,
                        completedServerPuzzles: completedServerPuzzles,
                        games: games,
                        onQuizTap: { quiz in
                            selectedQuiz = quiz
                            showQuizDetail = true
                        },
                        onPuzzleDelete: { loadAllData() }
                    )
                }
            }
        }
        .sheet(isPresented: $showQuizDetail) {
            if let quiz = selectedQuiz {
                ParentQuizDetailView(quiz: quiz, child: child)
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
                    // Check if any quiz has a date
                    let hasAnyDates = fetchedQuizzes.contains { $0.createdAt != nil }
                    
                    if hasAnyDates {
                        // Sort by createdAt descending (newest first)
                        self.quizzes = fetchedQuizzes.sorted { quiz1, quiz2 in
                            if let date1 = quiz1.createdAt, let date2 = quiz2.createdAt {
                                return date1 > date2
                            }
                            if quiz1.createdAt != nil { return true }
                            if quiz2.createdAt != nil { return false }
                            return false
                        }
                    } else {
                        // If no dates, reverse the array (assuming API returns oldest first)
                        self.quizzes = Array(fetchedQuizzes.reversed())
                    }
                }
            } catch {
                print("Error loading quizzes: \(error)")
            }
            
            // 2. Fetch Puzzles (independently)
            do {
                let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
                await MainActor.run {
                    // Check if any puzzle has a date
                    let hasAnyDates = fetchedPuzzles.contains { $0.createdAt != nil }
                    
                    if hasAnyDates {
                        // Sort by createdAt descending (newest first)
                        self.serverPuzzles = fetchedPuzzles.sorted { puzzle1, puzzle2 in
                            if let date1 = puzzle1.createdAt, let date2 = puzzle2.createdAt {
                                return date1 > date2
                            }
                            if puzzle1.createdAt != nil { return true }
                            if puzzle2.createdAt != nil { return false }
                            return false
                        }
                    } else {
                        // If no dates, reverse the array (assuming API returns oldest first)
                        self.serverPuzzles = Array(fetchedPuzzles.reversed())
                    }
                }
            } catch {
                print("Error loading puzzles: \(error)")
            }
            
            // 3. Load inventory and calculate NET score
            do {
                if let token = AuthService.shared.getToken() {
                    let baseURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
                    let pUrl = URL(string: "\(baseURL)/parents/\(parentId)")!
                    var req = URLRequest(url: pUrl)
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    req.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
                    let (d, _) = try await URLSession.shared.data(for: req)
                    
                    if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                       let childrenArr = json["children"] as? [[String: Any]] {
                        if let childDict = childrenArr.first(where: { ($0["_id"] as? String) == child.id || ($0["id"] as? String) == child.id }) {
                            if let invArr = childDict["inventory"] as? [[String: Any]] {
                                let data = try JSONSerialization.data(withJSONObject: invArr)
                                let loadedInventory = try JSONDecoder().decode([Gift].self, from: data)
                                
                                await MainActor.run {
                                    self.inventory = loadedInventory
                                    // Calculate NET score
                                    let grossScore = self.calculatedTotalScore
                                    let totalSpent = loadedInventory.reduce(0) { $0 + $1.cost }
                                    self.netScore = max(0, grossScore - totalSpent)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error loading inventory: \(error)")
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

// MARK: - Large Action Button (for 2-column layout)
struct LargeActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.8),
                                    color.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 36)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
            )
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
    
    let onQR: () -> Void
    let onGenerateReport: () -> Void
    var isGeneratingReport: Bool = false
    
    // Results data
    var completedQuizzes: [AIQuizResponse] = []
    var completedLocalPuzzles: [LocalPuzzle] = []
    var completedServerPuzzles: [PuzzleResponse] = []
    var games: [[String: Any]] = []
    var onQuizTap: (AIQuizResponse) -> Void = { _ in }
    var onPuzzleDelete: () -> Void = {}
    
    // State for results popup
    @State private var showResultsSheet = false
    @State private var selectedResultsTab = 0
    
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
                    
                    // QR Code and Results Buttons Side by Side
                    HStack(spacing: 12) {
                        LargeActionButton(
                            title: "QR Code",
                            icon: "qrcode",
                            color: Color.blue,
                            action: onQR
                        )
                        
                        LargeActionButton(
                            title: "Results",
                            icon: "list.bullet.clipboard",
                            color: Color.green,
                            action: { showResultsSheet = true }
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
                
                // Report Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Report")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    Button(action: onGenerateReport) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                if isGeneratingReport {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Generate Report")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(isGeneratingReport ? "Generating..." : "View detailed report")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .disabled(isGeneratingReport)
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
        .sheet(isPresented: $showResultsSheet) {
            ResultsPopupView(
                completedQuizzes: completedQuizzes,
                completedLocalPuzzles: completedLocalPuzzles,
                completedServerPuzzles: completedServerPuzzles,
                games: games,
                child: child,
                onQuizTap: onQuizTap,
                onPuzzleDelete: onPuzzleDelete
            )
        }
    }
}

// MARK: - Results Popup View
struct ResultsPopupView: View {
    let completedQuizzes: [AIQuizResponse]
    let completedLocalPuzzles: [LocalPuzzle]
    let completedServerPuzzles: [PuzzleResponse]
    let games: [[String: Any]]
    let child: Child
    let onQuizTap: (AIQuizResponse) -> Void
    let onPuzzleDelete: () -> Void
    
    @State private var selectedTab = 0
    @State private var selectedQuiz: AIQuizResponse?
    @State private var showQuizDetail = false
    @Environment(\.dismiss) var dismiss
    
    let tabs = ["Quizzes", "Puzzles", "Games"]
    
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
                    Text("Results")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Professional Tabs with Better Design
                HStack(spacing: 12) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: tabIcon(for: index))
                                    .font(.system(size: 16, weight: .semibold))
                                Text(tabs[index])
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        selectedTab == index ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                tabColor(for: index).opacity(0.8),
                                                tabColor(for: index).opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.15),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedTab == index ? tabColor(for: index).opacity(0.5) : Color.white.opacity(0.2),
                                        lineWidth: selectedTab == index ? 2 : 1
                                    )
                            )
                            .shadow(
                                color: selectedTab == index ? tabColor(for: index).opacity(0.3) : Color.clear,
                                radius: selectedTab == index ? 8 : 0,
                                x: 0,
                                y: selectedTab == index ? 4 : 0
                            )
                            .scaleEffect(selectedTab == index ? 1.02 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.08))
                
                // Content
                TabView(selection: $selectedTab) {
                    // Quiz Results
                    QuizResultsTabView(quizzes: completedQuizzes, onQuizTap: { quiz in
                        selectedQuiz = quiz
                        showQuizDetail = true
                    })
                        .tag(0)
                    
                    // Puzzle Results
                    PuzzleResultsTabView(
                        localPuzzles: completedLocalPuzzles,
                        serverPuzzles: completedServerPuzzles,
                        childId: child.id,
                        onDelete: onPuzzleDelete
                    )
                    .tag(1)
                    
                    // Game Results
                    GameResultsTabView(games: games)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .sheet(isPresented: $showQuizDetail) {
            if let quiz = selectedQuiz {
                ParentQuizDetailView(quiz: quiz, child: child)
            }
        }
    }
    
    func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "doc.text.fill"
        case 1: return "puzzlepiece.fill"
        case 2: return "gamecontroller.fill"
        default: return "circle"
        }
    }
    
    func tabColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .purple
        case 2: return .orange
        default: return .gray
        }
    }
}

// MARK: - Results Section Helper Views
struct ResultsSectionHeader: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.3))
                    )
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }
}

struct EmptyResultsRowView: View {
    let message: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

struct CompactQuizResultCard: View {
    let quiz: AIQuizResponse
    
    var scoreColor: Color {
        if quiz.score >= 80 { return .green }
        else if quiz.score >= 60 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.meaningfulTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(quiz.subject.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text("\(quiz.score)%")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(scoreColor.opacity(0.3))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CompactPuzzleResultCard: View {
    let puzzle: LocalPuzzle
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(puzzle.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(puzzle.difficulty.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text("\(puzzle.score) pts")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.3))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CompactServerPuzzleResultCard: View {
    let puzzle: PuzzleResponse
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(puzzle.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(puzzle.difficulty.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text("\(puzzle.score) pts")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.3))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CompactGameResultCard: View {
    let game: [String: Any]
    let index: Int
    
    var gameType: String { (game["type"] as? String) ?? "game" }
    
    var gameName: String {
        // First try to get the name from the game data
        if let name = game["name"] as? String, !name.isEmpty {
            return name
        }
        // Otherwise translate the game type
        switch gameType {
        case "memory": return "Memory Match"
        case "color": return "Color Match"
        case "shape": return "Shape Match"
        case "sequence": return "Number Sequence"
        case "puzzle": return "Puzzle"
        default: return "Game"
        }
    }
    
    var gameScore: Int {
        game["score"] as? Int ?? 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(gameName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let date = game["date"] as? String {
                    Text(date)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Text("\(gameScore) pts")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.3))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
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
                    ForEach(quizzes.prefix(10)) { quiz in
                        Button(action: { onQuizTap(quiz) }) {
                            EnhancedAIQuizResultCardForParent(quiz: quiz)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Show count if there are more than 10
                    if quizzes.count > 10 {
                        Text("Showing 10 of \(quizzes.count) quizzes")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
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
    
    // Calculate actual answered count from questions
    var actualAnsweredCount: Int {
        if quiz.answered > 0 {
            return quiz.answered
        }
        // Fallback: count questions with userAnswerIndex
        return quiz.questions.filter { $0.userAnswerIndex != nil }.count
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
                QuizStatLabel(icon: "checkmark.circle.fill", value: "\(actualAnsweredCount)", label: "answered")
                
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
    @State private var puzzleGames: [[String: Any]] = []
    
    // Combine all puzzles and limit to 10
    var allPuzzles: [(id: String, isLocal: Bool, index: Int)] {
        var combined: [(id: String, isLocal: Bool, index: Int)] = []
        
        // Add local puzzles
        for (index, puzzle) in localPuzzles.enumerated() {
            combined.append((id: puzzle.id, isLocal: true, index: index))
        }
        
        // Add server puzzles
        for (index, puzzle) in serverPuzzles.enumerated() {
            combined.append((id: puzzle.id, isLocal: false, index: index))
        }
        
        // Add puzzle games
        for (index, _) in puzzleGames.enumerated() {
            combined.append((id: "game_\(index)", isLocal: false, index: index))
        }
        
        return Array(combined.prefix(10))
    }
    
    var totalPuzzleCount: Int {
        localPuzzles.count + serverPuzzles.count + puzzleGames.count
    }
    
    var body: some View {
        Group {
            if localPuzzles.isEmpty && serverPuzzles.isEmpty && puzzleGames.isEmpty {
                EmptyResultsView(emoji: "🧩", message: "No puzzles completed yet", subtitle: "Complete a puzzle to see results here")
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        // Local Puzzles (limited)
                        ForEach(localPuzzles.prefix(10)) { puzzle in
                            LocalPuzzleResultCardWithDelete(puzzle: puzzle) {
                                puzzleToDelete = puzzle.id
                                isLocalPuzzle = true
                                showDeleteAlert = true
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Server Puzzles (limited to remaining slots)
                        let remainingSlots = max(0, 10 - localPuzzles.prefix(10).count)
                        ForEach(serverPuzzles.prefix(remainingSlots)) { puzzle in
                            ServerPuzzleResultCardWithDelete(puzzle: puzzle) {
                                puzzleToDelete = puzzle.id
                                isLocalPuzzle = false
                                showDeleteAlert = true
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Puzzle Games (limited to remaining slots)
                        let remainingForGames = max(0, 10 - localPuzzles.prefix(10).count - serverPuzzles.prefix(remainingSlots).count)
                        ForEach(puzzleGames.prefix(remainingForGames).indices, id: \.self) { index in
                            PuzzleGameResultCard(game: puzzleGames[index])
                        }
                        
                        // Show count if there are more than 10
                        if totalPuzzleCount > 10 {
                            Text("Showing 10 of \(totalPuzzleCount) puzzles")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
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
        .onAppear {
            loadPuzzleGames()
        }
    }
    
    private func loadPuzzleGames() {
        // Load puzzle games from UserDefaults
        if let allGames = UserDefaults.standard.array(forKey: "child_\(childId)_games") as? [[String: Any]] {
            puzzleGames = allGames.filter { game in
                let gameType = (game["type"] as? String) ?? ""
                return gameType == "puzzle"
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

// MARK: - Puzzle Game Result Card
struct PuzzleGameResultCard: View {
    let game: [String: Any]
    
    var gameTitle: String {
        if let name = game["name"] as? String, !name.isEmpty {
            return name
        }
        return "Puzzle Game"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(gameTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let dateString = game["date"] as? String {
                    Text(formatDate(dateString))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 12) {
                    if let attempts = game["attempts"] as? Int {
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
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.yellow.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Text("\(score)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
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
}

// MARK: - Game Results Tab View
struct GameResultsTabView: View {
    let games: [[String: Any]]
    
    // Filter out puzzle type games - they should appear in Puzzle Results tab
    var filteredGames: [[String: Any]] {
        games.filter { game in
            let gameType = (game["type"] as? String) ?? ""
            return gameType != "puzzle"
        }
    }
    
    var body: some View {
        if filteredGames.isEmpty {
            EmptyResultsView(emoji: "🎮", message: "No games played yet", subtitle: "Play a game to see results here")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(filteredGames.prefix(10).indices, id: \.self) { index in
                        GameResultCard(game: filteredGames[index])
                    }
                    
                    // Show count if there are more than 10
                    if filteredGames.count > 10 {
                        Text("Showing 10 of \(filteredGames.count) games")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
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
