//
//  ChildDashboardScreen.swift - UPDATED
//  EduKid
//
//  Updated: November 22, 2025
//  - Added quiz result display
//  - Auto-refresh after quiz completion
//  - Shows completed vs pending quizzes
//

import SwiftUI

struct ChildDashboardScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    var pendingQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered == 0 }
    }
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered > 0 }
    }
    
    var averageScore: Int {
        guard !completedQuizzes.isEmpty else { return 0 }
        let total = completedQuizzes.reduce(0) { $0 + $1.score }
        return total / completedQuizzes.count
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
                        
                        // Child Info Card
                        ChildInfoCard(child: child)
                            .padding(.horizontal, 20)
                        
                        // Stats Row
                        HStack(spacing: 12) {
                            QuickStatCard(
                                icon: "checkmark.circle.fill",
                                value: "\(completedQuizzes.count)",
                                label: "Completed",
                                color: .green
                            )
                            QuickStatCard(
                                icon: "hourglass",
                                value: "\(pendingQuizzes.count)",
                                label: "Pending",
                                color: .orange
                            )
                            QuickStatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                value: "\(averageScore)%",
                                label: "Average",
                                color: .blue
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Tab Selector
                        HStack(spacing: 0) {
                            TabButton(title: "Pending (\(pendingQuizzes.count))", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            TabButton(title: "Completed (\(completedQuizzes.count))", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Quizzes Section
                        VStack(alignment: .leading, spacing: 16) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if selectedTab == 0 {
                                // Pending Quizzes
                                if pendingQuizzes.isEmpty {
                                    EmptyStateView(
                                        icon: "checkmark.seal.fill",
                                        title: "All caught up!",
                                        message: "No pending quizzes. Great job!"
                                    )
                                } else {
                                    ForEach(pendingQuizzes) { quiz in
                                        NavigationLink(destination:
                                            QuizTakingScreen(
                                                quiz: quiz,
                                                child: child,
                                                onQuizCompleted: {
                                                    Task { await loadQuizzes() }
                                                }
                                            )
                                        ) {
                                            AIQuizCardForChild(quiz: quiz, showScore: false)
                                        }
                                    }
                                }
                            } else {
                                // Completed Quizzes
                                if completedQuizzes.isEmpty {
                                    EmptyStateView(
                                        icon: "book.closed",
                                        title: "No completed quizzes",
                                        message: "Complete a quiz to see your results here"
                                    )
                                } else {
                                    ForEach(completedQuizzes) { quiz in
                                        CompletedQuizCard(quiz: quiz)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout Button
                        Button(action: { authVM.signOutChild() }) {
                            HStack {
                                Image(systemName: "arrow.uturn.left.circle.fill")
                                    .font(.title3)
                                Text("Logout")
                                    .font(.title3.bold())
                            }
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
            }
            .navigationBarHidden(true)
            .onAppear {
                Task { await loadQuizzes() }
            }
            .refreshable {
                await loadQuizzes()
            }
        }
    }
    
    private func loadQuizzes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let parentId = AuthService.shared.getParentId() else {
                throw QuizError.noToken
            }
            
            let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(
                parentId: parentId,
                kidId: child.id
            )
            
            await MainActor.run {
                self.quizzes = fetchedQuizzes.sorted { q1, q2 in
                    guard let d1 = q1.createdAt, let d2 = q2.createdAt else { return false }
                    return d1 > d2
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
                .padding(.vertical, 12)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
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

// MARK: - AI Quiz Card for Child
struct AIQuizCardForChild: View {
    let quiz: AIQuizResponse
    var showScore: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.3))
                    .frame(width: 70, height: 70)
                Image(systemName: subjectIcon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(quiz.topic.capitalized)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(quiz.subject.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 12) {
                    Label("\(quiz.questions.count) questions", systemImage: "questionmark.circle.fill")
                    Label(quiz.difficulty.capitalized, systemImage: difficultyIcon)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
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
}

// MARK: - Completed Quiz Card
struct CompletedQuizCard: View {
    let quiz: AIQuizResponse
    
    var scoreColor: Color {
        if quiz.score >= 80 { return .green }
        else if quiz.score >= 60 { return .orange }
        else { return .red }
    }
    
    var scoreEmoji: String {
        if quiz.score >= 80 { return "🎉" }
        else if quiz.score >= 60 { return "👍" }
        else { return "💪" }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: Double(quiz.score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(scoreEmoji)
                        .font(.title3)
                    Text("\(quiz.score)%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(quiz.topic.capitalized)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(quiz.subject.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 12) {
                    Label("\(quiz.answered)/\(quiz.questions.count)", systemImage: "checkmark.circle")
                    Label(quiz.difficulty.capitalized, systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    scoreColor.opacity(0.2),
                    Color.white.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(scoreColor.opacity(0.3), lineWidth: 1)
        )
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
