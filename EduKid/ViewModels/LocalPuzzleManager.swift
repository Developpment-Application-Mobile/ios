//
//  LocalPuzzleManager.swift
//  EduKid
//
//  Created by mac on 22/11/2025.
//
//  Manages puzzles locally when backend has issues
//

import Foundation
import SwiftUI

class LocalPuzzleManager {
    static let shared = LocalPuzzleManager()
    
    private init() {}
    
    // MARK: - Local Puzzle Generation
    func generateLocalPuzzle(for child: Child, type: PuzzleType? = nil, difficulty: PuzzleDifficulty? = nil) -> LocalPuzzle {
        let puzzleType = type ?? getRandomType(for: child.age)
        let puzzleDifficulty = difficulty ?? getDifficulty(for: child.level)
        let gridSize = puzzleDifficulty.gridSize
        
        let puzzle = LocalPuzzle(
            id: UUID().uuidString,
            childId: child.id,
            title: generateTitle(type: puzzleType),
            type: puzzleType,
            difficulty: puzzleDifficulty,
            gridSize: gridSize,
            pieces: generatePieces(type: puzzleType, gridSize: gridSize),
            hint: generateHint(type: puzzleType),
            solution: generateSolution(type: puzzleType),
            isCompleted: false,
            attempts: 0,
            timeSpent: 0,
            score: 0,
            createdAt: Date()
        )
        
        savePuzzle(puzzle)
        return puzzle
    }
    
    // MARK: - Generate Pieces
    private func generatePieces(type: PuzzleType, gridSize: Int) -> [LocalPuzzlePiece] {
        let totalPieces = gridSize * gridSize
        var content: [String] = []
        var imageContent: [String] = []
        
        switch type {
        case .word:
            let words = ["CAT", "DOG", "SUN", "MOON", "STAR", "TREE", "BIRD", "FISH"]
            let word = words.randomElement()!
            content = Array(word).map { String($0) }
            
        case .number:
            content = (1...totalPieces).map { String($0) }
            
        case .sequence:
            let sequences = [
                ["Monday", "Tuesday", "Wednesday", "Thursday"],
                ["Spring", "Summer", "Fall", "Winter"],
                ["Morning", "Noon", "Evening", "Night"],
                ["Red", "Orange", "Yellow", "Green", "Blue"]
            ]
            let sequence = sequences.randomElement()!
            content = Array(sequence.prefix(totalPieces))
            
        case .pattern:
            let patterns = ["🔴", "🔵", "🟢", "🟡", "🟣", "🟠"]
            content = (0..<totalPieces).map { _ in patterns.randomElement()! }
            
        case .image:
            let emojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼"]
            content = (0..<totalPieces).map { _ in emojis.randomElement()! }
            imageContent = content // For image puzzles, use emojis as image content
        }
        
        // Ensure we have enough content
        while content.count < totalPieces {
            content.append("?")
        }
        
        var pieces: [LocalPuzzlePiece] = []
        for i in 0..<totalPieces {
            pieces.append(LocalPuzzlePiece(
                id: i,
                correctPosition: i,
                currentPosition: i,
                content: content[i],
                emoji: type == .image ? content[i] : nil,
                imageUrl: type == .image ? nil : "" // Add imageUrl field
            ))
        }
        
        // Shuffle pieces
        let shuffled = pieces.indices.shuffled()
        for (index, newPos) in shuffled.enumerated() {
            pieces[index].currentPosition = newPos
        }
        
        return pieces
    }
    
    // MARK: - Submit Solution
    func submitSolution(puzzleId: String, positions: [Int], timeSpent: Int) -> LocalPuzzleResult {
        guard var puzzle = getPuzzle(id: puzzleId) else {
            return LocalPuzzleResult(isCorrect: false, score: 0, message: "Puzzle not found")
        }
        
        puzzle.attempts += 1
        puzzle.timeSpent += timeSpent
        
        // Check if correct - compare current positions with correct positions
        let isCorrect = positions == puzzle.pieces.map { $0.correctPosition }
        
        if isCorrect {
            puzzle.isCompleted = true
            puzzle.completedAt = Date()
            
            // Calculate score
            let baseScore = puzzle.difficulty == .hard ? 100 : (puzzle.difficulty == .medium ? 75 : 50)
            let attemptPenalty = max(0, (puzzle.attempts - 1) * 5)
            let timePenalty = min(20, timeSpent / 60)
            puzzle.score = max(10, baseScore - attemptPenalty - timePenalty)
        }
        
        // Update positions
        for (index, pos) in positions.enumerated() {
            if index < puzzle.pieces.count {
                puzzle.pieces[index].currentPosition = pos
            }
        }
        
        savePuzzle(puzzle)
        
        return LocalPuzzleResult(
            isCorrect: isCorrect,
            score: isCorrect ? puzzle.score : 0,
            message: isCorrect ? "🎉 Amazing! Puzzle completed!" : "Not quite right. Try again! 💪"
        )
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
        // Search in all stored puzzles
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
    
    // MARK: - Helpers
    private func generateTitle(type: PuzzleType) -> String {
        switch type {
        case .word: return "Word Puzzle"
        case .number: return "Number Sequence"
        case .sequence: return "Put in Order"
        case .pattern: return "Pattern Match"
        case .image: return "Image Puzzle"
        }
    }
    
    private func generateHint(type: PuzzleType) -> String {
        switch type {
        case .word: return "Arrange the letters to make a word!"
        case .number: return "Put the numbers in order from smallest to largest!"
        case .sequence: return "Put these items in the correct order!"
        case .pattern: return "Match the pattern!"
        case .image: return "Complete the picture!"
        }
    }
    
    private func generateSolution(type: PuzzleType) -> String {
        switch type {
        case .word: return "Spell the word correctly"
        case .number: return "Numbers in ascending order"
        case .sequence: return "Items in logical order"
        case .pattern: return "Pattern completed"
        case .image: return "Image assembled"
        }
    }
    
    private func getRandomType(for age: Int) -> PuzzleType {
        if age <= 5 {
            return [.word, .image].randomElement()!
        } else if age <= 7 {
            return [.word, .number, .image].randomElement()!
        } else {
            return PuzzleType.allCases.randomElement()!
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

// MARK: - Local Puzzle Models
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
    var isCompleted: Bool
    var attempts: Int
    var timeSpent: Int
    var score: Int
    let createdAt: Date
    var completedAt: Date?
    
    var puzzleType: PuzzleType { type }
    var puzzleDifficulty: PuzzleDifficulty { difficulty }
}

struct LocalPuzzlePiece: Codable, Identifiable {
    var id: Int
    var correctPosition: Int
    var currentPosition: Int
    var content: String
    var emoji: String?
    var imageUrl: String? // Add this field
}

struct LocalPuzzleResult {
    let isCorrect: Bool
    let score: Int
    let message: String
}

// MARK: - Local Puzzle Play Screen
struct LocalPuzzlePlayScreen: View {
    let puzzle: LocalPuzzle
    let child: Child
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var pieces: [LocalPuzzlePiece]
    @State private var selectedPieceIndex: Int? = nil
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var result: LocalPuzzleResult?
    
    init(puzzle: LocalPuzzle, child: Child, onComplete: @escaping () -> Void) {
        self.puzzle = puzzle
        self.child = child
        self.onComplete = onComplete
        _pieces = State(initialValue: puzzle.pieces)
    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: puzzle.gridSize)
    }
    
    var sortedPieces: [LocalPuzzlePiece] {
        pieces.sorted { $0.currentPosition < $1.currentPosition }
    }
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .init(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text(formatTime(timeElapsed))
                            .font(.headline.monospacedDigit())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Title
                VStack(spacing: 8) {
                    Text(puzzle.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(puzzle.hint)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Puzzle Grid
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(sortedPieces.indices, id: \.self) { index in
                        let piece = sortedPieces[index]
                        LocalPuzzlePieceView(
                            piece: piece,
                            isSelected: selectedPieceIndex == index,
                            puzzleType: puzzle.type,
                            gridSize: puzzle.gridSize
                        ) {
                            handlePieceTap(at: index)
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Check Button
                Button(action: checkSolution) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Check Solution")
                            .font(.headline)
                    }
                    .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .alert(result?.message ?? "", isPresented: $showResult) {
            Button(result?.isCorrect == true ? "Continue" : "Try Again") {
                if result?.isCorrect == true {
                    onComplete()
                    dismiss()
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func handlePieceTap(at index: Int) {
        if let selected = selectedPieceIndex {
            if selected != index {
                swapPieces(from: selected, to: index)
            }
            selectedPieceIndex = nil
        } else {
            selectedPieceIndex = index
        }
    }
    
    private func swapPieces(from: Int, to: Int) {
        let sortedIndices = sortedPieces.map { piece in
            pieces.firstIndex(where: { $0.id == piece.id })!
        }
        
        let fromIndex = sortedIndices[from]
        let toIndex = sortedIndices[to]
        
        let temp = pieces[fromIndex].currentPosition
        pieces[fromIndex].currentPosition = pieces[toIndex].currentPosition
        pieces[toIndex].currentPosition = temp
    }
    
    private func checkSolution() {
        let positions = sortedPieces.map { $0.currentPosition }
        let result = LocalPuzzleManager.shared.submitSolution(
            puzzleId: puzzle.id,
            positions: positions,
            timeSpent: timeElapsed
        )
        
        self.result = result
        showResult = true
    }
}

// MARK: - Local Puzzle Piece View (FIXED)
struct LocalPuzzlePieceView: View {
    let piece: LocalPuzzlePiece
    let isSelected: Bool
    let puzzleType: PuzzleType
    let gridSize: Int
    let onTap: () -> Void
    
    var pieceSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 80
        return (screenWidth - CGFloat(gridSize - 1) * 8) / CGFloat(gridSize)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? puzzleType.color : Color.white)
                    .shadow(color: isSelected ? puzzleType.color.opacity(0.5) : .clear, radius: 8)
                
                // Handle different content types
                if puzzleType == .image, let emoji = piece.emoji {
                    Text(emoji)
                        .font(.system(size: pieceSize * 0.5))
                } else {
                    Text(piece.content)
                        .font(getFontForGridSize())
                        .fontWeight(.bold) // FIXED: removed parentheses
                        .foregroundColor(isSelected ? .white : puzzleType.color)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .padding(4)
                }
            }
            .frame(width: pieceSize, height: pieceSize)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? puzzleType.color : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
    
    private func getFontForGridSize() -> Font {
        switch gridSize {
        case 2: return .title
        case 3: return .title2
        default: return .headline
        }
    }
}
