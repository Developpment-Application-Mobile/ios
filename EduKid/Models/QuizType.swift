//
//  QuizType.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

enum quizType {
    case math, science, history, geography, literature, general
    
    var iconRes: String {
        switch self {
        case .math: return "function"
        case .science: return "flask"
        case .history: return "book.closed"
        case .geography: return "globe"
        case .literature: return "book.pages"
        case .general: return "star.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .math: return Color(red: 1.0, green: 0.8, blue: 0.8)
        case .science: return Color(red: 0.8, green: 1.0, blue: 0.8)
        case .history: return Color(red: 0.8, green: 0.8, blue: 1.0)
        case .geography: return Color(red: 1.0, green: 1.0, blue: 0.8)
        case .literature: return Color(red: 1.0, green: 0.9, blue: 1.0)
        case .general: return Color(red: 0.9, green: 0.9, blue: 0.9)
        }
    }
    
    var progressColor: Color {
        switch self {
        case .math: return Color(red: 0.988, green: 0.376, blue: 0.286)
        case .science: return Color(red: 0.298, green: 0.686, blue: 0.314)
        case .history: return Color(red: 0.573, green: 0.478, blue: 1.0)
        case .geography: return Color(red: 1.0, green: 0.757, blue: 0.027)
        case .literature: return Color(red: 0.906, green: 0.298, blue: 0.235)
        case .general: return Color(red: 0.4, green: 0.4, blue: 0.4)
        }
    }
}
