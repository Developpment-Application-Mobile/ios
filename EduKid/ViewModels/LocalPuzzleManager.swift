//
//  LocalPuzzleManager.swift
//  EduKid
//
//  FIXED: Support for custom images, proper piece generation
//

import Foundation
import SwiftUI
import UIKit

class LocalPuzzleManager {
    static let shared = LocalPuzzleManager()
    private init() {}
    
    // MARK: - Generate Puzzle with Custom Image Support
    func generateLocalPuzzle(
        for child: Child,
        type: PuzzleType? = nil,
        difficulty: PuzzleDifficulty? = nil,
        puzzleImage: PuzzleImage? = nil,
        customImage: UIImage? = nil
    ) -> LocalPuzzle {
        let puzzleType = type ?? .image
        let puzzleDifficulty = difficulty ?? getDifficulty(for: child.level)
        let gridSize = puzzleDifficulty.gridSize
        let totalPieces = gridSize * gridSize
        
        var savedImagePath: String?
        if let customImage = customImage {
            savedImagePath = saveCustomImage(customImage, childId: child.id)
        }
        
        let image = puzzleImage ?? PuzzleImage.random()
        
        let puzzle = LocalPuzzle(
            id: UUID().uuidString,
            childId: child.id,
            title: generateTitle(type: puzzleType, image: image, hasCustomImage: savedImagePath != nil),
            type: puzzleType,
            difficulty: puzzleDifficulty,
            gridSize: gridSize,
            pieces: generatePieces(type: puzzleType, gridSize: gridSize, totalPieces: totalPieces),
            hint: generateHint(type: puzzleType),
            solution: generateSolution(type: puzzleType),
            puzzleImage: image,
            customImagePath: savedImagePath,
            isCompleted: false,
            attempts: 0,
            timeSpent: 0,
            score: 0,
            createdAt: Date()
        )
        
        savePuzzle(puzzle)
        return puzzle
    }
    
    // MARK: - Save Custom Image
    private func saveCustomImage(_ image: UIImage, childId: String) -> String? {
        // Resize image if too large (max 2048px on longest side)
        let resizedImage = resizeImage(image, maxDimension: 2048)
        
        guard let data = resizedImage.jpegData(compressionQuality: 0.85) else { return nil }
        
        let filename = "puzzle_\(UUID().uuidString).jpg"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Saved custom image: \(filename), size: \(data.count / 1024)KB")
            return filename
        } catch {
            print("❌ Error saving image: \(error)")
            return nil
        }
    }
    
    // MARK: - Resize Image Helper
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSize = max(size.width, size.height)
        
        // If image is already small enough, return as-is
        if maxSize <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let scale = maxDimension / maxSize
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Load Custom Image
    func loadCustomImage(path: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(path)
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Generate Pieces (FIXED for all grid sizes)
    private func generatePieces(type: PuzzleType, gridSize: Int, totalPieces: Int) -> [LocalPuzzlePiece] {
        var content: [String] = []
        
        switch type {
        case .word:
            let words = ["CAT", "DOG", "SUN", "MOON", "STAR", "TREE", "BIRD", "FISH", "FROG", "BEAR",
                        "APPLE", "BANANA", "ORANGE", "GRAPE", "MELON"]
            let word = words.filter { $0.count >= totalPieces }.randomElement() ??
                      (words.filter { $0.count >= gridSize }.randomElement() ?? "CATS")
            content = Array(word.prefix(totalPieces)).map { String($0) }
            
        case .number:
            content = (1...totalPieces).map { String($0) }
            
        case .sequence:
            let sequences = [
                ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue"],
                ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep"],
                ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th"],
                ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"]
            ]
            let seq = sequences.randomElement()!
            content = Array(seq.prefix(totalPieces))
            
        case .pattern:
            let patterns = ["🔴", "🔵", "🟢", "🟡", "🟣", "🟠", "⚫", "⚪"]
            content = (0..<totalPieces).map { patterns[$0 % patterns.count] }
            
        case .image:
            content = (0..<totalPieces).map { "\($0)" }
        }
        
        // Ensure we have exactly totalPieces elements
        while content.count < totalPieces {
            content.append("?")
        }
        content = Array(content.prefix(totalPieces))
        
        // Create pieces with correct positions
        var pieces: [LocalPuzzlePiece] = []
        for i in 0..<totalPieces {
            pieces.append(LocalPuzzlePiece(
                id: i,
                correctPosition: i,
                currentPosition: i,
                content: content[i],
                emoji: type == .pattern ? content[i] : nil,
                imageUrl: nil
            ))
        }
        
        // Shuffle positions (Fisher-Yates)
        var positions = Array(0..<totalPieces)
        for i in (1..<positions.count).reversed() {
            let j = Int.random(in: 0...i)
            positions.swapAt(i, j)
        }
        
        for (index, piece) in pieces.enumerated() {
            pieces[index].currentPosition = positions[index]
        }
        
        return pieces
    }
    
    // MARK: - Update Puzzle
    func updatePuzzle(_ puzzle: LocalPuzzle) {
        savePuzzle(puzzle)
    }
    
    // MARK: - Storage
    private func savePuzzle(_ puzzle: LocalPuzzle) {
        var puzzles = getAllPuzzles(for: puzzle.childId)
        if let index = puzzles.firstIndex(where: { $0.id == puzzle.id }) {
            puzzles[index] = puzzle
        } else {
            puzzles.append(puzzle)
        }
        
        if let data = try? JSONEncoder().encode(puzzles) {
            UserDefaults.standard.set(data, forKey: "local_puzzles_\(puzzle.childId)")
        }
    }
    
    func getAllPuzzles(for childId: String) -> [LocalPuzzle] {
        guard let data = UserDefaults.standard.data(forKey: "local_puzzles_\(childId)"),
              let puzzles = try? JSONDecoder().decode([LocalPuzzle].self, from: data) else {
            return []
        }
        return puzzles.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getPuzzle(id: String) -> LocalPuzzle? {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.starts(with: "local_puzzles_") {
            if let data = UserDefaults.standard.data(forKey: key),
               let puzzles = try? JSONDecoder().decode([LocalPuzzle].self, from: data),
               let puzzle = puzzles.first(where: { $0.id == id }) {
                return puzzle
            }
        }
        return nil
    }
    
    func deletePuzzle(id: String, childId: String) {
        var puzzles = getAllPuzzles(for: childId)
        
        // Delete custom image if exists
        if let puzzle = puzzles.first(where: { $0.id == id }),
           let imagePath = puzzle.customImagePath {
            deleteCustomImage(path: imagePath)
        }
        
        puzzles.removeAll { $0.id == id }
        
        if let data = try? JSONEncoder().encode(puzzles) {
            UserDefaults.standard.set(data, forKey: "local_puzzles_\(childId)")
        }
    }
    
    private func deleteCustomImage(path: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(path)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Helpers
    private func generateTitle(type: PuzzleType, image: PuzzleImage, hasCustomImage: Bool = false) -> String {
        if hasCustomImage {
            return "My Photo Puzzle"
        }
        
        switch type {
        case .image: return "\(image.displayName) Puzzle"
        case .word: return "Word Puzzle"
        case .number: return "Number Puzzle"
        case .sequence: return "Sequence Puzzle"
        case .pattern: return "Pattern Puzzle"
        }
    }
    
    private func generateHint(type: PuzzleType) -> String {
        switch type {
        case .image: return "Put the picture pieces together!"
        case .word: return "Arrange the letters to spell the word!"
        case .number: return "Put numbers in order!"
        case .sequence: return "Put items in the correct order!"
        case .pattern: return "Complete the pattern!"
        }
    }
    
    private func generateSolution(type: PuzzleType) -> String {
        switch type {
        case .image: return "Complete the picture"
        case .word: return "Spell the word correctly"
        case .number: return "Numbers in order"
        case .sequence: return "Items in logical order"
        case .pattern: return "Pattern completed"
        }
    }
    
    private func getDifficulty(for level: String) -> PuzzleDifficulty {
        switch level.lowercased() {
        case "advanced", "3": return .hard
        case "intermediate", "2": return .medium
        default: return .easy
        }
    }
}
