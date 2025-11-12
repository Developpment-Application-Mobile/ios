//
//  Child.swift
//  EduKid
//
//  Created by Mac Mini 11 on 4/11/2025.
//

// Child.swift
import Foundation
import SwiftUI


struct Child: Identifiable, Codable {
    let id: String
    let name: String
    let age: Int
    let level: String
    let avatarEmoji: String
    let Score: Int
    let quizzes: [String]
    var totalPoints: Int = 0
    let connectionToken: String
    var rewards: [Reward] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        age: Int,
        level: String,
        avatarEmoji: String,
        Score: Int,
        quizzes: [String] = [],
        totalPoints: Int = 0,
        connectionToken: String,
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

    func getCompletedQuizzes() -> [String] {
        return quizzes // TODO: logique réelle plus tard
    }
}
