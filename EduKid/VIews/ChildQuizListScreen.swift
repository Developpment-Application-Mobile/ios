//
//  ChildQuizTaking.swift - UPDATED
//  EduKid
//
//  Updated: November 22, 2025
//  - Fixed navigation to dashboard after quiz completion
//  - Auto-generates retry quiz based on wrong answers
//  - Added onQuizCompleted callback for refresh
//

import SwiftUI

// MARK: - Quiz Taking Screen
struct QuizTakingScreen: View {
    let quiz: AIQuizResponse
    let child: Child
    var onQuizCompleted: (() -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [Int] = []
    @State private var showResult = false
    @State private var quizResult: QuizResultResponse?
    @State private var isSubmitting = false
    @State private var retryQuizGenerated = false
    
    var currentQuestion: AIQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(quiz.questions.count)
    }
    
    init(quiz: AIQuizResponse, child: Child, onQuizCompleted: (() -> Void)? = nil) {
        self.quiz = quiz
        self.child = child
        self.onQuizCompleted = onQuizCompleted
        _selectedAnswers = State(initialValue: Array(repeating: -1, count: quiz.questions.count))
    }
    
    var body: some View {
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
                                .fill(Color.blue)
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
                        Text(currentQuestion.questionText)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                                SimpleOptionButton(
                                    text: option,
                                    index: index,
                                    isSelected: selectedAnswers[currentQuestionIndex] == index,
                                    action: { selectedAnswers[currentQuestionIndex] = index }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
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
                                    Text(currentQuestionIndex < quiz.questions.count - 1 ? "Next" : "Finish")
                                    Image(systemName: currentQuestionIndex < quiz.questions.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                                }
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
                            .disabled(selectedAnswers[currentQuestionIndex] == -1 && currentQuestionIndex == quiz.questions.count - 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            
            if isSubmitting {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Calculating your score...")
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(red: 0.153, green: 0.125, blue: 0.322))
                .cornerRadius(16)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showResult) {
            if let result = quizResult {
                EnhancedQuizResultScreen(
                    result: result,
                    quiz: quiz,
                    child: child,
                    retryQuizGenerated: retryQuizGenerated,
                    onDismiss: {
                        showResult = false
                        onQuizCompleted?()
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 { currentQuestionIndex -= 1 }
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
                guard let parentId = AuthService.shared.getParentId() else {
                    await MainActor.run { isSubmitting = false }
                    return
                }
                
                let result = try await AIQuizService.shared.submitQuizAnswer(
                    parentId: parentId,
                    kidId: child.id,
                    quizId: quiz.id,
                    answers: selectedAnswers
                )
                
                // Auto-generate retry quiz if there are wrong answers
                var generated = false
                if result.correctAnswers < result.totalQuestions {
                    generated = await generateRetryQuizInBackground()
                }
                
                await MainActor.run {
                    retryQuizGenerated = generated
                    isSubmitting = false
                    quizResult = result
                    showResult = true
                }
            } catch {
                let localResult = calculateLocalResults()
                
                var generated = false
                if localResult.correctAnswers < localResult.totalQuestions {
                    generated = await generateRetryQuizInBackground()
                }
                
                await MainActor.run {
                    retryQuizGenerated = generated
                    isSubmitting = false
                    quizResult = localResult
                    showResult = true
                }
            }
        }
    }
    
    private func generateRetryQuizInBackground() async -> Bool {
        do {
            guard let parentId = AuthService.shared.getParentId() else { return false }
            
            print("🔄 Auto-generating retry quiz based on wrong answers...")
            _ = try await AIQuizService.shared.generateRetryQuiz(
                parentId: parentId,
                kidId: child.id
            )
            print("✅ Retry quiz auto-generated successfully!")
            return true
        } catch {
            print("⚠️ Could not auto-generate retry quiz: \(error.localizedDescription)")
            return false
        }
    }
    
    private func calculateLocalResults() -> QuizResultResponse {
        var correctCount = 0
        var answerDetails: [AnswerDetail] = []
        
        for (index, question) in quiz.questions.enumerated() {
            let userAnswer = selectedAnswers[index]
            let isCorrect = userAnswer == question.correctAnswerIndex
            if isCorrect && userAnswer != -1 { correctCount += 1 }
            
            answerDetails.append(AnswerDetail(
                questionId: question.id,
                isCorrect: isCorrect,
                userAnswer: userAnswer,
                correctAnswer: question.correctAnswerIndex
            ))
        }
        
        let totalQuestions = quiz.questions.count
        let score = totalQuestions > 0 ? Int(Double(correctCount) / Double(totalQuestions) * 100) : 0
        
        return QuizResultResponse(
            score: score,
            totalQuestions: totalQuestions,
            percentage: Double(score),
            correctAnswers: correctCount,
            answers: answerDetails
        )
    }
}

// MARK: - Enhanced Quiz Result Screen
struct EnhancedQuizResultScreen: View {
    let result: QuizResultResponse
    let quiz: AIQuizResponse
    let child: Child
    var retryQuizGenerated: Bool = false
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showIncorrectAnswers = false
    @State private var isGenerating = false
    
    var incorrectAnswers: [(question: AIQuestion, detail: AnswerDetail)] {
        result.answers.compactMap { answer -> (question: AIQuestion, detail: AnswerDetail)? in
            guard !answer.isCorrect else { return nil }
            guard let question = quiz.questions.first(where: { $0.id == answer.questionId }) else { return nil }
            return (question, answer)
        }
    }
    
    var body: some View {
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
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)
                    
                    Text(result.score >= 80 ? "🎉" : result.score >= 60 ? "👍" : "💪")
                        .font(.system(size: 100))
                    
                    Text(result.score >= 80 ? "Excellent!" : result.score >= 60 ? "Good Job!" : "Keep Practicing!")
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
                                result.score >= 80 ? Color.green :
                                result.score >= 60 ? Color.orange : Color.red,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: result.percentage)
                        
                        VStack(spacing: 8) {
                            Text("\(result.score)%")
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
                        ResultStatRow(label: "Correct", value: "\(result.correctAnswers) of \(result.totalQuestions)")
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                    
                    // Retry Quiz Generated Notice
                    if retryQuizGenerated && !incorrectAnswers.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Practice Quiz Created!")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("A new quiz was added to help you practice the questions you missed.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(16)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                    
                    // Review Wrong Answers (only if there are incorrect answers)
                    if !incorrectAnswers.isEmpty {
                        Button(action: { showIncorrectAnswers.toggle() }) {
                            HStack {
                                Image(systemName: showIncorrectAnswers ? "chevron.up" : "chevron.down")
                                Text(showIncorrectAnswers ? "Hide Answers" : "Review Wrong Answers (\(incorrectAnswers.count))")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.orange.opacity(0.7))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                        
                        if showIncorrectAnswers {
                            VStack(spacing: 16) {
                                ForEach(Array(incorrectAnswers.enumerated()), id: \.offset) { index, item in
                                    IncorrectAnswerCard(
                                        questionNumber: index + 1,
                                        question: item.question,
                                        userAnswer: item.detail.userAnswer,
                                        correctAnswer: item.detail.correctAnswer
                                    )
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    
                    // Back to Dashboard Button
                    Button(action: {
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Back to Dashboard")
                        }
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
            
            if isGenerating {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Creating practice quiz...")
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(red: 0.153, green: 0.125, blue: 0.322))
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Simple Option Button
struct SimpleOptionButton: View {
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
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.3))
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
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Result Stat Row
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

// MARK: - Incorrect Answer Card
struct IncorrectAnswerCard: View {
    let questionNumber: Int
    let question: AIQuestion
    let userAnswer: Int
    let correctAnswer: Int
    
    let letters = ["A", "B", "C", "D"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(questionNumber).")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(question.questionText)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.white.opacity(0.3))
            
            if userAnswer >= 0 && userAnswer < question.options.count {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Your Answer:")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text(letters[userAnswer])
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.red.opacity(0.3))
                            .clipShape(Circle())
                        Text(question.options[userAnswer])
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Correct Answer:")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                HStack {
                    Text(letters[correctAnswer])
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.green.opacity(0.3))
                        .clipShape(Circle())
                    Text(question.options[correctAnswer])
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
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
