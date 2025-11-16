//
//  Quizz.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//  Fixed: November 15, 2025 – Type ambiguity and naming consistency
//

import Foundation
import SwiftUI

struct quiz: Identifiable {
    var id: String?
    let title: String
    let category: String
    var description: String?
    var duration: Int? // in minutes
    var questions: [Question]
    var completionPercentage: Int?
    var type: quizType?
    
    // Custom coding keys to match backend
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, category, description, duration, questions
    }
    
    // Computed property to get quizType from category
    var categoryType: quizType {
        quizType(rawValue: category) ?? .general
    }
    
    // Computed property for type-safe category access
    var categoryEnum: quizType? {
        quizType(rawValue: category)
    }
    
    // Initialize
    init(id: String? = nil,
         title: String,
         category: String,
         description: String? = nil,
         duration: Int? = nil,
         questions: [Question] = [],
         completionPercentage: Int? = nil,
         type: quizType? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.duration = duration
        self.questions = questions
        self.completionPercentage = completionPercentage
        self.type = type ?? quizType(rawValue: category)
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
        category = try container.decode(String.self, forKey: .category)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
        completionPercentage = nil
        type = quizType(rawValue: category)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        
        // Fix: Explicitly type the optional values
        if let desc = description {
            try container.encode(desc, forKey: .description)
        }
        
        if let dur = duration {
            try container.encode(dur, forKey: .duration)
        }
        
        try container.encode(questions, forKey: .questions)
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
        let quizzes = try decoder.decode([quiz].self, from: data)
        return quizzes
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
        
        let encoder = JSONEncoder()
        let httpBody = try encoder.encode(quizData)
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("CREATE QUIZ RAW: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to create quiz")
        }
        
        let decoder = JSONDecoder()
        let createdQuiz = try decoder.decode(quiz.self, from: data)
        return createdQuiz
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
        
        let encoder = JSONEncoder()
        let httpBody = try encoder.encode(quizData)
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to update quiz")
        }
        
        let decoder = JSONDecoder()
        let updatedQuiz = try decoder.decode(quiz.self, from: data)
        return updatedQuiz
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
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(question)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("ADD QUESTION RAW: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to add question")
        }
        
        let decoder = JSONDecoder()
        let addedQuestion = try decoder.decode(Question.self, from: data)
        return addedQuestion
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
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(question)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to update question")
        }
        
        let decoder = JSONDecoder()
        let updatedQuestion = try decoder.decode(Question.self, from: data)
        return updatedQuestion
    }
    
    func deleteQuestion(parentId: String, kidId: String, quizId: String, questionId: String) async throws {
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
            throw AuthError.serverError("Failed to delete question")
        }
    }
}
