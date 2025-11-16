//
//  ChildDetailScreen.swift - Enhanced with Quiz Results
//  EduKid
//
//  Updated: November 16, 2025
//

import Foundation
import SwiftUI

struct ChildDetailScreen: View {
    let child: Child
    
    @State private var selectedTab = 0
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @EnvironmentObject var authVM: AuthViewModel
    
    let tabs = ["Overview", "Quiz Results"]
    
    var onBackClick: () -> Void = {}
    var onAssignQuizClick: () -> Void = {}
    var onGenerateQRClick: () -> Void = {}
    var onEditClick: () -> Void = {}
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.answered > 0 }
    }
    
    var averageScore: Int {
        guard !completedQuizzes.isEmpty else { return 0 }
        let total = completedQuizzes.reduce(0) { $0 + $1.score }
        return total / completedQuizzes.count
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
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onAssignQuizClick) {
                        Text("📝 Assign Quiz")
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
                
                // Tabs
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: { selectedTab = index }) {
                            Text(tabs[index])
                                .font(.system(size: 15, weight: selectedTab == index ? .bold : .regular))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedTab == index ?
                                    Color.white.opacity(0.2) : Color.clear
                                )
                        }
                    }
                }
                .background(Color.white.opacity(0.1))
                
                Spacer().frame(height: 16)
                
                // Tab content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    if selectedTab == 0 {
                        OverviewTab(
                            child: child,
                            completedQuizzes: completedQuizzes.count,
                            totalQuizzes: quizzes.count,
                            averageScore: averageScore
                        )
                    } else {
                        QuizResultsTab(quizzes: completedQuizzes)
                    }
                }
            }
        }
        .onAppear {
            loadQuizzes()
        }
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
                    quizzes = fetchedQuizzes
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Failed to load quizzes: \(error)")
                }
            }
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let child: Child
    let completedQuizzes: Int
    let totalQuizzes: Int
    let averageScore: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Stats cards
                HStack(spacing: 12) {
                    StatsCardDetail(
                        title: "Completed",
                        value: "\(completedQuizzes)",
                        subtitle: "quizzes",
                        icon: "✅"
                    )
                    
                    StatsCardDetail(
                        title: "Average",
                        value: "\(averageScore)%",
                        subtitle: "score",
                        icon: "⭐"
                    )
                }
                .padding(.horizontal, 20)
                
                // Overall Progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Overall Progress")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(completedQuizzes) of \(totalQuizzes) quizzes")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        
                        Spacer()
                        
                        Text("\(totalQuizzes == 0 ? 0 : (completedQuizzes * 100 / totalQuizzes))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(red: 0.88, green: 0.88, blue: 0.88))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(red: 0.686, green: 0.494, blue: 0.906))
                                .frame(
                                    width: totalQuizzes == 0 ? 0 : geometry.size.width * CGFloat(completedQuizzes) / CGFloat(totalQuizzes),
                                    height: 10
                                )
                        }
                    }
                    .frame(height: 10)
                }
                .padding(16)
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Stats Card Detail
struct StatsCardDetail: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 32))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
    }
}

// MARK: - Quiz Results Tab
struct QuizResultsTab: View {
    let quizzes: [AIQuizResponse]
    
    var body: some View {
        if quizzes.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                
                Text("📊")
                    .font(.system(size: 48))
                
                Text("No quiz results yet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Complete some quizzes to see results here")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(quizzes) { quiz in
                        AIQuizResultCard(quiz: quiz)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
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
                    Text(quiz.topic.capitalized)
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
