//
//  QuizResult.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation

struct QuizResult: Identifiable {
    let id: String
    let quizName: String
    let category: String
    let score: Int
    let totalQuestions: Int
    let date: String
    let duration: String
}
