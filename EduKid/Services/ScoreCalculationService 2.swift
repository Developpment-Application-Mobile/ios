//
//  ScoreCalculationService.swift
//  EduKid
//
//  Centralized service for consistent score and completion calculations
//

import Foundation

class ScoreCalculationService {
    static let shared = ScoreCalculationService()
    
    private init() {}
    
    // MARK: - Unified Calculation Method
    func calculateChildStats(
        quizzes: [AIQuizResponse],
        localPuzzles: [LocalPuzzle],
        serverPuzzles: [PuzzleResponse],
        games: [[String: Any]]
    ) -> ChildStats {
        
        // Filter completed items using consistent logic
        let completedQuizzes = quizzes.filter { $0.isAnswered || $0.answered > 0 }
        let completedLocalPuzzles = localPuzzles.filter { $0.isCompleted }
        let completedServerPuzzles = serverPuzzles.filter { $0.isCompleted }
        
        // Calculate scores
        let quizScore = completedQuizzes.reduce(0) { $0 + $1.score }
        let localPuzzleScore = completedLocalPuzzles.reduce(0) { $0 + $1.score }
        let serverPuzzleScore = completedServerPuzzles.reduce(0) { $0 + $1.score }
        let gameScore = games.compactMap { $0["score"] as? Int }.reduce(0, +)
        
        let totalScore = quizScore + localPuzzleScore + serverPuzzleScore + gameScore
        let totalCompleted = completedQuizzes.count + completedLocalPuzzles.count + completedServerPuzzles.count + games.count
        
        return ChildStats(
            totalScore: totalScore,
            totalCompleted: totalCompleted,
            quizScore: quizScore,
            localPuzzleScore: localPuzzleScore,
            serverPuzzleScore: serverPuzzleScore,
            gameScore: gameScore,
            completedQuizzes: completedQuizzes.count,
            completedLocalPuzzles: completedLocalPuzzles.count,
            completedServerPuzzles: completedServerPuzzles.count,
            completedGames: games.count
        )
    }
    
    // MARK: - Load All Data and Calculate
    func loadAndCalculateStats(for childId: String, parentId: String) async throws -> ChildStats {
        // Load all data
        let quizzes = try await AIQuizService.shared.getQuizzes(parentId: parentId, kidId: childId)
        let serverPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: childId)
        let localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: childId)
        let games = UserDefaults.standard.array(forKey: "child_\(childId)_games") as? [[String: Any]] ?? []
        
        return calculateChildStats(
            quizzes: quizzes,
            localPuzzles: localPuzzles,
            serverPuzzles: serverPuzzles,
            games: games
        )
    }
    
    // MARK: - Calculate Net Score (after inventory)
    func calculateNetScore(grossScore: Int, inventory: [Gift]) -> Int {
        let totalSpent = inventory.reduce(0) { $0 + $1.cost }
        return max(0, grossScore - totalSpent)
    }
}

// MARK: - Child Stats Model
struct ChildStats {
    let totalScore: Int
    let totalCompleted: Int
    let quizScore: Int
    let localPuzzleScore: Int
    let serverPuzzleScore: Int
    let gameScore: Int
    let completedQuizzes: Int
    let completedLocalPuzzles: Int
    let completedServerPuzzles: Int
    let completedGames: Int
}
