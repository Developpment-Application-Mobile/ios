//
//  Quiz Management Views - COMPLETE
//  EduKid
//
//  Updated: November 22, 2025
//  Added missing views: AddQuestionView, EditQuestionView, EditQuizView
//  Fixed to match backend schema
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
                        ForEach(quizType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
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
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let newQuiz = quiz(
                        title: title,
                        category: selectedType.rawValue,
                        description: description.isEmpty ? nil : description,
                        duration: Int(duration),
                        questions: [],
                        type: selectedType,
                        answered: 0,
                        isAnswered: false,
                        score: 0
                    )
                    onSave(newQuiz)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Add Question View
struct AddQuestionView: View {
    let quiz: quiz
    let child: Child
    let onSave: (Question) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var questionText = ""
    @State private var options: [String] = ["", "", "", ""]
    @State private var correctAnswerIndex = 0
    @State private var explanation = ""
    @State private var selectedType = "general"
    @State private var selectedLevel = "beginner"
    
    let types = ["math", "science", "english", "history", "geography", "general"]
    let levels = ["beginner", "intermediate", "advanced"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Enter your question", text: $questionText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Options") {
                    ForEach(0..<4, id: \.self) { index in
                        HStack {
                            TextField("Option \(["A", "B", "C", "D"][index])", text: $options[index])
                            
                            if correctAnswerIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Correct Answer") {
                    Picker("Select correct answer", selection: $correctAnswerIndex) {
                        ForEach(0..<4, id: \.self) { index in
                            Text("Option \(["A", "B", "C", "D"][index])").tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Type & Level") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(levels, id: \.self) { l in
                            Text(l.capitalized).tag(l)
                        }
                    }
                }
                
                Section("Explanation (Optional)") {
                    TextField("Why is this the correct answer?", text: $explanation, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let filteredOptions = options.filter { !$0.isEmpty }
                        let newQuestion = Question(
                            questionText: questionText,
                            options: filteredOptions,
                            correctAnswer: filteredOptions[correctAnswerIndex],
                            correctAnswerIndex: correctAnswerIndex,
                            explanation: explanation.isEmpty ? nil : explanation,
                            type: selectedType,
                            level: selectedLevel
                        )
                        onSave(newQuestion)
                        dismiss()
                    }
                    .disabled(questionText.isEmpty || options.filter { !$0.isEmpty }.count < 2)
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
    @State private var selectedType: String
    @State private var selectedLevel: String
    
    let types = ["math", "science", "english", "history", "geography", "general"]
    let levels = ["beginner", "intermediate", "advanced"]
    
    init(question: Question, quiz: quiz, child: Child, onSave: @escaping (Question) -> Void) {
        self.question = question
        self.quiz = quiz
        self.child = child
        self.onSave = onSave
        
        _questionText = State(initialValue: question.questionText)
        
        var opts = question.options
        while opts.count < 4 { opts.append("") }
        _options = State(initialValue: opts)
        
        let correctIdx = question.correctAnswerIndex ?? question.options.firstIndex(of: question.correctAnswer) ?? 0
        _correctAnswerIndex = State(initialValue: correctIdx)
        _explanation = State(initialValue: question.explanation ?? "")
        _selectedType = State(initialValue: question.type ?? "general")
        _selectedLevel = State(initialValue: question.level ?? "beginner")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Enter your question", text: $questionText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Options") {
                    ForEach(0..<4, id: \.self) { index in
                        HStack {
                            TextField("Option \(["A", "B", "C", "D"][index])", text: $options[index])
                            if correctAnswerIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Correct Answer") {
                    Picker("Select correct answer", selection: $correctAnswerIndex) {
                        ForEach(0..<4, id: \.self) { index in
                            Text("Option \(["A", "B", "C", "D"][index])").tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Type & Level") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(levels, id: \.self) { l in
                            Text(l.capitalized).tag(l)
                        }
                    }
                }
                
                Section("Explanation (Optional)") {
                    TextField("Why is this the correct answer?", text: $explanation, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let filteredOptions = options.filter { !$0.isEmpty }
                        let updatedQuestion = Question(
                            id: question.id,
                            questionText: questionText,
                            options: filteredOptions,
                            correctAnswer: filteredOptions[correctAnswerIndex],
                            correctAnswerIndex: correctAnswerIndex,
                            explanation: explanation.isEmpty ? nil : explanation,
                            type: selectedType,
                            level: selectedLevel
                        )
                        onSave(updatedQuestion)
                        dismiss()
                    }
                    .disabled(questionText.isEmpty || options.filter { !$0.isEmpty }.count < 2)
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
        _description = State(initialValue: quiz.description ?? "")
        _duration = State(initialValue: quiz.duration != nil ? "\(quiz.duration!)" : "")
        
        // Safely unwrap the optional quizType
        if let t = quiz.type {
            _selectedType = State(initialValue: t)
        } else if let t = quizType(rawValue: quiz.category.lowercased()) {
            _selectedType = State(initialValue: t)
        } else {
            _selectedType = State(initialValue: .general)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Information") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $selectedType) {
                        ForEach(quizType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Description (optional)", text: $description)
                    TextField("Duration in minutes (optional)", text: $duration)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedQuiz = Quiz(
                            id: quiz.id,
                            title: title,
                            category: selectedType.rawValue,
                            description: description.isEmpty ? nil : description,
                            duration: Int(duration),
                            questions: quiz.questions,
                            type: selectedType,
                            answered: quiz.answered,
                            isAnswered: quiz.isAnswered,
                            score: quiz.score
                        )
                        onSave(updatedQuiz)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// Note: Question, quiz, and quizType models are defined in their respective files:
// - Question.swift
// - Quiz.swift
// - QuizType.swift
