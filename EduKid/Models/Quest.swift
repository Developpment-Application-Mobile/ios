import Foundation

enum QuestType: String, Codable, CaseIterable {
    case completeQuizzes = "COMPLETE_QUIZZES"
    case completeGames = "COMPLETE_GAMES"
    case earnPoints = "EARN_POINTS"
    case perfectScore = "PERFECT_SCORE"
    
    var displayName: String {
        switch self {
        case .completeQuizzes: return "Compléter des Quiz"
        case .completeGames: return "Jouer à des Jeux"
        case .earnPoints: return "Gagner des Points"
        case .perfectScore: return "Score Parfait"
        }
    }
}

enum QuestStatus: String, Codable {
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case claimed = "CLAIMED"
}

struct Quest: Identifiable, Codable {
    let id: String
    let type: QuestType
    let title: String?
    let description: String?
    var progress: Int
    let target: Int
    let reward: Int
    var status: QuestStatus
    let progressionLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case title
        case description
        case progress
        case target
        case reward
        case status
        case progressionLevel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle potential ID mismatch
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else {
            id = UUID().uuidString
        }
        
        // Safely decode Enums
        let typeString = try container.decode(String.self, forKey: .type)
        type = QuestType(rawValue: typeString) ?? .earnPoints // Fallback
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        progress = try container.decodeIfPresent(Int.self, forKey: .progress) ?? 0
        target = try container.decode(Int.self, forKey: .target)
        reward = try container.decode(Int.self, forKey: .reward)
        
        let statusString = try container.decode(String.self, forKey: .status)
        status = QuestStatus(rawValue: statusString) ?? .active
        
        progressionLevel = try container.decodeIfPresent(Int.self, forKey: .progressionLevel) ?? 1
    }
}
