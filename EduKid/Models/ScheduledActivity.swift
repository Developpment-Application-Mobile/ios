//
//  ScheduledActivity.swift
//  EduKid
//
//  Created on December 1, 2025.
//  Model for scheduled activities
//

import Foundation
import SwiftUI

// MARK: - Scheduled Activity Model
struct ScheduledActivity: Identifiable, Codable {
    let id: String
    let childId: String
    let activityType: ActivityType
    let title: String
    let description: String
    let scheduledTime: Date
    let duration: TimeInterval // in seconds
    var isCompleted: Bool
    var quizData: AIQuizResponse? // If it's a quiz
    
    enum ActivityType: String, Codable {
        case quiz = "quiz"
        case game = "game"
        case puzzle = "puzzle"
        
        var icon: String {
            switch self {
            case .quiz: return "brain.head.profile"
            case .game: return "gamecontroller.fill"
            case .puzzle: return "puzzlepiece.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .quiz: return Color(red: 0.686, green: 0.494, blue: 0.906)
            case .game: return .green
            case .puzzle: return .orange
            }
        }
    }
    
    var isAvailable: Bool {
        return Date() >= scheduledTime
    }
    
    var timeRemaining: TimeInterval {
        return max(0, scheduledTime.timeIntervalSinceNow)
    }
}
