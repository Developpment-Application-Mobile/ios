//
//  Quiz.swift
//  EduKid
//
//  Fixed: November 22, 2025 - Match backend schema, fixed typo
//

import Foundation
import SwiftUI

struct quiz: Identifiable {
    var id: String?
    var title: String
    var category: String
    var description: String?
    var duration: Int?
    var questions: [Question]
    var completionPercentage: Int?
    var type: quizType?
    
    // Backend fields
    var answered: Int?
    var isAnswered: Bool?
    var score: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case category
        case type
        case description
        case duration
        case questions
        case answered
        case isAnswered
        case score
    }
    
    // Computed property to get quizType from category
    var categoryType: quizType {
        quizType(rawValue: category.lowercased()) ?? .general
    }
    
    // Initialize - FIXED: removed extra "A" after category
    init(id: String? = nil,
         title: String,
         category: String,
         description: String? = nil,
         duration: Int? = nil,
         questions: [Question] = [],
         completionPercentage: Int? = nil,
         type: quizType? = nil,
         answered: Int? = nil,
         isAnswered: Bool? = nil,
         score: Int? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.duration = duration
        self.questions = questions
        self.completionPercentage = completionPercentage
        self.type = type ?? quizType(rawValue: category.lowercased())
        self.answered = answered
        self.isAnswered = isAnswered
        self.score = score
    }
}

// Type alias for consistency
typealias Quiz = quiz

// MARK: - Codable Conformance
extension quiz: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        // Handle category/type - backend uses "type" field
        if let typeStr = try container.decodeIfPresent(String.self, forKey: .type) {
            category = typeStr
            type = quizType(rawValue: typeStr.lowercased())
        } else if let cat = try container.decodeIfPresent(String.self, forKey: .category) {
            category = cat
            type = quizType(rawValue: cat.lowercased())
        } else {
            category = "general"
            type = .general
        }
        
        description = try container.decodeIfPresent(String.self, forKey: .description)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
        answered = try container.decodeIfPresent(Int.self, forKey: .answered)
        isAnswered = try container.decodeIfPresent(Bool.self, forKey: .isAnswered)
        score = try container.decodeIfPresent(Int.self, forKey: .score)
        completionPercentage = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .type)  // Backend expects "type"
        
        if let desc = description {
            try container.encode(desc, forKey: .description)
        }
        
        if let dur = duration {
            try container.encode(dur, forKey: .duration)
        }
        
        try container.encode(questions, forKey: .questions)
        
        if let ans = answered {
            try container.encode(ans, forKey: .answered)
        }
        
        if let isAns = isAnswered {
            try container.encode(isAns, forKey: .isAnswered)
        }
        
        if let sc = score {
            try container.encode(sc, forKey: .score)
        }
    }
}

// MARK: - Quiz Service
class QuizService {
    static let shared = QuizService()
    
    private let baseURL = "https://accessorial-zaida-soggily.ngrok-free.dev"
    
    private init() {}
    
    // MARK: - Quiz CRUD
    
    func getQuizzes(parentId: String, kidId: String) async throws -> [quiz] {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("GET QUIZZES RAW: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to get quizzes")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([quiz].self, from: data)
    }
    
    func createQuiz(parentId: String, kidId: String, quiz quizData: quiz) async throws -> quiz {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        request.httpBody = try JSONEncoder().encode(quizData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to create quiz")
        }
        
        return try JSONDecoder().decode(quiz.self, from: data)
    }
    
    func updateQuiz(parentId: String, kidId: String, quizId: String, quiz quizData: quiz) async throws -> quiz {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        request.httpBody = try JSONEncoder().encode(quizData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to update quiz")
        }
        
        return try JSONDecoder().decode(quiz.self, from: data)
    }
    
    func deleteQuiz(parentId: String, kidId: String, quizId: String) async throws {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthError.serverError("Failed to delete quiz")
        }
    }
    
    // MARK: - Question CRUD
    
    func addQuestion(parentId: String, kidId: String, quizId: String, question: Question) async throws -> Question {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)/questions") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        request.httpBody = try JSONEncoder().encode(question)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to add question")
        }
        
        return try JSONDecoder().decode(Question.self, from: data)
    }
    
    func updateQuestion(parentId: String, kidId: String, quizId: String, questionId: String, question: Question) async throws -> Question {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)/questions/\(questionId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        request.httpBody = try JSONEncoder().encode(question)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to update question")
        }
        
        return try JSONDecoder().decode(Question.self, from: data)
    }
    
    func deleteQuestion(parentId: String, kidId: String, quizId: String, questionId: String) async throws {
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(kidId)/quizzes/\(quizId)/questions/\(questionId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthError.serverError("Failed to delete question")
        }
    }
}
