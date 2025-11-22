//
//  PuzzlePlayScreen.swift
//  EduKid
//
//  Created by mac on 22/11/2025.
//

import SwiftUI

struct PuzzlePlayScreen: View {
    let puzzle: PuzzleResponse
    let child: Child
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var pieces: [PuzzlePiece] = []
    @State private var selectedPieceIndex: Int? = nil
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer?
    @State private var showHint = false
    @State private var isSubmitting = false
    @State private var submitResult: PuzzleSubmitResponse?
    @State private var showResult = false
    @State private var attempts = 0
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: puzzle.gridSize)
    }
    
    var body: some View {
        ZStack {
            // Background
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
                    
                    // Timer
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
                    
                    // Hint Button
                    Button(action: { showHint.toggle() }) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Title
                VStack(spacing: 8) {
                    Text(puzzle.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Label(puzzle.puzzleType.displayName, systemImage: puzzle.puzzleType.icon)
                        Label(puzzle.puzzleDifficulty.displayName, systemImage: "star.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                }
                
                // Hint
                if showHint, let hint = puzzle.hint, !hint.isEmpty {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(hint)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Puzzle Grid
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(sortedPieces.indices, id: \.self) { index in
                        let piece = sortedPieces[index]
                        PuzzlePieceView(
                            piece: piece,
                            isSelected: selectedPieceIndex == index,
                            puzzleType: puzzle.puzzleType,
                            gridSize: puzzle.gridSize,
                            puzzleTitle: puzzle.title
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
                
                // Attempts counter
                Text("Attempts: \(attempts)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                // Check Solution Button
                Button(action: submitSolution) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.153, green: 0.125, blue: 0.322)))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isSubmitting ? "Checking..." : "Check Solution")
                            .font(.headline)
                    }
                    .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .disabled(isSubmitting)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupPuzzle()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            if let result = submitResult {
                PuzzleResultScreen(
                    result: result,
                    timeElapsed: timeElapsed,
                    onDismiss: {
                        showResult = false
                        if result.isCorrect {
                            onComplete()
                            dismiss()
                        }
                    }
                )
            }
        }
    }
    
    // Pieces sorted by current position
    var sortedPieces: [PuzzlePiece] {
        pieces.sorted { $0.currentPosition < $1.currentPosition }
    }
    
    private func setupPuzzle() {
        pieces = puzzle.pieces
        print("🧩 PUZZLE SETUP:")
        print("   Title: \(puzzle.title)")
        print("   Type: \(puzzle.type)")
        print("   Pieces: \(puzzle.pieces.map { $0.content })")
        
        // Debug each piece conversion
        for (index, piece) in puzzle.pieces.enumerated() {
            let testEmoji = convertToEmojiForDebug(piece.content, puzzleTitle: puzzle.title, puzzleType: puzzle.puzzleType)
            print("   Piece \(index): '\(piece.content)' → '\(testEmoji)'")
        }
    }

    // Helper function for debugging emoji conversion
    private func convertToEmojiForDebug(_ content: String, puzzleTitle: String, puzzleType: PuzzleType) -> String {
        // Use the same logic as in PuzzlePieceView
        let lowerTitle = puzzleTitle.lowercased()
        let lowerContent = content.lowercased()
        
        // Sports-themed content
        if lowerContent.contains("football") || lowerContent.contains("soccer") {
            return "⚽"
        } else if lowerContent.contains("basketball") {
            return "🏀"
        }
        
        // Add other conversion logic here...
        
        return content // Return original if no conversion
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
            // Swap pieces
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
        
        let fromPieceIndex = sortedIndices[from]
        let toPieceIndex = sortedIndices[to]
        
        let tempPosition = pieces[fromPieceIndex].currentPosition
        pieces[fromPieceIndex].currentPosition = pieces[toPieceIndex].currentPosition
        pieces[toPieceIndex].currentPosition = tempPosition
    }
    
    private func submitSolution() {
        isSubmitting = true
        attempts += 1
        
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                
                // Get current positions in order
                let positions = sortedPieces.map { $0.currentPosition }
                
                // Check if puzzle has temporary ID - if so, use local validation
                if puzzle.hasTemporaryId {
                    print("🧩 PUZZLE: Using local validation for temporary puzzle")
                    let isCorrect = positions == puzzle.pieces.map { $0.correctPosition }
                    
                    await MainActor.run {
                        isSubmitting = false
                        submitResult = PuzzleSubmitResponse(
                            puzzle: puzzle,
                            isCorrect: isCorrect,
                            score: isCorrect ? 100 : 0,
                            attempts: attempts,
                            message: isCorrect ? "🎉 Amazing! Puzzle completed!" : "Not quite right. Try again! 💪"
                        )
                        showResult = true
                    }
                } else {
                    // Use backend submission for real puzzles
                    let result = try await PuzzleService.shared.submitSolution(
                        parentId: parentId,
                        kidId: child.id,
                        puzzleId: puzzle.id,
                        positions: positions,
                        timeSpent: timeElapsed
                    )
                    
                    await MainActor.run {
                        isSubmitting = false
                        submitResult = result
                        showResult = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("Error submitting solution: \(error)")
                    
                    // Fallback to local validation if backend fails
                    let positions = sortedPieces.map { $0.currentPosition }
                    let isCorrect = positions == puzzle.pieces.map { $0.correctPosition }
                    
                    submitResult = PuzzleSubmitResponse(
                        puzzle: puzzle,
                        isCorrect: isCorrect,
                        score: isCorrect ? 100 : 0,
                        attempts: attempts,
                        message: isCorrect ? "🎉 Amazing! Puzzle completed!" : "Not quite right. Try again! 💪"
                    )
                    showResult = true
                }
            }
        }
    }
}

// MARK: - Puzzle Piece View with Auto-Emoji Conversion
// MARK: - Puzzle Piece View with Universal Emoji Support
struct PuzzlePieceView: View {
    let piece: PuzzlePiece
    let isSelected: Bool
    let puzzleType: PuzzleType
    let gridSize: Int
    let puzzleTitle: String
    let onTap: () -> Void
    
    var pieceSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 80
        return (screenWidth - CGFloat(gridSize - 1) * 8) / CGFloat(gridSize)
    }
    
    // Get the display content (auto-convert to emoji if possible)
    private var displayContent: String {
        // If it's already an emoji, use it as is
        if piece.content.isSingleEmoji {
            return piece.content
        }
        
        // Try to convert text to emoji for ALL puzzle types
        return convertToEmoji(piece.content, puzzleTitle: puzzleTitle, puzzleType: puzzleType)
    }
    
    // Check if we should display as emoji/image
    private var shouldShowAsEmoji: Bool {
        // Show as emoji if:
        // 1. It's already an emoji
        // 2. We successfully converted it to an emoji
        // 3. It's a single character that can be represented as emoji
        return piece.content.isSingleEmoji || displayContent.isSingleEmoji || piece.content.count == 1
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? puzzleType.color : Color.white)
                    .shadow(color: isSelected ? puzzleType.color.opacity(0.5) : .clear, radius: 8)
                
                // Content
                if shouldShowAsEmoji {
                    // Show as emoji/image
                    Text(displayContent)
                        .font(.system(size: pieceSize * 0.5))
                        .minimumScaleFactor(0.5)
                } else {
                    // Show as text
                    Text(displayContent)
                        .font(getFontForGridSize())
                        .fontWeight(.bold)
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
    
    // Convert text content to appropriate emoji based on puzzle title, content, and type
    private func convertToEmoji(_ content: String, puzzleTitle: String, puzzleType: PuzzleType) -> String {
        let lowerTitle = puzzleTitle.lowercased()
        let lowerContent = content.lowercased()
        
        print("🧩 Converting to emoji: '\(content)' from puzzle '\(puzzleTitle)' type: \(puzzleType)")
        
        // Sports-themed content
        if lowerContent.contains("football") || lowerContent.contains("soccer") {
            return "⚽"
        } else if lowerContent.contains("basketball") {
            return "🏀"
        } else if lowerContent.contains("tennis") {
            return "🎾"
        } else if lowerContent.contains("baseball") {
            return "⚾"
        } else if lowerContent.contains("volleyball") {
            return "🏐"
        }
        
        // Animal-themed content
        if lowerContent.contains("cat") {
            return "🐱"
        } else if lowerContent.contains("dog") {
            return "🐶"
        } else if lowerContent.contains("bird") {
            return "🐦"
        } else if lowerContent.contains("fish") {
            return "🐠"
        } else if lowerContent.contains("lion") {
            return "🦁"
        } else if lowerContent.contains("tiger") {
            return "🐯"
        } else if lowerContent.contains("bear") {
            return "🐻"
        } else if lowerContent.contains("rabbit") || lowerContent.contains("bunny") {
            return "🐰"
        }
        
        // Food-themed content
        if lowerContent.contains("apple") {
            return "🍎"
        } else if lowerContent.contains("banana") {
            return "🍌"
        } else if lowerContent.contains("orange") {
            return "🍊"
        } else if lowerContent.contains("grape") {
            return "🍇"
        } else if lowerContent.contains("strawberry") {
            return "🍓"
        } else if lowerContent.contains("watermelon") {
            return "🍉"
        } else if lowerContent.contains("pizza") {
            return "🍕"
        } else if lowerContent.contains("burger") || lowerContent.contains("hamburger") {
            return "🍔"
        } else if lowerContent.contains("ice cream") {
            return "🍦"
        } else if lowerContent.contains("cake") {
            return "🍰"
        }
        
        // Shape and color content
        if lowerContent.contains("circle") || lowerContent.contains("round") {
            return "⭕"
        } else if lowerContent.contains("square") {
            return "⬜"
        } else if lowerContent.contains("triangle") {
            return "🔺"
        } else if lowerContent.contains("star") {
            return "⭐"
        } else if lowerContent.contains("heart") {
            return "❤️"
        }
        
        if lowerContent.contains("red") {
            return "🔴"
        } else if lowerContent.contains("blue") {
            return "🔵"
        } else if lowerContent.contains("green") {
            return "🟢"
        } else if lowerContent.contains("yellow") {
            return "🟡"
        } else if lowerContent.contains("purple") {
            return "🟣"
        } else if lowerContent.contains("orange") {
            return "🟠"
        }
        
        // Number content
        if puzzleType == .number {
            let numberEmojis = ["1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟"]
            if let number = Int(content), number > 0 && number <= numberEmojis.count {
                return numberEmojis[number - 1]
            }
            return numberEmojis.randomElement() ?? "🔢"
        }
        
        // Single letter content (like "C", "A", "T")
        if content.count == 1 {
            let letter = content.uppercased()
            let letterEmojis: [String: String] = [
                "A": "🅰️", "B": "🅱️", "C": "©️", "D": "🇩", "E": "🇪",
                "F": "🇫", "G": "🇬", "H": "🇭", "I": "ℹ️", "J": "🇯",
                "K": "🇰", "L": "🇱", "M": "Ⓜ️", "N": "🇳", "O": "⭕",
                "P": "🅿️", "Q": "🧩", "R": "®️", "S": "💲", "T": "✝️",
                "U": "🇺", "V": "✅", "W": "〰️", "X": "❌", "Y": "🇾", "Z": "💤"
            ]
            return letterEmojis[letter] ?? "🔤"
        }
        
        // Question mark
        if content == "?" {
            return "❓"
        }
        
        // Default fallback based on puzzle type
        switch puzzleType {
        case .image:
            let imageEmojis = ["🖼️", "🎨", "📷", "🖌️", "🎭", "🌟", "✨", "💫"]
            return imageEmojis.randomElement() ?? "🖼️"
        case .word:
            let wordEmojis = ["🔤", "📝", "📚", "✏️", "🆎", "💬", "🗨️"]
            return wordEmojis.randomElement() ?? "🔤"
        case .number:
            let numberEmojis = ["🔢", "123️⃣", "➗", "✖️", "➕", "➖", "💯"]
            return numberEmojis.randomElement() ?? "🔢"
        case .sequence:
            let sequenceEmojis = ["🔁", "➡️", "⏩", "🔄", "📈", "🔼"]
            return sequenceEmojis.randomElement() ?? "🔁"
        case .pattern:
            let patternEmojis = ["🔄", "♻️", "💠", "🔶", "🔷", "🎯", "🎪"]
            return patternEmojis.randomElement() ?? "🔄"
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



// MARK: - Puzzle Result Screen
struct PuzzleResultScreen: View {
    let result: PuzzleSubmitResponse
    let timeElapsed: Int
    let onDismiss: () -> Void
    
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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Result Icon
                Text(result.isCorrect ? "🎉" : "🤔")
                    .font(.system(size: 100))
                
                Text(result.isCorrect ? "Puzzle Solved!" : "Not Quite Right")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(result.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                if result.isCorrect {
                    // Stats
                    VStack(spacing: 16) {
                        StatRow(icon: "star.fill", label: "Score", value: "\(result.score)", color: .yellow)
                        StatRow(icon: "clock.fill", label: "Time", value: formatTime(timeElapsed), color: .blue)
                        StatRow(icon: "arrow.counterclockwise", label: "Attempts", value: "\(result.attempts)", color: .orange)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text(result.isCorrect ? "Continue" : "Try Again")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}



// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
