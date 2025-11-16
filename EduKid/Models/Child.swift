import Foundation
import SwiftUI

struct Child: Identifiable, Codable {
    let id: String
    let name: String
    let age: Int
    let level: String
    let avatarEmoji: String
    let Score: Int
    let quizzes: [quiz]
    var totalPoints: Int
    let connectionToken: String
    var rewards: [Reward]

    init(
        id: String = UUID().uuidString,
        name: String,
        age: Int,
        level: String,
        avatarEmoji: String,
        Score: Int = 0,
        quizzes: [quiz] = [],
        totalPoints: Int = 0,
        connectionToken: String = UUID().uuidString,
        rewards: [Reward] = []
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.level = level
        self.avatarEmoji = avatarEmoji
        self.Score = Score
        self.quizzes = quizzes
        self.totalPoints = totalPoints
        self.connectionToken = connectionToken
        self.rewards = rewards
    }

    func getCompletedQuizzes() -> [quiz] {
        return quizzes.filter { ($0.completionPercentage ?? 0) >= 70 }
    }
    
    var quizCount: Int {
        return quizzes.count
    }
    
    var completedQuizCount: Int {
        return getCompletedQuizzes().count
    }
}
