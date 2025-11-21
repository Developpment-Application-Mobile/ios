//
//  QuizType.swift
//  EduKid
//
//  Fixed: November 22, 2025 - Match backend lowercase values
//

import Foundation
import SwiftUI

enum quizType: String, Codable, CaseIterable {
    case math = "math"
    case science = "science"
    case english = "english"
    case history = "history"
    case geography = "geography"
    case general = "general"
    case mixed = "mixed"  // Added for "Getting Started Quiz"
    
    // Display name for UI
    var displayName: String {
        switch self {
        case .math: return "Math"
        case .science: return "Science"
        case .english: return "English"
        case .history: return "History"
        case .geography: return "Geography"
        case .general: return "General"
        case .mixed: return "Mixed"
        }
    }
}
