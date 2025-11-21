//
//  Question.swift
//  EduKid
//
//  Fixed: November 22, 2025 - Match backend schema
//

import Foundation
import SwiftUI

struct Question: Identifiable, Codable {
    var id: String?
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var correctAnswerIndex: Int?  // Backend uses this
    var explanation: String?
    var imageUrl: String?
    var type: String?      // "math", "science", etc.
    var level: String?     // "beginner", "intermediate", "advanced"
    var userAnswerIndex: Int?  // Stores user's answer after submission
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case questionText
        case options
        case correctAnswer
        case correctAnswerIndex
        case explanation
        case imageUrl
        case type
        case level
        case userAnswerIndex
    }
    
    init(id: String? = nil,
         questionText: String,
         options: [String],
         correctAnswer: String,
         correctAnswerIndex: Int? = nil,
         explanation: String? = nil,
         imageUrl: String? = nil,
         type: String? = nil,
         level: String? = nil,
         userAnswerIndex: Int? = nil) {
        self.id = id
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.correctAnswerIndex = correctAnswerIndex ?? options.firstIndex(of: correctAnswer)
        self.explanation = explanation
        self.imageUrl = imageUrl
        self.type = type
        self.level = level
        self.userAnswerIndex = userAnswerIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        questionText = try container.decode(String.self, forKey: .questionText)
        options = try container.decode([String].self, forKey: .options)
        correctAnswerIndex = try container.decodeIfPresent(Int.self, forKey: .correctAnswerIndex)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        level = try container.decodeIfPresent(String.self, forKey: .level)
        userAnswerIndex = try container.decodeIfPresent(Int.self, forKey: .userAnswerIndex)
        
        // Handle correctAnswer - might come from correctAnswerIndex
        if let idx = correctAnswerIndex, idx >= 0 && idx < options.count {
            correctAnswer = options[idx]
        } else if let answer = try? container.decode(String.self, forKey: .correctAnswer) {
            correctAnswer = answer
        } else {
            correctAnswer = options.first ?? ""
        }
    }
}
