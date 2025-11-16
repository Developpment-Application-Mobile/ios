//
//  AIQuizScreens.swift
//  EduKid
//
//  Created: November 16, 2025
//  AI Quiz Generation & Management
//

import SwiftUI

// MARK: - AI Quiz Generation Screen
struct AIQuizGenerationScreen: View {
    let child: Child
    let onQuizGenerated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var subject = "math"
    @State private var difficulty = "beginner"
    @State private var numberOfQuestions = 10
    @State private var topic = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    let subjects = ["math", "science", "english", "history", "geography"]
    let difficulties = ["beginner", "intermediate", "advanced"]
    let questionCounts = [5, 10, 15, 20]
    
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
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("🤖")
                            .font(.system(size: 60))
                        
                        Text("AI Quiz Generator")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Generate a personalized quiz for \(child.name)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Subject Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subject")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(subjects, id: \.self) { subj in
                                        SubjectButton(
                                            title: subj.capitalized,
                                            icon: subjectIcon(subj),
                                            isSelected: subject == subj,
                                            action: { subject = subj }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Topic Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Topic")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("e.g., fractions, solar system", text: $topic)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        // Difficulty Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(difficulties, id: \.self) { diff in
                                    DifficultyButton(
                                        title: diff.capitalized,
                                        isSelected: difficulty == diff,
                                        action: { difficulty = diff }
                                    )
                                }
                            }
                        }
                        
                        // Number of Questions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Number of Questions")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(questionCounts, id: \.self) { count in
                                    QuestionCountButton(
                                        count: count,
                                        isSelected: numberOfQuestions == count,
                                        action: { numberOfQuestions = count }
                                    )
                                }
                            }
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                        }
                        
                        // Generate Button
                        Button(action: generateQuiz) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Quiz")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.8),
                                        Color(red: 0.6, green: 0.3, blue: 0.9)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isGenerating || topic.isEmpty)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                onQuizGenerated()
                dismiss()
            }
        } message: {
            Text("Quiz generated successfully! \(numberOfQuestions) questions created.")
        }
    }
    
    private func subjectIcon(_ subject: String) -> String {
        switch subject {
        case "math": return "function"
        case "science": return "flask.fill"
        case "english": return "book.fill"
        case "history": return "clock.fill"
        case "geography": return "globe"
        default: return "star.fill"
        }
    }
    
    private func generateQuiz() {
        guard !topic.isEmpty else {
            errorMessage = "Please enter a topic"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else {
                    throw QuizError.noToken
                }
                
                _ = try await AIQuizService.shared.generateAIQuiz(
                    parentId: parentId,
                    kidId: child.id,
                    subject: subject,
                    difficulty: difficulty,
                    nbrQuestions: numberOfQuestions,
                    topic: topic
                )
                
                await MainActor.run {
                    isGenerating = false
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

// MARK: - Subject Button
struct SubjectButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(width: 100, height: 80)
            .background(
                isSelected ?
                Color.white.opacity(0.3) :
                Color.white.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Difficulty Button
struct DifficultyButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected ?
                    Color.white.opacity(0.3) :
                    Color.white.opacity(0.1)
                )
                .cornerRadius(10)
        }
    }
}

// MARK: - Question Count Button
struct QuestionCountButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected ?
                    Color.white.opacity(0.3) :
                    Color.white.opacity(0.1)
                )
                .cornerRadius(10)
        }
    }
}

// MARK: - Quiz List Screen for Parent (Fixed Layout)
struct ParentQuizListScreen: View {
    let child: Child
    
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showGenerateQuiz = false
    @State private var quizToDelete: AIQuizResponse?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and + button (no back button)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(child.name)'s Quizzes")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(quizzes.count) AI-generated quizzes")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Generate Quiz Button
                Button(action: { showGenerateQuiz = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Content
            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Spacer()
            } else if quizzes.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Text("🤖")
                        .font(.system(size: 60))
                    Text("No quizzes yet")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Generate your first AI quiz")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(quizzes) { quiz in
                            AIQuizCard(quiz: quiz, onDelete: {
                                quizToDelete = quiz
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showGenerateQuiz) {
            NavigationStack {
                AIQuizGenerationScreen(child: child, onQuizGenerated: loadQuizzes)
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

// MARK: - AI Quiz Card
struct AIQuizCard: View {
    let quiz: AIQuizResponse
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: subjectIcon)
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(quiz.topic.capitalized)
                    .font(.headline)
                    .foregroundColor(.white)
                
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
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
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
    
    var difficultyIcon: String {
        switch quiz.difficulty {
        case "beginner": return "star"
        case "intermediate": return "star.leadinghalf.filled"
        case "advanced": return "star.fill"
        default: return "star"
        }
    }
}
