//
//  Quiz Management Views
//  EduKid
//
//  Created: November 15, 2025
//  Fixed: November 15, 2025 - Type consistency
//

import SwiftUI

// MARK: - Add Quiz View
struct AddQuizView: View {
    let child: Child
    let onSave: (quiz) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedType: quizType = .general
    @State private var description = ""
    @State private var duration = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Information") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $selectedType) {
                        Text("Math").tag(quizType.math)
                        Text("Science").tag(quizType.science)
                        Text("English").tag(quizType.english)
                        Text("History").tag(quizType.history)
                        Text("Geography").tag(quizType.geography)
                        Text("General").tag(quizType.general)
                    }
                    
                    TextField("Description (optional)", text: $description)
                    TextField("Duration in minutes (optional)", text: $duration)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add New Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let newQuiz = quiz(
                        title: title,
                        category: selectedType.rawValue,
                        description: description.isEmpty ? nil : description,
                        duration: Int(duration),
                        questions: [],
                        type: selectedType
                    )
                    onSave(newQuiz)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Quiz Detail View
struct QuizDetailView: View {
    let quiz: quiz
    let child: Child
    let onUpdate: () async -> Void
    
    @State private var localQuiz: quiz
    @State private var showAddQuestion = false
    @State private var showEditQuiz = false
    @State private var showDeleteAlert = false
    @State private var questionToDelete: Question?
    @State private var questionToEdit: Question?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    init(quiz: quiz, child: Child, onUpdate: @escaping () async -> Void) {
        self.quiz = quiz
        self.child = child
        self.onUpdate = onUpdate
        _localQuiz = State(initialValue: quiz)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.153, green: 0.125, blue: 0.322)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quiz Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localQuiz.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(localQuiz.category)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let description = localQuiz.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack(spacing: 16) {
                            Label("\(localQuiz.questions.count) questions", systemImage: "questionmark.circle.fill")
                            
                            if let duration = localQuiz.duration {
                                Label("\(duration) min", systemImage: "clock.fill")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: { showEditQuiz = true }) {
                            Label("Edit Quiz", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                    }
                    
                    // Questions Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Questions")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { showAddQuestion = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if localQuiz.questions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No questions yet")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Tap + to add questions")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            ForEach(Array(localQuiz.questions.enumerated()), id: \.element.id) { index, question in
                                QuestionCardView(
                                    question: question,
                                    index: index + 1,
                                    onEdit: {
                                        questionToEdit = question
                                    },
                                    onDelete: {
                                        questionToDelete = question
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddQuestion) {
            AddQuestionView(quiz: localQuiz, child: child) { newQuestion in
                Task {
                    await addQuestion(newQuestion)
                }
            }
        }
        .sheet(item: $questionToEdit) { question in
            EditQuestionView(question: question, quiz: localQuiz, child: child) { updatedQuestion in
                Task {
                    await updateQuestion(updatedQuestion)
                }
            }
        }
        .sheet(isPresented: $showEditQuiz) {
            EditQuizView(quiz: localQuiz, child: child) { updatedQuiz in
                Task {
                    await updateQuiz(updatedQuiz)
                }
            }
        }
        .alert("Delete Question", isPresented: .constant(questionToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                questionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let question = questionToDelete {
                    Task {
                        await deleteQuestion(question)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this question?")
        }
        .alert("Delete Quiz", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteQuiz()
                }
            }
        } message: {
            Text("Are you sure you want to delete this quiz? This action cannot be undone.")
        }
    }
    
    // MARK: - Question Management
    private func addQuestion(_ question: Question) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let addedQuestion = try await QuizService.shared.addQuestion(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id,
                quizId: localQuiz.id ?? "",
                question: question
            )
            
            await MainActor.run {
                localQuiz.questions.append(addedQuestion)
                isLoading = false
                showAddQuestion = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func updateQuestion(_ question: Question) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedQuestion = try await QuizService.shared.updateQuestion(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id,
                quizId: localQuiz.id ?? "",
                questionId: question.id ?? "",
                question: question
            )
            
            await MainActor.run {
                if let index = localQuiz.questions.firstIndex(where: { $0.id == question.id }) {
                    localQuiz.questions[index] = updatedQuestion
                }
                isLoading = false
                questionToEdit = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func deleteQuestion(_ question: Question) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await QuizService.shared.deleteQuestion(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id,
                quizId: localQuiz.id ?? "",
                questionId: question.id ?? ""
            )
            
            await MainActor.run {
                localQuiz.questions.removeAll { $0.id == question.id }
                isLoading = false
                questionToDelete = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                questionToDelete = nil
            }
        }
    }
    
    private func updateQuiz(_ quizData: quiz) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedQuiz = try await QuizService.shared.updateQuiz(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id,
                quizId: localQuiz.id ?? "",
                quiz: quizData
            )
            
            await MainActor.run {
                localQuiz = updatedQuiz
                isLoading = false
                showEditQuiz = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func deleteQuiz() async {
        isLoading = true
        
        do {
            try await QuizService.shared.deleteQuiz(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id,
                quizId: localQuiz.id ?? ""
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
            
            await onUpdate()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Question Card View
struct QuestionCardView: View {
    let question: Question
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Number and Text
            HStack(alignment: .top) {
                Text("\(index).")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 30, alignment: .leading)
                
                Text(question.questionText)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Options
            VStack(alignment: .leading, spacing: 8) {
                ForEach(question.options, id: \.self) { option in
                    HStack {
                        Image(systemName: option == question.correctAnswer ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(option == question.correctAnswer ? .green : .white.opacity(0.5))
                        
                        Text(option)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(.leading, 30)
            
            // Explanation
            if let explanation = question.explanation, !explanation.isEmpty {
                Text("💡 \(explanation)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, 30)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
