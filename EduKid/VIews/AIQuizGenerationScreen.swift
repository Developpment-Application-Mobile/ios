

import SwiftUI

// MARK: - Adaptive Quiz Generation Screen
struct AdaptiveQuizGenerationScreen: View {
    let child: Child
    let quizHistory: [AIQuizResponse]
    let onQuizGenerated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var generatedQuizInfo: GeneratedQuizInfo?
    @State private var analytics: ChildPerformanceAnalytics?
    @State private var showAnalytics = false
    
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
                    Spacer().frame(height: 20)
                    
                    // Child Avatar & Info
                    VStack(spacing: 16) {
                        Image(child.avatarEmoji)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        
                        Text(child.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            ProfileBadge(icon: "calendar", label: "Age", value: "\(child.age)")
                            ProfileBadge(icon: "chart.bar.fill", label: "Level", value: child.level)
                            ProfileBadge(icon: "star.fill", label: "Quizzes", value: "\(quizHistory.count)")
                        }
                    }
                    
                    // AI Smart Analysis Card
                    if let analytics = analytics {
                        AnalyticsCard(analytics: analytics, showDetails: $showAnalytics)
                            .padding(.horizontal, 20)
                    }
                    
                    // AI Magic Card
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.6), .blue.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(2)
                            } else {
                                Text("🧠")
                                    .font(.system(size: 50))
                            }
                        }
                        
                        Text(isGenerating ? "Analyzing learning patterns..." : "Smart Quiz Generator")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text(isGenerating ?
                             "Creating a personalized quiz based on \(child.name)'s performance" :
                             "AI will analyze \(child.name)'s progress and create the perfect next challenge")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Generate Button
                    Button(action: generateAdaptiveQuiz) {
                        HStack(spacing: 12) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "272052")))
                            } else {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                            }
                            Text(isGenerating ? "Analyzing..." : "Generate Smart Quiz")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "272052"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .disabled(isGenerating)
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
        .onAppear {
            analyzePerformance()
        }
        .alert("Quiz Created! 🎉", isPresented: $showSuccess) {
            Button("Start Quiz") {
                onQuizGenerated()
                dismiss()
            }
        } message: {
            if let info = generatedQuizInfo {
                Text("Personalized \(info.subject.capitalized) quiz on \(info.topic) at \(info.difficulty) level with \(info.questionCount) questions")
            } else {
                Text("Smart quiz generated based on learning progress!")
            }
        }
    }
    
    // MARK: - Analyze Performance
    private func analyzePerformance() {
        let performanceAnalytics = AdaptiveQuizService.shared.analyzePerformance(quizzes: quizHistory)
        analytics = performanceAnalytics
    }
    
    // MARK: - Generate Adaptive Quiz
    private func generateAdaptiveQuiz() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else {
                    throw QuizError.noToken
                }
                
                let response = try await AdaptiveQuizService.shared.generateAdaptiveQuiz(
                    parentId: parentId,
                    child: child,
                    quizHistory: quizHistory
                )
                
                await MainActor.run {
                    isGenerating = false
                    generatedQuizInfo = GeneratedQuizInfo(
                        subject: response.subject,
                        topic: response.topic,
                        difficulty: response.difficulty,
                        questionCount: response.questions.count
                    )
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let analytics: ChildPerformanceAnalytics
    @Binding var showDetails: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Analytics")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Based on \(analytics.totalQuizzesTaken) quiz\(analytics.totalQuizzesTaken == 1 ? "" : "zes")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
            }
            
            // Performance Overview
            HStack(spacing: 16) {
                PerformanceIndicator(
                    title: "Average",
                    value: "\(Int(analytics.averageScore))%",
                    color: scoreColor(analytics.averageScore),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                PerformanceIndicator(
                    title: "Trend",
                    value: trendIcon(analytics.performanceTrend),
                    color: trendColor(analytics.performanceTrend),
                    icon: "arrow.up.right"
                )
                
                if analytics.recentImprovement {
                    PerformanceIndicator(
                        title: "Status",
                        value: "🚀",
                        color: .green,
                        icon: "star.fill"
                    )
                }
            }
            
            // Detailed view
            if showDetails {
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    if !analytics.weakSubjects.isEmpty {
                        SubjectSection(
                            title: "Focus Areas",
                            subjects: analytics.weakSubjects,
                            icon: "target",
                            isWeak: true
                        )
                    }
                    
                    if !analytics.strongSubjects.isEmpty {
                        SubjectSection(
                            title: "Strong Subjects",
                            subjects: analytics.strongSubjects,
                            icon: "star.fill",
                            isWeak: false
                        )
                    }
                }
            }
            
            // Next Recommendation
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Next Recommended:")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    Text("\(analytics.recommendedSubject.capitalized) • \(analytics.recommendedTopic.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(analytics.recommendedDifficulty.capitalized)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor(analytics.recommendedDifficulty))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(20)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else { return .orange }
    }
    
    private func trendIcon(_ trend: PerformanceTrend) -> String {
        switch trend {
        case .improving: return "📈"
        case .stable: return "➡️"
        case .declining: return "📉"
        case .insufficient_data: return "❓"
        }
    }
    
    private func trendColor(_ trend: PerformanceTrend) -> Color {
        switch trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        case .insufficient_data: return .gray
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "beginner": return .green.opacity(0.5)
        case "intermediate": return .orange.opacity(0.5)
        case "advanced": return .red.opacity(0.5)
        default: return .gray.opacity(0.5)
        }
    }
}

// MARK: - Performance Indicator
struct PerformanceIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Subject Section
struct SubjectSection: View {
    let title: String
    let subjects: [SubjectPerformance]
    let icon: String
    let isWeak: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isWeak ? .orange : .green)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            ForEach(subjects, id: \.subject) { subject in
                HStack {
                    Text(subject.subject.capitalized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("\(Int(subject.averageScore))%")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Preview
struct AdaptiveQuizGenerationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AdaptiveQuizGenerationScreen(
                child: Child(
                    name: "Emma",
                    age: 8,
                    level: "3",
                    avatarEmoji: "avatar_1",
                    Score: 100,
                    quizzes: [],
                    connectionToken: "test"
                ),
                quizHistory: [],
                onQuizGenerated: {}
            )
        }
    }
}


//
//  ParentQuizListScreen.swift - UPDATED
//  EduKid
//
//  Updated: November 21, 2025
//  Now uses Adaptive AI Quiz Generation
//

import SwiftUI

struct ParentQuizListScreen: View {
    let child: Child
    
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showGenerateQuiz = false
    @State private var quizToDelete: AIQuizResponse?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with child info
            VStack(spacing: 16) {
                // Child Avatar Row
                HStack(spacing: 16) {
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(child.name)'s Quizzes")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Age \(child.age) • Level \(child.level)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // Smart Generate Quiz Button
                Button(action: { showGenerateQuiz = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Generate Smart Quiz")
                                .font(.system(size: 16, weight: .bold))
                            Text("AI-powered adaptive learning")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(Color(hex: "272052"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Quiz Count with Performance Insight
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(quizzes.count) quiz\(quizzes.count == 1 ? "" : "zes") available")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if !quizzes.isEmpty {
                        let completedCount = quizzes.filter { $0.answered > 0 }.count
                        Text("\(completedCount) completed")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer()
                
                if quizzes.count >= 3 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Smart Mode Active")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Content
            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Spacer()
            } else if quizzes.isEmpty {
                Spacer()
                EmptyQuizStateView(onGenerate: { showGenerateQuiz = true })
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(quizzes) { quiz in
                            EnhancedAIQuizCard(
                                quiz: quiz,
                                isRecent: isRecentQuiz(quiz),
                                onDelete: {
                                    quizToDelete = quiz
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showGenerateQuiz) {
            NavigationStack {
                AdaptiveQuizGenerationScreen(
                    child: child,
                    quizHistory: quizzes,
                    onQuizGenerated: loadQuizzes
                )
            }
        }
        .alert("Delete Quiz", isPresented: .constant(quizToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                quizToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let quiz = quizToDelete {
                    deleteQuiz(quiz)
                }
            }
        } message: {
            Text("Are you sure you want to delete this quiz?")
        }
        .onAppear {
            loadQuizzes()
        }
    }
    
    private func isRecentQuiz(_ quiz: AIQuizResponse) -> Bool {
        guard let dateStr = quiz.createdAt else { return false }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateStr) else { return false }
        
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return daysSinceCreation <= 1
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
                    quizzes = fetchedQuizzes.sorted { q1, q2 in
                        guard let date1 = q1.createdAt, let date2 = q2.createdAt else { return false }
                        return date1 > date2
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteQuiz(_ quiz: AIQuizResponse) {
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                try await AIQuizService.shared.deleteQuiz(
                    parentId: parentId,
                    kidId: child.id,
                    quizId: quiz.id
                )
                await MainActor.run {
                    quizzes.removeAll { $0.id == quiz.id }
                    quizToDelete = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    quizToDelete = nil
                }
            }
        }
    }
}

// MARK: - Enhanced AI Quiz Card
struct EnhancedAIQuizCard: View {
    let quiz: AIQuizResponse
    let isRecent: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: subjectIcon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(quiz.topic.capitalized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if isRecent {
                            Text("NEW")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(quiz.subject.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        Label("\(quiz.questions.count)", systemImage: "questionmark.circle")
                        Label(quiz.difficulty.capitalized, systemImage: difficultyIcon)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
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
            
            // Score bar if answered
            if quiz.answered > 0 {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Performance")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("\(quiz.score)/\(quiz.questions.count) correct")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text(scoreLabel)
                                .font(.caption.bold())
                                .foregroundColor(scoreColor)
                            
                            Image(systemName: performanceIcon)
                                .font(.caption)
                                .foregroundColor(scoreColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(scoreColor.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            } else {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        Image(systemName: "hourglass")
                            .font(.caption)
                        Text("Not attempted yet")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.18), Color.white.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
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
    
    var difficultyIcon: String {
        switch quiz.difficulty {
        case "beginner": return "star"
        case "intermediate": return "star.leadinghalf.filled"
        case "advanced": return "star.fill"
        default: return "star"
        }
    }
    
    var scorePercentage: Double {
        guard quiz.questions.count > 0 else { return 0 }
        return Double(quiz.score) / Double(quiz.questions.count) * 100
    }
    
    var scoreLabel: String {
        if scorePercentage >= 80 { return "Excellent!" }
        else if scorePercentage >= 60 { return "Good" }
        else if scorePercentage >= 40 { return "Keep trying" }
        else { return "Needs practice" }
    }
    
    var scoreColor: Color {
        if scorePercentage >= 80 { return .green }
        else if scorePercentage >= 60 { return .yellow }
        else if scorePercentage >= 40 { return .orange }
        else { return .red }
    }
    
    var performanceIcon: String {
        if scorePercentage >= 80 { return "star.fill" }
        else if scorePercentage >= 60 { return "hand.thumbsup.fill" }
        else { return "arrow.up.circle.fill" }
    }
}
