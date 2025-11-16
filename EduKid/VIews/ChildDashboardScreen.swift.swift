//
//  ChildDashboardScreen.swift
//  EduKid
//
//  Updated: November 16, 2025 – Fixed for AI Quiz Integration
//

import SwiftUI

struct ChildDashboardScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var showAddQuiz = false
    @State private var errorMessage: String?
    @State private var parentInfo: ParentInfo?
    
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
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)
                    
                    // Child Info Card
                    ChildInfoCard(child: child)
                        .padding(.horizontal, 20)
                    
                    // Parent Info Card
                    if let parent = parentInfo {
                        ParentInfoCard(parent: parent)
                            .padding(.horizontal, 20)
                    }
                    
                    // Quizzes Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Quizzes")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text("\(quizzes.count) quizzes available")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if quizzes.isEmpty {
                            EmptyQuizzesView()
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(quizzes) { quiz in
                                NavigationLink(destination: QuizTakingScreen(quiz: quiz, child: child)) {
                                    AIQuizCardForChild(quiz: quiz)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
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
            Task {
                await loadQuizzes()
                await loadParentInfo()
            }
        }
    }
    
    // MARK: - Load Quizzes
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
                self.quizzes = fetchedQuizzes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                print("❌ Failed to load quizzes: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Load Parent Info
    private func loadParentInfo() async {
        do {
            let user = try await AuthService.shared.getCurrentUser()
            await MainActor.run {
                self.parentInfo = ParentInfo(
                    name: user.name ?? "Parent",
                    email: user.email ?? ""
                )
            }
        } catch {
            print("Failed to load parent info: \(error.localizedDescription)")
        }
    }
}

// MARK: - Child Info Card
struct ChildInfoCard: View {
    let child: Child
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Image(child.avatarEmoji)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color.white.opacity(0.3))
                .clipShape(Circle())
                .shadow(radius: 8)
            
            // Name
            Text(child.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            // Stats Row
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
                gradient: Gradient(colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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

// MARK: - Parent Info Card
struct ParentInfoCard: View {
    let parent: ParentInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Parent Information")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "person.fill", label: "Name", value: parent.name)
                InfoRow(icon: "envelope.fill", label: "Email", value: parent.email)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(20)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - AI Quiz Card for Child
struct AIQuizCardForChild: View {
    let quiz: AIQuizResponse
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.3))
                    .frame(width: 70, height: 70)
                
                Image(systemName: subjectIcon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }
            
            // Info
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
                gradient: Gradient(colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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

// MARK: - Empty Quizzes View
struct EmptyQuizzesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No quizzes yet")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Your parent will assign quizzes for you")
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

// MARK: - Parent Info Model
struct ParentInfo {
    let name: String
    let email: String
}
