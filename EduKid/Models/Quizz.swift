//
//  Quizz.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct quiz: Identifiable {
    let id = UUID()
    let title: String
    let questions: [String]
    let completionPercentage: Int
    let type: QuizType
}
