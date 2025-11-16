//
//  QuestionEditViews.swift
//  EduKid
//
//  Updated: November 15, 2025 – Fixed toolbar and type issues
//

import SwiftUI

// MARK: - Add Question View
struct AddQuestionView: View {
    let quiz: quiz
    let child: Child
    let onSave: (Question) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var questionText = ""
    @State private var options = ["", "", "", ""]
    @State private var correctAnswerIndex = 0
    @State private var explanation = ""
    
    var isValid: Bool {
        !questionText.isEmpty &&
        options.allSatisfy { !$0.isEmpty } &&
        correctAnswerIndex < options.count
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextEditor(text: $questionText)
                        .frame(minHeight: 80)
                }
                
                Section("Options") {
                    ForEach(0..<4, id: \.self) { index in
                        HStack {
                            TextField("Option \(index + 1)", text: $options[index])
                            
                            if correctAnswerIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button(action: {
                                    correctAnswerIndex = index
                                }) {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                Section("Explanation (Optional)") {
                    TextEditor(text: $explanation)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Add Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let question = Question(
                            questionText: questionText,
                            options: options,
                            correctAnswer: options[correctAnswerIndex],
                            explanation: explanation.isEmpty ? nil : explanation
                        )
                        onSave(question)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Edit Question View
struct EditQuestionView: View {
    let question: Question
    let quiz: quiz
    let child: Child
    let onSave: (Question) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var questionText: String
    @State private var options: [String]
    @State private var correctAnswerIndex: Int
    @State private var explanation: String
    
    init(question: Question, quiz: quiz, child: Child, onSave: @escaping (Question) -> Void) {
        self.question = question
        self.quiz = quiz
        self.child = child
        self.onSave = onSave
        
        _questionText = State(initialValue: question.questionText)
        _options = State(initialValue: question.options)
        _correctAnswerIndex = State(initialValue: question.options.firstIndex(of: question.correctAnswer) ?? 0)
        _explanation = State(initialValue: question.explanation ?? "")
    }
    
    var isValid: Bool {
        !questionText.isEmpty &&
        options.allSatisfy { !$0.isEmpty } &&
        correctAnswerIndex < options.count
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextEditor(text: $questionText)
                        .frame(minHeight: 80)
                }
                
                Section("Options") {
                    ForEach(0..<options.count, id: \.self) { index in
                        HStack {
                            TextField("Option \(index + 1)", text: $options[index])
                            
                            if correctAnswerIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button(action: {
                                    correctAnswerIndex = index
                                }) {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                Section("Explanation (Optional)") {
                    TextEditor(text: $explanation)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Edit Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newQuestion = Question(
                            id: question.id,
                            questionText: questionText,
                            options: options,
                            correctAnswer: options[correctAnswerIndex],
                            explanation: explanation.isEmpty ? nil : explanation
                        )
                        
                        onSave(newQuestion)
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Edit Quiz View
struct EditQuizView: View {
    let quiz: quiz
    let child: Child
    let onSave: (quiz) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var selectedType: quizType
    @State private var description: String
    @State private var duration: String
    
    init(quiz: quiz, child: Child, onSave: @escaping (quiz) -> Void) {
        self.quiz = quiz
        self.child = child
        self.onSave = onSave
        
        _title = State(initialValue: quiz.title)
        _selectedType = State(initialValue: quiz.type ?? .general)
        _description = State(initialValue: quiz.description ?? "")
        _duration = State(initialValue: quiz.duration != nil ? String(quiz.duration!) : "")
    }
    
    var isValid: Bool {
        !title.isEmpty
    }
    
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
            .navigationTitle("Edit Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    // Create updated quiz using EduKid.quiz explicitly
                    let updatedQuiz = EduKid.quiz(
                        id: self.quiz.id,
                        title: title,
                        category: selectedType.rawValue,
                        description: description.isEmpty ? nil : description,
                        duration: Int(duration),
                        questions: self.quiz.questions,
                        completionPercentage: self.quiz.completionPercentage,
                        type: selectedType
                    )
                    onSave(updatedQuiz)
                    dismiss()
                }
                .disabled(!isValid)
            )
        }
    }
}

// MARK: - Preview Helpers
struct QuestionEditViews_Previews: PreviewProvider {
    static var previews: some View {
        let sampleQuiz = quiz(
            id: "1",
            title: "Math Basics",
            category: "Math",
            description: "Basic math questions",
            duration: 10,
            questions: []
        )
        
        let sampleChild = Child(
            id: "1",
            name: "Emma",
            age: 8,
            level: "5",
            avatarEmoji: "👧",
            Score: 100,
            quizzes: [],
            totalPoints: 0,
            connectionToken: "ABC123"
        )
        
        AddQuestionView(quiz: sampleQuiz, child: sampleChild) { _ in }
    }
}
