//
//  PuzzleModels.swift
//  EduKid
//
//  FIXED: Added custom image path support
//

import Foundation
import SwiftUI

// MARK: - Puzzle Piece
struct PuzzlePiece: Codable, Identifiable, Equatable {
    var id: Int
    var correctPosition: Int
    var currentPosition: Int
    var content: String
    var imageUrl: String?
    
    var isEmoji: Bool { content.isSingleEmoji }
    var isImage: Bool { imageUrl?.isEmpty == false }
    var displayText: String { content.trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Puzzle Type
enum PuzzleType: String, Codable, CaseIterable {
    case image = "image"
    case word = "word"
    case number = "number"
    case sequence = "sequence"
    case pattern = "pattern"
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .word: return "Word"
        case .number: return "Number"
        case .sequence: return "Sequence"
        case .pattern: return "Pattern"
        }
    }
    
    var icon: String {
        switch self {
        case .image: return "photo.fill"
        case .word: return "textformat.abc"
        case .number: return "number"
        case .sequence: return "arrow.right.arrow.left"
        case .pattern: return "square.grid.3x3.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .image: return .purple
        case .word: return .blue
        case .number: return .green
        case .sequence: return .orange
        case .pattern: return .pink
        }
    }
}

// MARK: - Puzzle Difficulty
enum PuzzleDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String { rawValue.capitalized }
    
    var gridSize: Int {
        switch self {
        case .easy: return 2
        case .medium: return 3
        case .hard: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Puzzle Image (Codable)
enum PuzzleImage: String, Codable, CaseIterable {
    case lion = "puzzle_lion"
    case turtle = "puzzle_turtle"
    case elephant = "puzzle_elephant"
    case rabbit = "puzzle_rabbit"
    case cat = "puzzle_cat"
    case dog = "puzzle_dog"
    case bear = "puzzle_bear"
    case panda = "puzzle_panda"
    
    var displayName: String {
        rawValue.replacingOccurrences(of: "puzzle_", with: "").capitalized
    }
    
    var emoji: String {
        switch self {
        case .lion: return "🦁"
        case .turtle: return "🐢"
        case .elephant: return "🐘"
        case .rabbit: return "🐰"
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .bear: return "🐻"
        case .panda: return "🐼"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .lion: return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .turtle: return Color(red: 0.6, green: 0.9, blue: 0.95)
        case .elephant: return Color(red: 0.7, green: 0.85, blue: 0.95)
        case .rabbit: return Color(red: 0.95, green: 0.85, blue: 0.9)
        case .cat: return Color(red: 1.0, green: 0.9, blue: 0.8)
        case .dog: return Color(red: 0.9, green: 0.85, blue: 0.75)
        case .bear: return Color(red: 0.85, green: 0.75, blue: 0.65)
        case .panda: return Color(red: 0.9, green: 0.95, blue: 0.9)
        }
    }
    
    static func random() -> PuzzleImage {
        allCases.randomElement()!
    }
}

// MARK: - Puzzle Response (Server)
struct PuzzleResponse: Codable, Identifiable {
    let id: String
    let title: String
    let type: String
    let difficulty: String
    let gridSize: Int
    var pieces: [PuzzlePiece]
    let hint: String?
    let solution: String?
    let imageUrl: String?
    var isCompleted: Bool
    var attempts: Int
    var timeSpent: Int
    var score: Int
    let completedAt: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, type, difficulty, gridSize, pieces
        case hint, solution, imageUrl
        case isCompleted, attempts, timeSpent, score
        case completedAt, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try container.decode(String.self, forKey: .title)
        self.type = try container.decode(String.self, forKey: .type)
        self.difficulty = try container.decode(String.self, forKey: .difficulty)
        self.gridSize = try container.decode(Int.self, forKey: .gridSize)
        self.pieces = try container.decode([PuzzlePiece].self, forKey: .pieces)
        
        if let realId = try? container.decode(String.self, forKey: .id), !realId.isEmpty {
            self.id = realId
        } else {
            self.id = "temp_\(UUID().uuidString.prefix(8))"
        }
        
        self.hint = try container.decodeIfPresent(String.self, forKey: .hint)
        self.solution = try container.decodeIfPresent(String.self, forKey: .solution)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        self.attempts = (try? container.decode(Int.self, forKey: .attempts)) ?? 0
        self.timeSpent = (try? container.decode(Int.self, forKey: .timeSpent)) ?? 0
        self.score = (try? container.decode(Int.self, forKey: .score)) ?? 0
        self.completedAt = try? container.decodeIfPresent(String.self, forKey: .completedAt)
        self.createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
    }
    
    var puzzleType: PuzzleType { PuzzleType(rawValue: type) ?? .word }
    var puzzleDifficulty: PuzzleDifficulty { PuzzleDifficulty(rawValue: difficulty) ?? .easy }
    var isSolved: Bool { pieces.allSatisfy { $0.currentPosition == $0.correctPosition } }
}

// MARK: - Submit Response
struct PuzzleSubmitResponse: Codable {
    let puzzle: PuzzleResponse
    let isCorrect: Bool
    let score: Int
    let attempts: Int
    let message: String
}

// MARK: - Local Puzzle Model (UPDATED with custom image path)
struct LocalPuzzle: Codable, Identifiable {
    let id: String
    let childId: String
    let title: String
    let type: PuzzleType
    let difficulty: PuzzleDifficulty
    let gridSize: Int
    var pieces: [LocalPuzzlePiece]
    let hint: String
    let solution: String
    let puzzleImage: PuzzleImage
    let customImagePath: String?
    var isCompleted: Bool
    var attempts: Int
    var timeSpent: Int
    var score: Int
    let createdAt: Date
    var completedAt: Date?
    
    var puzzleType: PuzzleType { type }
    var puzzleDifficulty: PuzzleDifficulty { difficulty }
}

// MARK: - Local Puzzle Piece
struct LocalPuzzlePiece: Codable, Identifiable {
    var id: Int
    var correctPosition: Int
    var currentPosition: Int
    var content: String
    var emoji: String?
    var imageUrl: String?
}

// MARK: - Local Puzzle Result
struct LocalPuzzleResult {
    let isCorrect: Bool
    let score: Int
    let message: String
}

// MARK: - String Extensions
extension String {
    var isSingleEmoji: Bool {
        guard count == 1, let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
    
    var containsEmoji: Bool { contains { $0.isEmoji } }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x1F600...0x1F64F, 0x1F300...0x1F5FF, 0x1F680...0x1F6FF,
             0x1F1E6...0x1F1FF, 0x2600...0x26FF, 0x2700...0x27BF,
             0xFE00...0xFE0F, 0x1F900...0x1F9FF:
            return true
        default: return false
        }
    }
}
