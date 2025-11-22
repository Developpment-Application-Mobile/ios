//
//  PuzzleModels.swift
//  EduKid
//
//  Fixed: Better ID handling and image support
//

import Foundation
import SwiftUI

// MARK: - Puzzle Piece
struct PuzzlePiece: Codable, Identifiable {
    var id: Int
    var correctPosition: Int
    var currentPosition: Int
    var content: String
    var imageUrl: String?
    
    // Helper to determine if this is emoji/image content
    var isEmoji: Bool {
        return content.isSingleEmoji
    }
    
    enum CodingKeys: String, CodingKey {
        case id, correctPosition, currentPosition, content, imageUrl
    }
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
    
    var displayName: String {
        rawValue.capitalized
    }
    
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

// MARK: - Puzzle Response
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
        
        // Required fields
        title = try container.decode(String.self, forKey: .title)
        type = try container.decode(String.self, forKey: .type)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        gridSize = try container.decode(Int.self, forKey: .gridSize)
        pieces = try container.decode([PuzzlePiece].self, forKey: .pieces)
        
        // Try to get _id, fallback to generating temporary one
        if let decodedId = try? container.decode(String.self, forKey: .id) {
            id = decodedId
        } else {
            // Generate temporary ID - will be replaced after refetch
            id = "temp_\(UUID().uuidString)"
            print("⚠️ PUZZLE: No _id in response, using temporary: \(id)")
        }
        
        // Optional fields
        hint = try? container.decodeIfPresent(String.self, forKey: .hint)
        solution = try? container.decodeIfPresent(String.self, forKey: .solution)
        imageUrl = try? container.decodeIfPresent(String.self, forKey: .imageUrl)
        isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        attempts = (try? container.decode(Int.self, forKey: .attempts)) ?? 0
        timeSpent = (try? container.decode(Int.self, forKey: .timeSpent)) ?? 0
        score = (try? container.decode(Int.self, forKey: .score)) ?? 0
        completedAt = try? container.decodeIfPresent(String.self, forKey: .completedAt)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
    }
    
    var puzzleType: PuzzleType {
        PuzzleType(rawValue: type) ?? .word
    }
    
    var puzzleDifficulty: PuzzleDifficulty {
        PuzzleDifficulty(rawValue: difficulty) ?? .easy
    }
    
    var isSolved: Bool {
        pieces.allSatisfy { $0.currentPosition == $0.correctPosition }
    }
    
    var hasTemporaryId: Bool {
        id.starts(with: "temp_")
    }
}

// MARK: - Puzzle Submit Response
struct PuzzleSubmitResponse: Codable {
    let puzzle: PuzzleResponse
    let isCorrect: Bool
    let score: Int
    let attempts: Int
    let message: String
}

// MARK: - Generate Puzzle Request
struct GeneratePuzzleRequest: Codable {
    let type: String?
    let difficulty: String?
    let topic: String?
    let gridSize: Int?
    
    init(type: PuzzleType? = nil, difficulty: PuzzleDifficulty? = nil, topic: String? = nil) {
        self.type = type?.rawValue
        self.difficulty = difficulty?.rawValue
        self.topic = topic
        self.gridSize = difficulty?.gridSize
    }
}

// MARK: - Submit Puzzle Request
struct SubmitPuzzleRequest: Codable {
    let positions: [Int]
    let timeSpent: Int?
}

// MARK: - Extension for String to check emoji
extension String {
    var isSingleEmoji: Bool {
        guard count == 1 else { return false }
        
        let emojiRanges = [
            0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x1F1E6...0x1F1FF, // Regional country flags
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF,   // Dingbats
            0xFE00...0xFE0F,   // Variation Selectors
            0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
            0x1F018...0x1F270, // Various other emoji
        ]
        
        for scalar in unicodeScalars {
            let codePoint = Int(scalar.value)
            for range in emojiRanges {
                if range.contains(codePoint) {
                    return true
                }
            }
        }
        return false
    }
    
    var isEmptyOrNil: Bool {
        return self.isEmpty || self == "null" || self == "undefined"
    }
}
