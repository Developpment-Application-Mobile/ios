import SwiftUI

struct ChildReviewView: View {
    let childId: String // MongoDB _id of the child
    
    @Environment(\.dismiss) var dismiss
    @State private var report: ChildReviewResponseDto?
    @State private var child: Child?
    @State private var quizzes: [AIQuizResponse] = []
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false
    @State private var selectedTab = 0
    
    // Removed tabs - only showing Overview now
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.98, green: 0.97, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.purple.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(
                                Animation.linear(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: isLoading
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text("Generating Your Report")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Our AI is analyzing performance data...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            } else if let error = errorMessage {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("Unable to Generate Report")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Button(action: { Task { await loadReport() } }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: 200)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                }
                .padding()
            } else if let report = report, let child = child {
                VStack(spacing: 0) {
                    // Removed tab selector - only showing Overview
                    
                    ScrollView(showsIndicators: false) {
                        // Overview Content (removed tab condition)
                        VStack(spacing: 24) {
                                // Premium Header Card with REAL child name
                                ZStack {
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.55, green: 0.35, blue: 0.95),
                                                    Color(red: 0.45, green: 0.50, blue: 0.98)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
                                    
                                    VStack(spacing: 20) {
                                        VStack(spacing: 8) {
                                            Text("Activity Report for")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            // ⭐ FIXED: Show real child name
                                            Text(child.name)
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        
                                        HStack(spacing: 16) {
                                            PremiumStatBadge(
                                                icon: "star.fill",
                                                value: "\(child.level)",
                                                label: "Level",
                                                color: Color.yellow
                                            )
                                            
                                            PremiumStatBadge(
                                                icon: "checkmark.circle.fill",
                                                value: "\(report.totalQuizzes)",
                                                label: "Quizzes",
                                                color: Color.green
                                            )
                                            
                                            PremiumStatBadge(
                                                icon: "chart.bar.fill",
                                                value: String(format: "%.0f%%", report.overallAverage),
                                                label: "Avg Score",
                                                color: Color.blue
                                            )
                                        }
                                    }
                                    .padding(28)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // AI Summary Card
                                PremiumCard(
                                    icon: "sparkles",
                                    iconColor: Color(red: 0.55, green: 0.35, blue: 0.95),
                                    title: "AI Analysis Summary"
                                ) {
                                    Text(report.summary)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineSpacing(6)
                                }
                                
                                // Strengths & Focus Areas
                                HStack(alignment: .top, spacing: 16) {
                                    PremiumInsightCard(
                                        icon: "arrow.up.circle.fill",
                                        iconColor: Color(red: 0.2, green: 0.78, blue: 0.35),
                                        title: "Strengths",
                                        content: report.strengths
                                    )
                                    
                                    PremiumInsightCard(
                                        icon: "target",
                                        iconColor: Color(red: 1.0, green: 0.58, blue: 0.0),
                                        title: "Focus Areas",
                                        content: report.weaknesses
                                    )
                                }
                                .padding(.horizontal, 20)
                                
                                // Topic Performance
                                PremiumCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    iconColor: Color(red: 0.35, green: 0.65, blue: 0.95),
                                    title: "Topic Performance"
                                ) {
                                    VStack(spacing: 16) {
                                        ForEach(report.performanceByTopic) { topic in
                                            PremiumTopicRow(topic: topic)
                                        }
                                    }
                                }
                                
                                // Recommendations
                                PremiumCard(
                                    icon: "lightbulb.fill",
                                    iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                                    title: "Expert Recommendations"
                                ) {
                                    Text(report.recommendations)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineSpacing(6)
                                }
                                
                                // Action Buttons
                                VStack(spacing: 12) {
                                    // Generate PDF Report Button
                                    Button(action: { generateAndDownloadPDF() }) {
                                        HStack(spacing: 12) {
                                            if isGeneratingPDF {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Image(systemName: "doc.text.fill")
                                                    .font(.system(size: 18, weight: .semibold))
                                            }
                                            Text(isGeneratingPDF ? "Generating PDF..." : "Generate PDF Report")
                                                .font(.system(size: 17, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(height: 56)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.55, green: 0.35, blue: 0.95),
                                                    Color(red: 0.45, green: 0.50, blue: 0.98)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                                    }
                                    .disabled(isGeneratingPDF)
                                    
                                    // Share Button
                                    Button(action: { preparePDF() }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 18, weight: .semibold))
                                            Text("Share Report")
                                                .font(.system(size: 17, weight: .semibold))
                                        }
                                        .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.95))
                                        .frame(height: 56)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(red: 0.55, green: 0.35, blue: 0.95), lineWidth: 2)
                                                .background(Color.white)
                                                .cornerRadius(16)
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                            }
                            .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle("Activity Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadReport()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func loadReport() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Loading report for child: \(childId)")
            
            // 1. Generate AI report
            let generatedReport = try await ChildReviewService.shared.generateReview(kidId: childId)
            
            // 2. Load child data from AuthService
            guard let parentId = AuthService.shared.getParentId() else {
                throw AuthError.serverError("No parent ID found")
            }
            
            let childrenResponse = try await AuthService.shared.getChildren()
            let childData = childrenResponse.first { $0.id == childId }
            
            // Convert ChildResponse to Child model
            let child: Child? = childData.map { childResponse in
                Child(
                    id: childResponse.id ?? childId,
                    name: childResponse.name,
                    age: childResponse.age,
                    level: childResponse.level ?? "\(childResponse.age - 3)",
                    avatarEmoji: childResponse.avatarEmoji,
                    Score: 0,
                    quizzes: [],
                    totalPoints: 0,
                    connectionToken: childResponse.connectionToken ?? childId,
                    shopCatalog: childResponse.shopCatalog,
                    inventory: childResponse.inventory,
                    quests: childResponse.quests
                )
            }
            
            // 3. Load activity data
            let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(parentId: parentId, kidId: childId)
            let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: childId)
            let loadedLocalPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: childId)
            let loadedGames = UserDefaults.standard.array(forKey: "child_\(childId)_games") as? [[String: Any]] ?? []
            
            await MainActor.run {
                self.report = generatedReport
                self.child = child
                
                // Check if any quiz or puzzle has a date
                let quizzesHaveDates = fetchedQuizzes.contains { $0.createdAt != nil }
                let puzzlesHaveDates = fetchedPuzzles.contains { $0.createdAt != nil }
                
                // Sort quizzes by createdAt descending (newest first)
                if quizzesHaveDates {
                    self.quizzes = fetchedQuizzes.filter { $0.isAnswered || $0.answered > 0 }.sorted { quiz1, quiz2 in
                        if let date1 = quiz1.createdAt, let date2 = quiz2.createdAt {
                            return date1 > date2
                        }
                        if quiz1.createdAt != nil { return true }
                        if quiz2.createdAt != nil { return false }
                        return false
                    }
                } else {
                    self.quizzes = Array(fetchedQuizzes.filter { $0.isAnswered || $0.answered > 0 }.reversed())
                }
                
                // Sort puzzles by createdAt descending (newest first)
                if puzzlesHaveDates {
                    self.serverPuzzles = fetchedPuzzles.filter { $0.isCompleted }.sorted { puzzle1, puzzle2 in
                        if let date1 = puzzle1.createdAt, let date2 = puzzle2.createdAt {
                            return date1 > date2
                        }
                        if puzzle1.createdAt != nil { return true }
                        if puzzle2.createdAt != nil { return false }
                        return false
                    }
                } else {
                    self.serverPuzzles = Array(fetchedPuzzles.filter { $0.isCompleted }.reversed())
                }
                
                self.localPuzzles = loadedLocalPuzzles.filter { $0.isCompleted }
                self.games = loadedGames
                self.isLoading = false
                print("✅ Report loaded for: \(child?.name ?? "Unknown")")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ Error loading report: \(error)")
            }
        }
    }
    
    private func generateAndDownloadPDF() {
        guard let report = report,
              let child = child,
              let data = Data(base64Encoded: report.pdfBase64) else {
            print("❌ No PDF data available")
            return
        }
        
        isGeneratingPDF = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "\(child.name)_Activity_Report_\(dateString).pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: tempURL)
                
                // Save to Files app
                let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
                documentPicker.modalPresentationStyle = .formSheet
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(documentPicker, animated: true)
                }
                
                isGeneratingPDF = false
                print("✅ PDF generated and ready to save")
            } catch {
                print("❌ Error saving PDF: \(error)")
                isGeneratingPDF = false
            }
        }
    }
    
    private func preparePDF() {
        guard let report = report,
              let child = child,
              let data = Data(base64Encoded: report.pdfBase64) else {
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(child.name)_Report.pdf")
        
        do {
            try data.write(to: tempURL)
            self.pdfURL = tempURL
            self.showingShareSheet = true
        } catch {
            print("❌ Error saving PDF: \(error)")
        }
    }
}

// MARK: - Real Activity History View
struct RealActivityHistoryView: View {
    let child: Child
    let report: ChildReviewResponseDto
    let quizzes: [AIQuizResponse]
    let localPuzzles: [LocalPuzzle]
    let serverPuzzles: [PuzzleResponse]
    let games: [[String: Any]]
    
    // Combine all activities with timestamps
    var allActivities: [ActivityItem] {
        var items: [ActivityItem] = []
        
        // Add quizzes
        for quiz in quizzes {
            if let dateString = quiz.createdAt,
               let date = ISO8601DateFormatter().date(from: dateString) {
                items.append(ActivityItem(
                    type: .quiz,
                    title: quiz.meaningfulTitle,
                    date: date,
                    score: quiz.score,
                    maxScore: 100,
                    details: "\(quiz.subject.capitalized) • \(quiz.difficulty.capitalized)",
                    icon: "doc.text.fill",
                    color: .blue
                ))
            }
        }
        
        // Add local puzzles
        for puzzle in localPuzzles {
            items.append(ActivityItem(
                type: .puzzle,
                title: puzzle.title,
                date: Date(), // Use current date as fallback for local puzzles
                score: puzzle.score,
                maxScore: 100,
                details: "\(puzzle.difficulty.displayName) • \(puzzle.attempts) attempts",
                icon: "puzzlepiece.fill",
                color: puzzle.puzzleImage.backgroundColor
            ))
        }
        
        // Add server puzzles
        for puzzle in serverPuzzles {
            // Unwrap the completedAt string safely
            if let completedAtString = puzzle.completedAt,
               let date = ISO8601DateFormatter().date(from: completedAtString) {
                items.append(ActivityItem(
                    type: .puzzle,
                    title: puzzle.title,
                    date: date,
                    score: puzzle.score,
                    maxScore: 100,
                    details: "\(puzzle.puzzleDifficulty.displayName) • \(puzzle.attempts) attempts",
                    icon: puzzle.puzzleType.icon,
                    color: puzzle.puzzleType.color
                ))
            }
        }
        
        // Add games
        for game in games {
            if let dateString = game["date"] as? String,
               let date = ISO8601DateFormatter().date(from: dateString),
               let score = game["score"] as? Int {
                let type = game["type"] as? String ?? "game"
                items.append(ActivityItem(
                    type: .game,
                    title: getGameTitle(type: type),
                    date: date,
                    score: score,
                    maxScore: 100,
                    details: getGameDetails(game: game),
                    icon: getGameIcon(type: type),
                    color: getGameColor(type: type)
                ))
            }
        }
        
        // Sort by date (newest first)
        return items.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Child Summary Card
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    // Child avatar
                    Text(child.avatarEmoji)
                        .font(.system(size: 40))
                        .frame(width: 64, height: 64)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Age \(child.age) • Level \(child.level)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    HistoryStatRow(
                        icon: "calendar",
                        label: "Report Generated",
                        value: formatDate(report.generatedAt)
                    )
                    
                    HistoryStatRow(
                        icon: "chart.bar.fill",
                        label: "Current Score",
                        value: "\(report.currentScore) pts"
                    )
                    
                    HistoryStatRow(
                        icon: "star.fill",
                        label: "Lifetime Score",
                        value: "\(report.lifetimeScore) pts"
                    )
                    
                    HistoryStatRow(
                        icon: "trophy.fill",
                        label: "Progression Level",
                        value: "Level \(report.progressionLevel)"
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            
            // Activity Timeline
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.green)
                    }
                    
                    Text("Activity Timeline")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(allActivities.count) activities")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                if allActivities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("No activities yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(allActivities) { activity in
                            RealActivityCard(activity: activity)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func getGameTitle(type: String) -> String {
        switch type {
        case "memory": return "Memory Match"
        case "color": return "Color Match"
        case "shape": return "Shape Match"
        case "sequence": return "Number Sequence"
        case "puzzle": return "Puzzle Game"
        default: return "Game"
        }
    }
    
    private func getGameIcon(type: String) -> String {
        switch type {
        case "memory": return "brain.head.profile"
        case "color": return "paintpalette.fill"
        case "shape": return "square.on.circle"
        case "sequence": return "number.circle"
        case "puzzle": return "puzzlepiece.fill"
        default: return "gamecontroller.fill"
        }
    }
    
    private func getGameColor(type: String) -> Color {
        switch type {
        case "memory": return .purple
        case "color": return .orange
        case "shape": return .green
        case "sequence": return .blue
        case "puzzle": return Color(red: 0.686, green: 0.494, blue: 0.906)
        default: return .gray
        }
    }
    
    private func getGameDetails(game: [String: Any]) -> String {
        var details: [String] = []
        
        if let time = game["time"] as? Int {
            let mins = time / 60
            let secs = time % 60
            details.append(String(format: "%d:%02d", mins, secs))
        }
        
        if let moves = game["moves"] as? Int {
            details.append("\(moves) moves")
        } else if let rounds = game["rounds"] as? Int {
            details.append("\(rounds) rounds")
        } else if let level = game["level"] as? Int {
            details.append("Level \(level)")
        }
        
        return details.joined(separator: " • ")
    }
}

// MARK: - Activity Item Model
struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let date: Date
    let score: Int
    let maxScore: Int
    let details: String
    let icon: String
    let color: Color
    
    enum ActivityType {
        case quiz, puzzle, game
    }
}

// MARK: - Real Activity Card
struct RealActivityCard: View {
    let activity: ActivityItem
    
    var scorePercentage: Int {
        guard activity.maxScore > 0 else { return 0 }
        return Int((Double(activity.score) / Double(activity.maxScore)) * 100)
    }
    
    var scoreColor: Color {
        if scorePercentage >= 80 { return .green }
        if scorePercentage >= 60 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(activity.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: activity.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(activity.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(activity.details)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formatActivityDate(activity.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
            
            // Score
            VStack(spacing: 4) {
                Text("\(activity.score)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(scoreColor)
                
                Text("\(scorePercentage)%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemGray6).opacity(0.5))
        )
    }
    
    private func formatActivityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - History Stat Row
struct HistoryStatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.95))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Premium Stat Badge
struct PremiumStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Card
struct PremiumCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Premium Insight Card
struct PremiumInsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Premium Topic Row
struct PremiumTopicRow: View {
    let topic: ReviewTopicPerformance
    
    var scoreColor: Color {
        if topic.averageScore >= 80 { return Color(red: 0.2, green: 0.78, blue: 0.35) }
        if topic.averageScore >= 60 { return Color(red: 1.0, green: 0.8, blue: 0.0) }
        return Color(red: 1.0, green: 0.34, blue: 0.34)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                Text(topic.topic.capitalized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(Int(topic.averageScore))%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    ZStack {
                        Circle()
                            .fill(scoreColor.opacity(0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: topic.averageScore >= 80 ? "checkmark" : "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(scoreColor)
                    }
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [scoreColor, scoreColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (CGFloat(topic.averageScore) / 100),
                            height: 10
                        )
                }
            }
            .frame(height: 10)
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(topic.quizzesCompleted) Quizzes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(scoreColor)
                    Text("High: \(topic.highestScore)%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
