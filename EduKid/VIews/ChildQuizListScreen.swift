//
//  ChildQuizTaking.swift - Enhanced Version
//  EduKid
//
//  Created: November 16, 2025
//  Child interface for taking AI-generated quizzes with instant feedback
//

import SwiftUI

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
    @State private var showFeedback = false
    @State private var isCorrect = false
    
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
                                OptionButtonWithFeedback(
                                    text: option,
                                    index: index,
                                    isSelected: selectedAnswers[currentQuestion.id] == index,
                                    showFeedback: showFeedback,
                                    isCorrectAnswer: index == currentQuestion.correctAnswerIndex,
                                    action: {
                                        if !showFeedback {
                                            selectAnswer(index)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Explanation (shown after answering)
                        if showFeedback, let explanation = currentQuestion.explanation {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("Explanation")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                Text(explanation)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            if currentQuestionIndex > 0 && !showFeedback {
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
                            
                            if showFeedback {
                                Button(action: nextQuestion) {
                                    HStack {
                                        Text(currentQuestionIndex < quiz.questions.count - 1 ? "Next Question" : "Finish")
                                        Image(systemName: currentQuestionIndex < quiz.questions.count - 1 ? "arrow.right" : "checkmark.circle.fill")
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
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            
            // Feedback Overlay
            if showFeedback {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text(isCorrect ? "Correct! 🎉" : "Not quite! 💡")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(isCorrect ? Color.green : Color.red)
                    .cornerRadius(16)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showFeedback)
            }
            
            if isSubmitting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Calculating your score...")
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(hex: "272052"))
                .cornerRadius(16)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showResult) {
            if let result = quizResult {
                QuizResultScreen(result: result, quiz: quiz, child: child)
            }
        }
    }
    
    private func selectAnswer(_ index: Int) {
        selectedAnswers[currentQuestion.id] = index
        isCorrect = (index == currentQuestion.correctAnswerIndex)
        
        withAnimation {
            showFeedback = true
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            showFeedback = false
        }
    }
    
    private func nextQuestion() {
        showFeedback = false
        
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

// MARK: - Option Button With Feedback
struct OptionButtonWithFeedback: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let showFeedback: Bool
    let isCorrectAnswer: Bool
    let action: () -> Void
    
    let letters = ["A", "B", "C", "D"]
    
    var backgroundColor: Color {
        if showFeedback {
            if isCorrectAnswer {
                return Color.green.opacity(0.3)
            } else if isSelected {
                return Color.red.opacity(0.3)
            }
        } else if isSelected {
            return Color.blue.opacity(0.3)
        }
        return Color.white.opacity(0.15)
    }
    
    var borderColor: Color {
        if showFeedback {
            if isCorrectAnswer {
                return Color.green
            } else if isSelected {
                return Color.red
            }
        } else if isSelected {
            return Color.blue
        }
        return Color.clear
    }
    
    var iconName: String? {
        if showFeedback {
            if isCorrectAnswer {
                return "checkmark.circle.fill"
            } else if isSelected {
                return "xmark.circle.fill"
            }
        }
        return nil
    }
    
    var iconColor: Color {
        if isCorrectAnswer {
            return .green
        } else {
            return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(showFeedback && isCorrectAnswer ? Color.green :
                              showFeedback && isSelected ? Color.red :
                              isSelected ? Color.blue :
                              Color.white.opacity(0.3))
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
                
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .disabled(showFeedback)
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
                    
                    VStack(spacing: 8) {
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
                    ResultStatRow(label: "Topic", value: quiz.topic.capitalized)
                    ResultStatRow(label: "Subject", value: quiz.subject.capitalized)
                    ResultStatRow(label: "Difficulty", value: quiz.difficulty.capitalized)
                    ResultStatRow(label: "Correct Answers", value: "\(result.correctAnswers) out of \(result.totalQuestions)")
                }
                .padding(24)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Done Button
                Button(action: {
                    dismiss()
                    dismiss() // Dismiss twice to go back to dashboard
                }) {
                    Text("Back to Dashboard")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct ResultStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}
