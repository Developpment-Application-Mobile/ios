//
//  PuzzlePlayScreen.swift
//  EduKid
//
//  FIXED: Score display for AI puzzles, sound effects
//

import SwiftUI

struct PuzzlePlayScreen: View {
    let puzzle: PuzzleResponse
    let child: Child
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var pieces: [PuzzlePiece] = []
    @State private var selectedIndex: Int?
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var attempts = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var finalScore = 0
    
    private var gridSize: Int { puzzle.gridSize }
    private var totalPieces: Int { gridSize * gridSize }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.3, green: 0.5, blue: 0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 50, height: 50)
                            Image(systemName: "xmark")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.yellow)
                        Text(timeString)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white.opacity(0.25)))
                    
                    Spacer()
                    
                    Button { } label: {
                        ZStack {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 50, height: 50)
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Text(puzzle.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                
                Spacer()
                
                // Puzzle Grid - FIXED for all grid sizes
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let spacing: CGFloat = 8
                    let totalSpacing = spacing * CGFloat(gridSize + 1)
                    let pieceSize = (availableWidth - totalSpacing) / CGFloat(gridSize)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.2))
                            .shadow(color: .black.opacity(0.2), radius: 20)
                        
                        VStack(spacing: spacing) {
                            ForEach(0..<gridSize, id: \.self) { row in
                                HStack(spacing: spacing) {
                                    ForEach(0..<gridSize, id: \.self) { col in
                                        let displayIndex = row * gridSize + col
                                        if displayIndex < sortedPieces.count {
                                            let piece = sortedPieces[displayIndex]
                                            ImprovedPuzzlePieceView(
                                                piece: piece,
                                                isSelected: selectedIndex == displayIndex,
                                                puzzleType: puzzle.puzzleType,
                                                gridSize: gridSize,
                                                pieceSize: pieceSize
                                            ) {
                                                handleTap(at: displayIndex)
                                                PuzzleSoundManager.shared.playPiecePlaced()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(spacing)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        StatPill(icon: "hand.tap.fill", value: "\(attempts)", label: "Tries")
                        StatPill(icon: "puzzlepiece.fill", value: "\(matchedCount)/\(pieces.count)", label: "Placed")
                    }
                    
                    Button(action: checkSolution) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Check Puzzle")
                                .font(.title3.bold())
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        )
                    }
                    .padding(.horizontal, 40)
                }
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
            PuzzleResultScreen(
                isCorrect: isCorrect,
                timeElapsed: timeElapsed,
                attempts: attempts,
                score: finalScore
            ) {
                showResult = false
                if isCorrect {
                    PuzzleSoundManager.shared.playSuccess()
                    onComplete()
                }
            }
        }
    }
    
    private var timeString: String {
        String(format: "%02d:%02d", timeElapsed / 60, timeElapsed % 60)
    }
    
    private var sortedPieces: [PuzzlePiece] {
        let sorted = pieces.sorted { $0.currentPosition < $1.currentPosition }
        return Array(sorted.prefix(totalPieces))
    }
    
    private var matchedCount: Int {
        pieces.filter { $0.currentPosition == $0.correctPosition }.count
    }
    
    private func setupPuzzle() {
        // FIXED: Ensure we have exactly gridSize² pieces
        pieces = Array(puzzle.pieces.prefix(totalPieces))
        
        // Ensure we have exactly the right number of pieces
        while pieces.count < totalPieces {
            pieces.append(PuzzlePiece(
                id: pieces.count,
                correctPosition: pieces.count,
                currentPosition: pieces.count,
                content: "\(pieces.count + 1)",
                imageUrl: nil
            ))
        }
        
        // Shuffle if not already shuffled
        if pieces.allSatisfy({ $0.currentPosition == $0.correctPosition }) {
            let shuffled = Array(0..<totalPieces).shuffled()
            for (index, newPos) in shuffled.enumerated() {
                if index < pieces.count {
                    pieces[index].currentPosition = newPos
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func handleTap(at displayIndex: Int) {
        if let selected = selectedIndex, selected != displayIndex {
            swapPieces(displayIndex1: selected, displayIndex2: displayIndex)
            selectedIndex = nil
        } else if selectedIndex == displayIndex {
            selectedIndex = nil
        } else {
            selectedIndex = displayIndex
        }
    }
    
    private func swapPieces(displayIndex1: Int, displayIndex2: Int) {
        guard displayIndex1 < sortedPieces.count && displayIndex2 < sortedPieces.count else { return }
        let piece1 = sortedPieces[displayIndex1]
        let piece2 = sortedPieces[displayIndex2]
        
        guard
            let i1 = pieces.firstIndex(where: { $0.id == piece1.id }),
            let i2 = pieces.firstIndex(where: { $0.id == piece2.id })
        else { return }
        
        let temp = pieces[i1].currentPosition
        pieces[i1].currentPosition = pieces[i2].currentPosition
        pieces[i2].currentPosition = temp
    }
    
    private func checkSolution() {
        attempts += 1
        isCorrect = sortedPieces.enumerated().allSatisfy { index, piece in
            piece.correctPosition == index
        }
        
        if isCorrect {
            savePuzzleResult()
        } else {
            showResult = true
        }
    }
    
    private func calculateScore() -> Int {
        let baseScore = puzzle.difficulty == "hard" ? 100 : (puzzle.difficulty == "medium" ? 75 : 50)
        let timePenalty = min(20, timeElapsed / 60)
        let attemptsPenalty = max(0, (attempts - 1) * 5)
        return max(10, baseScore - timePenalty - attemptsPenalty)
    }
    
    private func savePuzzleResult() {
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else {
                    await MainActor.run {
                        finalScore = calculateScore()
                        showResult = true
                    }
                    return
                }
                
                // Submit to backend and get score
                let result = try await PuzzleService.shared.submitSolution(
                    parentId: parentId,
                    kidId: child.id,
                    puzzleId: puzzle.id,
                    positions: sortedPieces.map { $0.currentPosition },
                    timeSpent: timeElapsed
                )
                
                await MainActor.run {
                    finalScore = result.score
                    
                    // Save to games UserDefaults for unified results view
                    var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
                    games.append([
                        "type": "puzzle",
                        "title": puzzle.title,
                        "difficulty": puzzle.difficulty,
                        "score": result.score,
                        "attempts": attempts,
                        "time": timeElapsed,
                        "date": ISO8601DateFormatter().string(from: Date())
                    ])
                    UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
                    
                    showResult = true
                }
            } catch {
                print("Failed to save puzzle result: \(error)")
                // Fallback to local calculation
                await MainActor.run {
                    finalScore = calculateScore()
                    
                    // Still save to games even if server fails
                    var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
                    games.append([
                        "type": "puzzle",
                        "title": puzzle.title,
                        "difficulty": puzzle.difficulty,
                        "score": finalScore,
                        "attempts": attempts,
                        "time": timeElapsed,
                        "date": ISO8601DateFormatter().string(from: Date())
                    ])
                    UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
                    
                    showResult = true
                }
            }
        }
    }
}

// MARK: - Improved Puzzle Piece View
struct ImprovedPuzzlePieceView: View {
    let piece: PuzzlePiece
    let isSelected: Bool
    let puzzleType: PuzzleType
    let gridSize: Int
    let pieceSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [.yellow, .orange] : [.white, Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? .yellow.opacity(0.6) : .black.opacity(0.2),
                        radius: isSelected ? 12 : 6
                    )
                
                PieceContentView(piece: piece, puzzleType: puzzleType, size: pieceSize)
                    .padding(6)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.yellow : Color.black.opacity(0.1),
                        lineWidth: isSelected ? 4 : 2
                    )
            }
            .frame(width: pieceSize, height: pieceSize)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .zIndex(isSelected ? 100 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Piece Content View
struct PieceContentView: View {
    let piece: PuzzlePiece
    let puzzleType: PuzzleType
    let size: CGFloat
    
    var body: some View {
        Group {
            if let imageUrl = piece.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipped()
                    case .failure:
                        FallbackContent(piece: piece, puzzleType: puzzleType, size: size)
                    @unknown default:
                        FallbackContent(piece: piece, puzzleType: puzzleType, size: size)
                    }
                }
            } else if piece.isEmoji {
                Text(piece.content)
                    .font(.system(size: size * 0.5))
                    .frame(width: size, height: size)
            } else {
                FallbackContent(piece: piece, puzzleType: puzzleType, size: size)
            }
        }
    }
}

// MARK: - Fallback Content
struct FallbackContent: View {
    let piece: PuzzlePiece
    let puzzleType: PuzzleType
    let size: CGFloat
    
    var body: some View {
        Text(piece.displayText)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(puzzleType.color)
            .frame(width: size, height: size)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.4)
            .lineLimit(2)
    }
    
    private var fontSize: CGFloat {
        let text = piece.displayText
        if text.count <= 2 {
            return size * 0.5
        } else if text.count <= 5 {
            return size * 0.35
        } else {
            return size * 0.25
        }
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                Text(label)
                    .font(.caption)
                    .opacity(0.8)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
}
