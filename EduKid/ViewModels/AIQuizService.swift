//
//  AIQuizService.swift
//  EduKid
//
//  Created: November 16, 2025
//  AI-Generated Quiz Service - FIXED
//

import Foundation

class AIQuizService {
    static let shared = AIQuizService()
    
    private let baseURL = "https://accessorial-zaida-soggily.ngrok-free.dev"
    
    private init() {}
    
    // MARK: - Generate AI Quiz
    func generateAIQuiz(
        parentId: String,
        kidId: String,
        subject: String,
        difficulty: String,
        nbrQuestions: Int,
        topic: String
    ) async throws -> AIQuizResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes"
        
        guard let url = URL(string: endpoint) else {
            throw QuizError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw QuizError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let requestBody: [String: Any] = [
            "subject": subject,
            "difficulty": difficulty,
            "nbrQuestions": nbrQuestions,
            "topic": topic
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🤖 AI QUIZ: Generating quiz - Subject: \(subject), Topic: \(topic), Questions: \(nbrQuestions)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("🤖 AI QUIZ RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuizError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw QuizError.serverError(errorData.message ?? "Failed to generate quiz")
            }
            throw QuizError.serverError("Failed to generate quiz: \(httpResponse.statusCode)")
        }
        
        // Parse the response - the API returns the quiz directly
        let decoder = JSONDecoder()
        let quizResponse = try decoder.decode(AIQuizResponse.self, from: data)
        print("✅ AI QUIZ: Generated successfully with \(quizResponse.questions.count) questions")
        
        return quizResponse
    }
    
    // MARK: - Get All Quizzes for a Child
    func getQuizzes(parentId: String, kidId: String) async throws -> [AIQuizResponse] {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes"
        
        guard let url = URL(string: endpoint) else {
            throw QuizError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw QuizError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("🤖 GET QUIZZES RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw QuizError.serverError("Failed to fetch quizzes")
        }
        
        let decoder = JSONDecoder()
        let quizzes = try decoder.decode([AIQuizResponse].self, from: data)
        print("✅ Fetched \(quizzes.count) quizzes")
        
        return quizzes
    }
    
    // MARK: - Get Single Quiz
    func getQuiz(parentId: String, kidId: String, quizId: String) async throws -> AIQuizResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)"
        
        guard let url = URL(string: endpoint) else {
            throw QuizError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw QuizError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw QuizError.serverError("Failed to fetch quiz")
        }
        
        return try JSONDecoder().decode(AIQuizResponse.self, from: data)
    }
    
    // MARK: - Delete Quiz
    func deleteQuiz(parentId: String, kidId: String, quizId: String) async throws {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)"
        
        guard let url = URL(string: endpoint) else {
            throw QuizError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw QuizError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw QuizError.serverError("Failed to delete quiz")
        }
        
        print("✅ Quiz deleted successfully")
    }
    
    // MARK: - Submit Quiz Answer
    func submitQuizAnswer(
        parentId: String,
        kidId: String,
        quizId: String,
        answers: [String: Int]
    ) async throws -> QuizResultResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)/submit"
        
        guard let url = URL(string: endpoint) else {
            throw QuizError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw QuizError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let requestBody = ["answers": answers]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw QuizError.serverError("Failed to submit answers")
        }
        
        return try JSONDecoder().decode(QuizResultResponse.self, from: data)
    }
}

// MARK: - Models
struct AIQuizResponse: Codable, Identifiable {
    let id: String
    let title: String
    let subject: String
    let difficulty: String
    let topic: String
    let questions: [AIQuestion]
    let type: String
    let score: Int
    let answered: Int
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case subject
        case difficulty
        case topic
        case questions
        case type
        case score
        case answered
        case createdAt
    }
    
    // Custom init to provide default values and extract subject/difficulty/topic from title if needed
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Quiz"
        questions = try container.decode([AIQuestion].self, forKey: .questions)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "quiz"
        score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        answered = try container.decodeIfPresent(Int.self, forKey: .answered) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        
        // Extract subject, difficulty, and topic from title
        // Title format: "Beginner Math: Plus and Minus" or "Beginner Math Quiz: Addition"
        let titleStr = title
        
        // Extract difficulty
        if titleStr.lowercased().contains("beginner") {
            difficulty = "beginner"
        } else if titleStr.lowercased().contains("intermediate") {
            difficulty = "intermediate"
        } else if titleStr.lowercased().contains("advanced") {
            difficulty = "advanced"
        } else {
            difficulty = "beginner"
        }
        
        // Extract subject
        if titleStr.lowercased().contains("math") {
            subject = "math"
        } else if titleStr.lowercased().contains("science") {
            subject = "science"
        } else if titleStr.lowercased().contains("english") {
            subject = "english"
        } else if titleStr.lowercased().contains("history") {
            subject = "history"
        } else if titleStr.lowercased().contains("geography") {
            subject = "geography"
        } else {
            subject = "general"
        }
        
        // Extract topic from title (everything after ":" or fallback to title)
        if let colonIndex = titleStr.firstIndex(of: ":") {
            let topicStart = titleStr.index(after: colonIndex)
            topic = String(titleStr[topicStart...]).trimmingCharacters(in: .whitespaces)
        } else {
            // Remove difficulty and subject from title to get topic
            var topicStr = titleStr
                .replacingOccurrences(of: "Beginner", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Intermediate", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Advanced", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Math", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Science", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "English", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "History", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Geography", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Quiz", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            
            topic = topicStr.isEmpty ? "General" : topicStr
        }
    }
}

struct AIQuestion: Codable, Identifiable {
    let id: String
    let questionText: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String?
    let imageUrl: String?
    let type: String?
    let level: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case questionText
        case options
        case correctAnswerIndex
        case explanation
        case imageUrl
        case type
        case level
    }
}

struct QuizResultResponse: Codable {
    let score: Int
    let totalQuestions: Int
    let percentage: Double
    let correctAnswers: Int
    let answers: [AnswerDetail]
}

struct AnswerDetail: Codable {
    let questionId: String
    let isCorrect: Bool
    let userAnswer: Int
    let correctAnswer: Int
}

enum QuizError: LocalizedError {
    case invalidURL
    case noToken
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noToken:
            return "No authentication token"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        }
    }
}
