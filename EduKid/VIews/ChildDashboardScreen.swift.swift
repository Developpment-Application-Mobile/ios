//
//  ChildDashboardScreen.swift
//  EduKid
//
//  Updated: November 15, 2025 – Fixed all type mismatches
//

import SwiftUI

struct ChildDashboardScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @State private var quizzes: [quiz] = []
    @State private var isLoading = false
    @State private var showAddQuiz = false
    @State private var errorMessage: String?
    
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
                VStack(spacing: 30) {
                    Spacer().frame(height: 60)
                    
                    // Child Avatar + Name
                    VStack(spacing: 12) {
                        Image(child.avatarEmoji)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())
                            .shadow(radius: 8)
                        
                        Text("Welcome, \(child.name)!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    
                    // Score Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(child.Score) Points")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        
                        Text("Level \(child.level)")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal, 30)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal, 30)
                    }
                    
                    // Quizzes Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("My Quizzes")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { showAddQuiz = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if quizzes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No quizzes yet")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Tap + to add your first quiz!")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 30)
                        } else {
                            ForEach(quizzes) { quizItem in
                                NavigationLink(destination: QuizDetailView(quiz: quizItem, child: child, onUpdate: loadQuizzes)) {
                                    QuizCardView(quiz: quizItem)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        NavigationLink(destination: ChildProgressScreen(child: child)) {
                            ActionButton(
                                icon: "chart.bar.fill",
                                title: "My Progress",
                                color: .green
                            )
                        }
                        
                        Button(action: { authVM.signOutChild() }) {
                            ActionButton(
                                icon: "arrow.uturn.left.circle.fill",
                                title: "Logout",
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddQuiz) {
            AddQuizViewSheet(child: child, onSave: { newQuiz in
                Task {
                    await createQuiz(newQuiz)
                    showAddQuiz = false
                }
            })
        }
        .onAppear {
            Task {
                await loadQuizzes()
            }
        }
    }
    
    // MARK: - Quiz Management
    private func loadQuizzes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedQuizzes = try await QuizService.shared.getQuizzes(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id
            )
            await MainActor.run {
                self.quizzes = loadedQuizzes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func createQuiz(_ quizItem: quiz) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await QuizService.shared.createQuiz(
                parentId: AuthService.shared.getParentId() ?? "",
                kidId: child.id,
                quiz: quizItem
            )
            await loadQuizzes()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Quiz Card View
struct QuizCardView: View {
    let quiz: quiz
    
    var iconName: String {
        switch quiz.categoryEnum ?? .general {
        case .math:
            return "function"
        case .science:
            return "flask.fill"
        case .english:
            return "book.fill"
        case .history:
            return "clock.fill"
        case .geography:
            return "globe"
        case .general:
            return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch quiz.categoryEnum ?? .general {
        case .math:
            return .blue
        case .science:
            return .green
        case .english:
            return .purple
        case .history:
            return .orange
        case .geography:
            return .cyan
        case .general:
            return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }
            
            // Quiz Info
            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text(quiz.category)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    Label("\(quiz.questions.count) questions", systemImage: "questionmark.circle.fill")
                    
                    if let duration = quiz.duration {
                        Label("\(duration) min", systemImage: "clock.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.title3.bold())
            Spacer()
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(color.opacity(0.7))
        .cornerRadius(16)
    }
}

// MARK: - Progress Screen (placeholder)
struct ChildProgressScreen: View {
    let child: Child
    
    var body: some View {
        Text("Progress for \(child.name)")
            .navigationTitle("Progress")
    }
}

// MARK: - Add Quiz View
struct AddQuizViewSheet: View {
    let child: Child
    let onSave: (quiz) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedType: quizType = .general
    @State private var description = ""
    @State private var duration = ""
    
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
            .navigationTitle("New Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    let newQuiz = quiz(
                        title: title,
                        category: selectedType.rawValue,
                        description: description.isEmpty ? nil : description,
                        duration: Int(duration),
                        questions: [],
                        type: selectedType
                    )
                    onSave(newQuiz)
                }
                .disabled(!isValid)
            )
        }
    }
}
