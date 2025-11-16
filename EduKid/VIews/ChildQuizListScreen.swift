//
//  ChildQuizTaking.swift
//  EduKid
//
//  Created: November 16, 2025
//  Child interface for taking AI-generated quizzes
//

import SwiftUI

// MARK: - Child Quiz List
struct ChildQuizListScreen: View {
    let child: Child
    
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @EnvironmentObject var authVM: AuthViewModel
    
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
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("📚")
                        .font(.system(size: 60))
                    
                    Text("My Quizzes")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(quizzes.count) quizzes available")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if quizzes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("🎯")
                            .font(.system(size: 60))
                        Text("No quizzes yet")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Ask your parent to create quizzes for you")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(quizzes) { quiz in
                                NavigationLink(destination: QuizTakingScreen(quiz: quiz, child: child)) {
                                    ChildQuizCard(quiz: quiz)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Child Quiz Card
struct ChildQuizCard: View {
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
        switch quiz.subject {
        case "math": return "function"
        case "science": return "flask.fill"
        case "english": return "book.fill"
        case "history": return "clock.fill"
        case "geography": return "globe"
        default: return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch quiz.subject {
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

// MARK: - Quiz Taking Screen
struct QuizTakingScreen: View {
    let quiz: AIQuizResponse
    let child: Child
    
    @Environment(\.dismiss) var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var showResult = false
    @State private var quizResult: QuizResultResponse?
    @State private var isSubmitting = false
    
    var currentQuestion: AIQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(quiz.questions.count)
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
            
            VStack(spacing: 0) {
                // Progress Bar
                VStack(spacing: 12) {
                    HStack {
                        Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green)
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Question
                        Text(currentQuestion.questionText)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Options
                        VStack(spacing: 16) {
                            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                                OptionButton(
                                    text: option,
                                    index: index,
                                    isSelected: selectedAnswers[currentQuestion.id] == index,
                                    action: {
                                        selectedAnswers[currentQuestion.id] = index
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            if currentQuestionIndex > 0 {
                                Button(action: previousQuestion) {
                                    HStack {
                                        Image(systemName: "arrow.left")
                                        Text("Previous")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(16)
                                }
                            }
                            
                            Button(action: nextQuestion) {
                                HStack {
                                    Text(currentQuestionIndex < quiz.questions.count - 1 ? "Next" : "Submit")
                                    if currentQuestionIndex == quiz.questions.count - 1 {
                                        Image(systemName: "checkmark.circle.fill")
                                    } else {
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .disabled(selectedAnswers[currentQuestion.id] == nil)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            
            if isSubmitting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Submitting answers...")
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(hex: "272052"))
                .cornerRadius(16)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showResult) {
            if let result = quizResult {
                QuizResultScreen(result: result, quiz: quiz, child: child)
            }
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            submitQuiz()
        }
    }
    
    private func submitQuiz() {
        isSubmitting = true
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                
                let result = try await AIQuizService.shared.submitQuizAnswer(
                    parentId: parentId,
                    kidId: child.id,
                    quizId: quiz.id,
                    answers: selectedAnswers
                )
                
                await MainActor.run {
                    isSubmitting = false
                    quizResult = result
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("Error submitting quiz: \(error)")
                }
            }
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    
    let letters = ["A", "B", "C", "D"]
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color.white.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Text(letters[index])
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(
                isSelected ?
                Color.green.opacity(0.2) :
                Color.white.opacity(0.15)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Quiz Result Screen
struct QuizResultScreen: View {
    let result: QuizResultResponse
    let quiz: AIQuizResponse
    let child: Child
    
    @Environment(\.dismiss) var dismiss
    
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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Emoji based on score
                Text(result.percentage >= 80 ? "🎉" : result.percentage >= 60 ? "👍" : "💪")
                    .font(.system(size: 100))
                
                Text(result.percentage >= 80 ? "Excellent!" : result.percentage >= 60 ? "Good Job!" : "Keep Practicing!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: result.percentage / 100)
                        .stroke(
                            result.percentage >= 80 ? Color.green :
                            result.percentage >= 60 ? Color.orange : Color.red,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(result.percentage))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(result.correctAnswers)/\(result.totalQuestions)")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Stats
                VStack(spacing: 16) {
                    StatRow(label: "Topic", value: quiz.topic.capitalized)
                    StatRow(label: "Subject", value: quiz.subject.capitalized)
                    StatRow(label: "Difficulty", value: quiz.difficulty.capitalized)
                }
                .padding(24)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Done Button
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
