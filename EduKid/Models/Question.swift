//
//  Question.swift
//  EduKid
//
//  Created by mac on 15/11/2025.
//

import Foundation
import SwiftUI

struct Question: Identifiable, Codable {
    var id: String?
    let questionText: String
    let options: [String]
    let correctAnswer: String
    var explanation: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case questionText, options, correctAnswer, explanation
    }
    
    init(id: String? = nil,
         questionText: String,
         options: [String],
         correctAnswer: String,
         explanation: String? = nil) {
        self.id = id
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}
