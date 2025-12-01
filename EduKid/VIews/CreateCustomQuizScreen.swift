import SwiftUI

struct CreateCustomQuizScreen: View {
    let child: Child
    let onQuizCreated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var subject = ""
    @State private var topic = ""
    @State private var difficulty = "beginner"
    @State private var numberOfQuestions = 5
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    let difficulties = ["beginner", "intermediate", "advanced"]
    
    var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Custom Quiz")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Tailor a quiz specifically for \(child.name)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Form Card
                    VStack(spacing: 24) {
                        // Subject Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("e.g., Math, Science, History", text: $subject)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Topic Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Specific Topic")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("e.g., Dinosaurs, Fractions, Space", text: $topic)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Difficulty Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Difficulty Level")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 0) {
                                ForEach(difficulties, id: \.self) { level in
                                    Button(action: { difficulty = level }) {
                                        Text(level.capitalized)
                                            .font(.subheadline.bold())
                                            .foregroundColor(difficulty == level ? Color(hex: "272052") : .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(difficulty == level ? Color.white : Color.clear)
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Number of Questions
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Number of Questions")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(numberOfQuestions)")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Stepper("", value: $numberOfQuestions, in: 3...15)
                                .labelsHidden()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .colorScheme(.dark) // Make stepper visible on dark background
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Create Button
                    Button(action: createQuiz) {
                        HStack(spacing: 12) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "272052")))
                            } else {
                                Image(systemName: "wand.and.stars")
                                    .font(.title2)
                            }
                            Text(isGenerating ? "Creating Quiz..." : "Create Quiz")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "272052"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(isValid ? Color.white : Color.white.opacity(0.5))
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .disabled(isGenerating || !isValid)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
        }
        .alert("Success! 🎉", isPresented: $showSuccess) {
            Button("Done") {
                onQuizCreated()
                dismiss()
            }
        } message: {
            Text("Your custom quiz has been created successfully.")
        }
    }
    
    private func createQuiz() {
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

struct CreateCustomQuizScreen_Previews: PreviewProvider {
    static var previews: some View {
        CreateCustomQuizScreen(
            child: Child(
                name: "Test Child",
                age: 8,
                level: "beginner",
                avatarEmoji: "avatar_1",
                Score: 0,
                quizzes: [],
                connectionToken: "token"
            ),
            onQuizCreated: {}
        )
    }
}
