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
    var gameType: GameType? // If it's a game
    var puzzleType: PuzzleType? // If it's a puzzle
    
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
    
    // MARK: - Game Types
    enum GameType: String, Codable {
        case memoryMatch = "Memory Match"
        case colorMatch = "Color Match"
        case shapeMatch = "Shape Match"
        case numberSequence = "Number Sequence"
        case mathQuiz = "Math Quiz"
        case emojiMatch = "Emoji Match"
        
        var icon: String {
            switch self {
            case .memoryMatch: return "brain.head.profile"
            case .colorMatch: return "paintpalette.fill"
            case .shapeMatch: return "square.circle.fill"
            case .numberSequence: return "list.number"
            case .mathQuiz: return "function"
            case .emojiMatch: return "face.smiling"
            }
        }
        
        var description: String {
            switch self {
            case .memoryMatch: return "Match pairs of emojis"
            case .colorMatch: return "Find the correct color"
            case .shapeMatch: return "Match the shapes"
            case .numberSequence: return "Put numbers in order"
            case .mathQuiz: return "Solve math problems"
            case .emojiMatch: return "Match emoji names"
            }
        }
    }
    
    // MARK: - Puzzle Types
    enum PuzzleType: String, Codable {
        case easy = "Easy (3x3)"
        case medium = "Medium (4x4)"
        
        var icon: String {
            switch self {
            case .easy: return "square.grid.3x3.fill"
            case .medium: return "square.grid.4x4.fill"
            }
        }
        
        var description: String {
            switch self {
            case .easy: return "3x3 puzzle grid"
            case .medium: return "4x4 puzzle grid"
            }
        }
    }
}
