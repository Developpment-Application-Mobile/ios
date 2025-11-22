//
//  AIQuizService.swift - UPDATED
//  EduKid
//
//  Updated: November 21, 2025
//  Synchronized with backend API
//

import Foundation

class AIQuizService {
    static let shared = AIQuizService()
    
    private let baseURL = "https://accessorial-zaida-soggily.ngrok-free.dev"
    
    private init() {}
    
    // MARK: - Generate AI Quiz (Normal or Adaptive)
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
        
        let decoder = JSONDecoder()
        let quizResponse = try decoder.decode(AIQuizResponse.self, from: data)
        print("✅ AI QUIZ: Generated successfully with \(quizResponse.questions.count) questions")
        
        return quizResponse
    }
    
    // MARK: - Generate Retry Quiz (Empty body = retry mode)
    func generateRetryQuiz(
        parentId: String,
        kidId: String
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
        
        // Empty body triggers retry mode on backend
        let requestBody: [String: Any] = [:]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 RETRY QUIZ: Generating retry quiz based on incorrect answers")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("🔄 RETRY QUIZ RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuizError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw QuizError.serverError(errorData.message ?? "Failed to generate retry quiz")
            }
            throw QuizError.serverError("Failed to generate retry quiz: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let quizResponse = try decoder.decode(AIQuizResponse.self, from: data)
        print("✅ RETRY QUIZ: Generated successfully with \(quizResponse.questions.count) questions")
        
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
    
    // MARK: - Submit Quiz Answer (UPDATED to match backend)
    func submitQuizAnswer(
        parentId: String,
        kidId: String,
        quizId: String,
        answers: [Int]  // Changed from [String: Int] to [Int]
    ) async throws -> QuizResultResponse {
        let submitEndpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)/submit"
        
        guard let url = URL(string: submitEndpoint) else {
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
        
        // Backend expects: { "answers": [0, 2, 1, 3] }
        let requestBody = ["answers": answers]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 SUBMIT QUIZ REQUEST:")
        print("   URL: \(submitEndpoint)")
        print("   Answers: \(answers)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("📥 SUBMIT QUIZ RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuizError.invalidResponse
        }
        
        print("📥 SUBMIT QUIZ STATUS CODE: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorMsg = errorJson["message"] as? String ??
                               errorJson["error"] as? String ??
                               "Failed to submit answers"
                print("❌ SUBMIT ERROR: \(errorMsg)")
                throw QuizError.serverError(errorMsg)
            }
            throw QuizError.serverError("Failed to submit answers: Status \(httpResponse.statusCode)")
        }
        
        // Parse backend response
        do {
            let result = try parseSubmitResponse(from: data)
            print("✅ SUBMIT SUCCESS: \(result.correctAnswers)/\(result.totalQuestions) - \(result.score)%")
            return result
        } catch {
            print("❌ DECODE ERROR: \(error)")
            throw QuizError.serverError("Failed to decode quiz result: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Parse Submit Response
    private func parseSubmitResponse(from data: Data) throws -> QuizResultResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuizError.serverError("Invalid response format")
        }
        
        print("🔧 Parsing submit response...")
        
        // Backend returns: { quiz, correctAnswers, totalQuestions, score }
        guard let correctAnswers = json["correctAnswers"] as? Int,
              let totalQuestions = json["totalQuestions"] as? Int,
              let score = json["score"] as? Int else {
            throw QuizError.serverError("Missing required fields in response")
        }
        
        // Quiz object contains updated questions with userAnswerIndex
        let quizData = json["quiz"] as? [String: Any]
        let questionsArray = quizData?["questions"] as? [[String: Any]] ?? []
        
        // Build answer details from questions
        var answerDetails: [AnswerDetail] = []
        for (index, questionDict) in questionsArray.enumerated() {
            let questionId = questionDict["_id"] as? String ?? "\(index)"
            let userAnswerIndex = questionDict["userAnswerIndex"] as? Int ?? -1
            let correctAnswerIndex = questionDict["correctAnswerIndex"] as? Int ?? 0
            let isCorrect = userAnswerIndex == correctAnswerIndex
            
            answerDetails.append(AnswerDetail(
                questionId: questionId,
                isCorrect: isCorrect,
                userAnswer: userAnswerIndex,
                correctAnswer: correctAnswerIndex
            ))
        }
        
        let percentage = totalQuestions > 0 ? Double(score) : 0.0
        
        print("✅ Parsing successful: \(correctAnswers)/\(totalQuestions) - \(score)%")
        
        return QuizResultResponse(
            score: score,
            totalQuestions: totalQuestions,
            percentage: percentage,
            correctAnswers: correctAnswers,
            answers: answerDetails
        )
    }
}

// MARK: - Models (UPDATED)
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
    let isAnswered: Bool
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
        case isAnswered
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Quiz"
        questions = try container.decode([AIQuestion].self, forKey: .questions)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "quiz"
        score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        answered = try container.decodeIfPresent(Int.self, forKey: .answered) ?? 0
        isAnswered = try container.decodeIfPresent(Bool.self, forKey: .isAnswered) ?? false
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        
        let titleStr = title
        
        // Parse difficulty from title or type
        if titleStr.lowercased().contains("beginner") {
            difficulty = "beginner"
        } else if titleStr.lowercased().contains("intermediate") {
            difficulty = "intermediate"
        } else if titleStr.lowercased().contains("advanced") {
            difficulty = "advanced"
        } else {
            difficulty = "beginner"
        }
        
        // Parse subject from title or type
        if titleStr.lowercased().contains("math") || type.lowercased() == "math" {
            subject = "math"
        } else if titleStr.lowercased().contains("science") || type.lowercased() == "science" {
            subject = "science"
        } else if titleStr.lowercased().contains("english") || type.lowercased() == "english" {
            subject = "english"
        } else if titleStr.lowercased().contains("history") || type.lowercased() == "history" {
            subject = "history"
        } else if titleStr.lowercased().contains("geography") || type.lowercased() == "geography" {
            subject = "geography"
        } else {
            subject = type
        }
        
        // Parse topic from title
        if let dashIndex = titleStr.firstIndex(of: "-") {
            let topicStart = titleStr.index(after: dashIndex)
            var topicStr = String(titleStr[topicStart...]).trimmingCharacters(in: .whitespaces)
            topicStr = topicStr.replacingOccurrences(of: "Quiz", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            topic = topicStr.isEmpty ? "General" : topicStr
        } else {
            topic = "General"
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
    let userAnswerIndex: Int?  // Added field from backend
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case questionText
        case options
        case correctAnswerIndex
        case explanation
        case imageUrl
        case type
        case level
        case userAnswerIndex
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
