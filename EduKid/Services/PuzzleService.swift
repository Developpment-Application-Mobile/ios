//
//  PuzzleService.swift
//  EduKid
//
//  Created by mac on 22/11/2025.
//  Fixed: Better error handling and response parsing
//

import Foundation

class PuzzleService {
    static let shared = PuzzleService()
    
    private let baseURL = "https://accessorial-zaida-soggily.ngrok-free.dev"
    
    private init() {}
    
    // MARK: - Generate Puzzle
    func generatePuzzle(
        parentId: String,
        kidId: String,
        type: PuzzleType? = nil,
        difficulty: PuzzleDifficulty? = nil,
        topic: String? = nil
    ) async throws -> PuzzleResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/puzzles"
        
        guard let url = URL(string: endpoint) else {
            throw PuzzleError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw PuzzleError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        // Build request body
        var body: [String: Any] = [:]
        if let t = type { body["type"] = t.rawValue }
        if let d = difficulty {
            body["difficulty"] = d.rawValue
            body["gridSize"] = d.gridSize
        }
        if let topic = topic { body["topic"] = topic }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🧩 PUZZLE: Generating puzzle - Type: \(type?.rawValue ?? "auto"), Difficulty: \(difficulty?.rawValue ?? "auto")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("🧩 PUZZLE RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PuzzleError.invalidResponse
        }
        
        print("🧩 PUZZLE RESPONSE STATUS: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw PuzzleError.serverError("Server error: \(message)")
            }
            throw PuzzleError.serverError("Failed to generate puzzle (Status: \(httpResponse.statusCode))")
        }
        
        do {
            let puzzle = try JSONDecoder().decode(PuzzleResponse.self, from: data)
            
            // If puzzle has temporary ID, fetch all puzzles to get the real one
            if puzzle.id.starts(with: "temp_") {
                print("🔄 PUZZLE: Fetching all puzzles to get real ID...")
                
                // Wait a moment for backend to save
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let allPuzzles = try await getPuzzles(parentId: parentId, kidId: kidId)
                
                // Find the puzzle we just created (most recent one with matching title)
                if let realPuzzle = allPuzzles.first(where: { $0.title == puzzle.title }) {
                    print("✅ PUZZLE: Found real puzzle with ID: \(realPuzzle.id)")
                    return realPuzzle
                } else {
                    print("⚠️ PUZZLE: Could not find puzzle in list, using temporary")
                    return puzzle
                }
            }
            
            print("✅ PUZZLE: Generated successfully - \(puzzle.title)")
            print("   Type: \(puzzle.type), Difficulty: \(puzzle.difficulty)")
            print("   Grid Size: \(puzzle.gridSize)x\(puzzle.gridSize)")
            print("   Pieces: \(puzzle.pieces.count)")
            return puzzle
        } catch {
            print("❌ PUZZLE DECODE ERROR: \(error)")
            throw PuzzleError.serverError("Failed to decode puzzle: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generate Adaptive Puzzle
    func generateAdaptivePuzzle(parentId: String, kidId: String) async throws -> PuzzleResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/puzzles"
        
        guard let url = URL(string: endpoint) else {
            throw PuzzleError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw PuzzleError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        // Empty body triggers adaptive mode
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        
        print("🧩 PUZZLE: Generating adaptive puzzle...")
        print("🧩 PUZZLE: Endpoint: \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("🧩 ADAPTIVE PUZZLE RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PuzzleError.invalidResponse
        }
        
        print("🧩 ADAPTIVE PUZZLE RESPONSE STATUS: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw PuzzleError.serverError("Server error: \(message)")
            }
            throw PuzzleError.serverError("Failed to generate adaptive puzzle (Status: \(httpResponse.statusCode))")
        }
        
        // Try to parse the response to see what we got
        var tempPuzzle: PuzzleResponse?
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("🧩 PARSED JSON KEYS: \(jsonObject.keys.joined(separator: ", "))")
            if let id = jsonObject["_id"] as? String {
                print("✅ Found _id in response: \(id)")
            } else {
                print("⚠️ No _id field in response! Will fetch from server...")
            }
        }
        
        do {
            let decoder = JSONDecoder()
            let puzzle = try decoder.decode(PuzzleResponse.self, from: data)
            
            // If puzzle has temporary ID, fetch all puzzles to get the real one
            if puzzle.id.starts(with: "temp_") {
                print("🔄 PUZZLE: Fetching all puzzles to get real ID...")
                
                // Wait a moment for backend to save
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let allPuzzles = try await getPuzzles(parentId: parentId, kidId: kidId)
                
                // Find the puzzle we just created (most recent one with matching title)
                if let realPuzzle = allPuzzles.first(where: { $0.title == puzzle.title }) {
                    print("✅ PUZZLE: Found real puzzle with ID: \(realPuzzle.id)")
                    return realPuzzle
                } else {
                    print("⚠️ PUZZLE: Could not find puzzle in list, using temporary")
                    return puzzle
                }
            }
            
            print("✅ PUZZLE: Adaptive puzzle generated - \(puzzle.title)")
            print("   ID: \(puzzle.id)")
            return puzzle
        } catch {
            print("❌ ADAPTIVE PUZZLE DECODE ERROR: \(error)")
            throw PuzzleError.serverError("Failed to decode adaptive puzzle: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get All Puzzles
    func getPuzzles(parentId: String, kidId: String) async throws -> [PuzzleResponse] {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/puzzles"
        
        guard let url = URL(string: endpoint) else {
            throw PuzzleError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw PuzzleError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PuzzleError.serverError("Failed to fetch puzzles")
        }
        
        let puzzles = try JSONDecoder().decode([PuzzleResponse].self, from: data)
        print("✅ Fetched \(puzzles.count) puzzles")
        
        return puzzles
    }
    
    // MARK: - Get Single Puzzle
    func getPuzzle(parentId: String, kidId: String, puzzleId: String) async throws -> PuzzleResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/puzzles/\(puzzleId)"
        
        guard let url = URL(string: endpoint) else {
            throw PuzzleError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw PuzzleError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PuzzleError.serverError("Failed to fetch puzzle")
        }
        
        return try JSONDecoder().decode(PuzzleResponse.self, from: data)
    }
    
    // MARK: - Submit Puzzle Solution
    func submitSolution(
        parentId: String,
        kidId: String,
        puzzleId: String,
        positions: [Int],
        timeSpent: Int
    ) async throws -> PuzzleSubmitResponse {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/puzzles/\(puzzleId)/submit"
        
        guard let url = URL(string: endpoint) else {
            throw PuzzleError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw PuzzleError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body: [String: Any] = [
            "positions": positions,
            "timeSpent": timeSpent
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🧩 PUZZLE: Submitting solution")
        print("   Puzzle ID: \(puzzleId)")
        print("   Endpoint: \(endpoint)")
        print("   Positions: \(positions)")
        print("   Time Spent: \(timeSpent)s")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("🧩 SUBMIT RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PuzzleError.invalidResponse
        }
        
        print("🧩 SUBMIT STATUS CODE: \(httpResponse.statusCode)")
        
        // Handle different status codes
        if httpResponse.statusCode == 404 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw PuzzleError.serverError("Puzzle not found: \(message)\nPuzzle ID: \(puzzleId)")
            }
            throw PuzzleError.serverError("Puzzle not found (ID: \(puzzleId))")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw PuzzleError.serverError("Submit error: \(message)")
            }
            throw PuzzleError.serverError("Failed to submit solution (Status: \(httpResponse.statusCode))")
        }
        
        let result = try JSONDecoder().decode(PuzzleSubmitResponse.self, from: data)
        print("✅ PUZZLE: Solution submitted - Correct: \(result.isCorrect), Score: \(result.score)")
        
        return result
    }
    
    // MARK: - Delete Puzzle
    func deletePuzzle(parentId: String, kidId: String, puzzleId: String) async throws {
        let endpoint = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/puzzles/\(puzzleId)"
        
        guard let url = URL(string: endpoint) else {
            throw PuzzleError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw PuzzleError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw PuzzleError.serverError("Failed to delete puzzle")
        }
        
        print("✅ Puzzle deleted successfully")
    }
}

// MARK: - Puzzle Error
enum PuzzleError: LocalizedError {
    case invalidURL
    case noToken
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noToken: return "No authentication token"
        case .invalidResponse: return "Invalid response from server"
        case .serverError(let msg): return msg
        }
    }
}
