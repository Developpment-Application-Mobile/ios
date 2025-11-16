//
//  QuizType.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

enum quizType: String, Codable, CaseIterable {
    case math = "Math"
    case science = "Science"
    case english = "English"
    case history = "History"
    case geography = "Geography"
    case general = "General"
}


