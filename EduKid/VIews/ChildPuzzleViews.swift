//
//  ChildPuzzleViews.swift
//  EduKid
//
//  FULLY FIXED: All puzzle pieces display, custom images work
//

import SwiftUI
import AVFoundation

// MARK: - Sound Manager
class PuzzleSoundManager {
    static let shared = PuzzleSoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    func playSuccess() {
        AudioServicesPlaySystemSound(1057)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(1054)
        }
    }
    
    func playPiecePlaced() {
        AudioServicesPlaySystemSound(1104)
    }
}

// MARK: - Child Puzzle Content View
struct ChildPuzzleContentView: View {
    let child: Child
    let onPuzzleCompleted: () -> Void
    
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var selectedLocalPuzzle: LocalPuzzle?
    @State private var selectedServerPuzzle: PuzzleResponse?
    @State private var isLoading = false
    
    var pendingLocalPuzzles: [LocalPuzzle] { localPuzzles.filter { !$0.isCompleted } }
    var completedLocalPuzzles: [LocalPuzzle] { localPuzzles.filter { $0.isCompleted } }
    // FIXED: Filter out AI puzzles with images
    var pendingServerPuzzles: [PuzzleResponse] {
        serverPuzzles.filter { !$0.isCompleted && $0.type.lowercased() != "image" }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).frame(height: 200)
            } else if pendingLocalPuzzles.isEmpty && pendingServerPuzzles.isEmpty && completedLocalPuzzles.isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 40)
                    Text("🧩").font(.system(size: 80))
                    Text("No puzzles yet!").font(.title2.bold()).foregroundColor(.white)
                    Text("Ask your parent to create some puzzles for you!")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center).padding(.horizontal)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if !pendingLocalPuzzles.isEmpty || !pendingServerPuzzles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ChildSectionHeader(title: "Ready to Play!", icon: "play.circle.fill")
                                ForEach(pendingLocalPuzzles) { puzzle in
                                    ChildPuzzleCard(puzzle: puzzle) { selectedLocalPuzzle = puzzle }
                                }
                                ForEach(pendingServerPuzzles) { puzzle in
                                    ChildServerPuzzleCard(puzzle: puzzle) { selectedServerPuzzle = puzzle }
                                }
                            }
                        }
                        if !completedLocalPuzzles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ChildSectionHeader(title: "Completed ⭐", icon: "checkmark.circle.fill")
                                ForEach(completedLocalPuzzles) { puzzle in
                                    ChildCompletedPuzzleCard(puzzle: puzzle)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { loadPuzzles() }
        .fullScreenCover(item: $selectedLocalPuzzle) { puzzle in
            ImagePuzzlePlayScreen(puzzle: puzzle, child: child) {
                selectedLocalPuzzle = nil
                loadPuzzles()
                onPuzzleCompleted()
            }
        }
        .fullScreenCover(item: $selectedServerPuzzle) { puzzle in
            PuzzlePlayScreen(puzzle: puzzle, child: child) {
                selectedServerPuzzle = nil
                loadPuzzles()
                onPuzzleCompleted()
            }
        }
    }
    
    private func loadPuzzles() {
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        Task {
            isLoading = true
            do {
                guard let parentId = AuthService.shared.getParentId() else { return }
                let fetched = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
                await MainActor.run { serverPuzzles = fetched; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}

// MARK: - Child Section Header
struct ChildSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title).font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Child Puzzle Card - FIXED to show custom image thumbnail
struct ChildPuzzleCard: View {
    let puzzle: LocalPuzzle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(puzzle.customImagePath != nil ? Color.gray.opacity(0.3) : puzzle.puzzleImage.backgroundColor)
                        .frame(width: 80, height: 80)
                    
                    if let imagePath = puzzle.customImagePath,
                       let customImage = LocalPuzzleManager.shared.loadCustomImage(path: imagePath) {
                        Image(uiImage: customImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text(puzzle.puzzleImage.emoji).font(.system(size: 50))
                    }
                    
                    VStack(spacing: 0) {
                        ForEach(0..<puzzle.gridSize, id: \.self) { _ in
                            HStack(spacing: 0) {
                                ForEach(0..<puzzle.gridSize, id: \.self) { _ in
                                    Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            }
                        }
                    }
                    .frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Circle().fill(Color(red: 0.1, green: 0.2, blue: 0.4)).frame(width: 20, height: 20).offset(x: 25, y: -25)
                }
                .shadow(color: puzzle.puzzleImage.backgroundColor.opacity(0.5), radius: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(puzzle.title).font(.headline.bold()).foregroundColor(.white)
                    HStack(spacing: 12) {
                        Label("\(puzzle.gridSize)×\(puzzle.gridSize)", systemImage: "square.grid.2x2").font(.caption).foregroundColor(.white.opacity(0.7))
                        Text(puzzle.difficulty.displayName).font(.caption.bold()).foregroundColor(puzzle.difficulty.color)
                            .padding(.horizontal, 8).padding(.vertical, 4).background(puzzle.difficulty.color.opacity(0.2)).cornerRadius(6)
                    }
                }
                Spacer()
                ZStack {
                    Circle().fill(LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 50, height: 50)
                    Image(systemName: "play.fill").font(.title3).foregroundColor(.white)
                }
            }
            .padding(16)
            .background(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(20)
        }
    }
}

// MARK: - Child Server Puzzle Card
struct ChildServerPuzzleCard: View {
    let puzzle: PuzzleResponse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(puzzle.puzzleType.color.opacity(0.3)).frame(width: 80, height: 80)
                    Image(systemName: puzzle.puzzleType.icon).font(.system(size: 36)).foregroundColor(puzzle.puzzleType.color)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(puzzle.title).font(.headline.bold()).foregroundColor(.white)
                    HStack(spacing: 12) {
                        Label("\(puzzle.gridSize)×\(puzzle.gridSize)", systemImage: "square.grid.2x2").font(.caption).foregroundColor(.white.opacity(0.7))
                        Text(puzzle.puzzleDifficulty.displayName).font(.caption.bold()).foregroundColor(puzzle.puzzleDifficulty.color)
                            .padding(.horizontal, 8).padding(.vertical, 4).background(puzzle.puzzleDifficulty.color.opacity(0.2)).cornerRadius(6)
                    }
                }
                Spacer()
                Image(systemName: "play.circle.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.8))
            }
            .padding(16).background(Color.white.opacity(0.15)).cornerRadius(20)
        }
    }
}

// MARK: - Child Completed Puzzle Card
struct ChildCompletedPuzzleCard: View {
    let puzzle: LocalPuzzle
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(puzzle.puzzleImage.backgroundColor.opacity(0.5)).frame(width: 60, height: 60)
                
                if let imagePath = puzzle.customImagePath,
                   let customImage = LocalPuzzleManager.shared.loadCustomImage(path: imagePath) {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(puzzle.puzzleImage.emoji).font(.system(size: 32))
                }
                
                Circle().fill(Color.green).frame(width: 20, height: 20)
                    .overlay(Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(.white)).offset(x: 22, y: -22)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(puzzle.title).font(.subheadline.bold()).foregroundColor(.white)
                HStack(spacing: 8) {
                    Label("\(puzzle.attempts) tries", systemImage: "hand.tap")
                    Label(formatTime(puzzle.timeSpent), systemImage: "clock")
                }
                .font(.caption).foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            VStack(spacing: 4) {
                Text("⭐").font(.title3)
                Text("\(puzzle.score)").font(.headline.bold()).foregroundColor(.yellow)
            }
        }
        .padding(12).background(Color.white.opacity(0.1)).cornerRadius(16)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Image Puzzle Play Screen - FULLY FIXED
struct ImagePuzzlePlayScreen: View {
    let puzzle: LocalPuzzle
    let child: Child
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var pieces: [ImagePuzzlePieceData] = []
    @State private var selectedIndex: Int? = nil
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var attempts = 0
    @State private var showingPreview = true // Show solved puzzle first
    
    private var gridSize: Int { puzzle.gridSize }
    private var totalPieces: Int { gridSize * gridSize }
    
    // FIXED: Always return exactly gridSize² pieces
    private var displayPieces: [ImagePuzzlePieceData] {
        // During preview, show pieces in correct order
        if showingPreview {
            return pieces.sorted { $0.correctPosition < $1.correctPosition }
        }
        // During gameplay, show pieces in current shuffled order
        return pieces.sorted { $0.currentPosition < $1.currentPosition }
    }
    
    private var matchedCount: Int { pieces.filter { $0.currentPosition == $0.correctPosition }.count }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 0.9)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.3)).frame(width: 50, height: 50)
                            Image(systemName: "xmark").font(.title2.bold()).foregroundColor(.white)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill").foregroundColor(.yellow)
                        Text(formatTime(timeElapsed)).font(.title2.bold().monospacedDigit()).foregroundColor(.white)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12).background(Capsule().fill(Color.white.opacity(0.25)))
                    Spacer()
                    Button { } label: {
                        ZStack {
                            Circle().fill(Color.yellow).frame(width: 50, height: 50)
                            Image(systemName: "lightbulb.fill").font(.title2).foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 60)
                
                Text(puzzle.title).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white).shadow(radius: 4)
                
                Spacer()
                
                // FIXED: Puzzle Grid
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let spacing: CGFloat = 0 // Zero spacing for interlocking pieces
                    let totalSpacing = spacing * CGFloat(gridSize + 1)
                    let pieceSize = (availableWidth - totalSpacing) / CGFloat(gridSize)
                    
                    VStack(spacing: spacing) {
                        ForEach(0..<gridSize, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<gridSize, id: \.self) { col in
                                    let index = row * gridSize + col
                                    if index < displayPieces.count {
                                        CustomImageJigsawPiece(
                                            piece: displayPieces[index],
                                            isSelected: selectedIndex == index,
                                            gridSize: gridSize,
                                            row: row,
                                            col: col,
                                            puzzle: puzzle,
                                            pieceSize: pieceSize
                                        ) {
                                            handleTap(at: index)
                                            SoundEffectManager.shared.playPop()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .aspectRatio(1, contentMode: .fit).padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        PuzzleStatPill(icon: "hand.tap.fill", value: "\(attempts)", label: "Tries")
                        PuzzleStatPill(icon: "puzzlepiece.fill", value: "\(matchedCount)/\(totalPieces)", label: "Placed")
                    }
                    Button(action: checkSolution) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill").font(.title2)
                            Text("Check Puzzle").font(.title3.bold())
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.15), radius: 8, y: 4))
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
            
            // Preview Overlay
            if showingPreview {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("🎯")
                            .font(.system(size: 60))
                        Text("Remember this!")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Text("Puzzle will shuffle in...")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(3 - timeElapsed)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .animation(.spring(), value: timeElapsed)
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear { 
            setupPuzzle()
            startPreview()
        }
        .onDisappear { timer?.invalidate() }
        .fullScreenCover(isPresented: $showResult) {
            PuzzleResultScreen(isCorrect: isCorrect, timeElapsed: timeElapsed, attempts: attempts, score: calculateScore()) {
                showResult = false
                if isCorrect {
                    PuzzleSoundManager.shared.playSuccess()
                    savePuzzleResult()
                    onComplete()
                }
            }
        }
    }
    
    private func setupPuzzle() {
        // Load saved state or create new pieces
        if let savedPuzzle = LocalPuzzleManager.shared.getPuzzle(id: puzzle.id),
           !savedPuzzle.pieces.isEmpty,
           savedPuzzle.pieces.count == totalPieces {
            // Load saved state
            pieces = savedPuzzle.pieces.map { localPiece in
                ImagePuzzlePieceData(
                    id: localPiece.id,
                    correctPosition: localPiece.correctPosition,
                    currentPosition: localPiece.currentPosition
                )
            }
        } else {
            // Create new pieces - ensure we have exactly totalPieces
            pieces = (0..<totalPieces).map { index in
                ImagePuzzlePieceData(
                    id: index,
                    correctPosition: index,
                    currentPosition: index // Start in correct position for preview
                )
            }
            
            // Shuffle using Fisher-Yates algorithm
            var shuffledPositions = Array(0..<totalPieces)
            for i in (1..<shuffledPositions.count).reversed() {
                let j = Int.random(in: 0...i)
                shuffledPositions.swapAt(i, j)
            }
            
            // Assign shuffled positions
            for (index, piece) in pieces.enumerated() {
                pieces[index].currentPosition = shuffledPositions[index]
            }
            
            // Ensure at least some pieces are out of place
            var correctCount = pieces.filter { $0.currentPosition == $0.correctPosition }.count
            while correctCount == totalPieces {
                // Re-shuffle if all pieces ended up correct
                for i in (1..<shuffledPositions.count).reversed() {
                    let j = Int.random(in: 0...i)
                    shuffledPositions.swapAt(i, j)
                }
            }
            
            // Apply shuffled positions
            for (index, newPos) in shuffledPositions.enumerated() {
                pieces[index].currentPosition = newPos
            }
            
            // Save initial state
            savePuzzleState()
        }
    }
    
    private func savePuzzleState() {
        var updatedPuzzle = puzzle
        updatedPuzzle.pieces = pieces.map { piece in
            LocalPuzzlePiece(
                id: piece.id,
                correctPosition: piece.correctPosition,
                currentPosition: piece.currentPosition,
                content: "\(piece.id)",
                emoji: nil,
                imageUrl: nil
            )
        }
        LocalPuzzleManager.shared.updatePuzzle(updatedPuzzle)
    }
    
    private func startPreview() {
        // Show preview for 3 seconds with countdown
        showingPreview = true
        timeElapsed = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            
            if timeElapsed >= 3 {
                // End preview, shuffle pieces, start game timer
                timer?.invalidate()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showingPreview = false
                }
                
                // Small delay before starting game timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    timeElapsed = 0
                    startTimer()
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
        // Ignore taps during preview
        guard !showingPreview else { return }
        
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
        guard displayIndex1 < displayPieces.count && displayIndex2 < displayPieces.count else { return }
        let piece1 = displayPieces[displayIndex1]
        let piece2 = displayPieces[displayIndex2]
        guard let i1 = pieces.firstIndex(where: { $0.id == piece1.id }),
              let i2 = pieces.firstIndex(where: { $0.id == piece2.id }) else { return }
        let temp = pieces[i1].currentPosition
        pieces[i1].currentPosition = pieces[i2].currentPosition
        pieces[i2].currentPosition = temp
        
        // Save state after move
        savePuzzleState()
    }
    
    private func checkSolution() {
        attempts += 1
        isCorrect = pieces.allSatisfy { $0.correctPosition == $0.currentPosition }
        showResult = true
    }
    
    private func calculateScore() -> Int {
        let baseScore = puzzle.difficulty == .hard ? 100 : (puzzle.difficulty == .medium ? 75 : 50)
        return max(10, baseScore - max(0, (attempts - 1) * 5) - min(20, timeElapsed / 60))
    }
    
    private func formatTime(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
    
    private func savePuzzleResult() {
        var updatedPuzzle = puzzle
        updatedPuzzle.isCompleted = true
        updatedPuzzle.score = calculateScore()
        updatedPuzzle.attempts = attempts
        updatedPuzzle.timeSpent = timeElapsed
        LocalPuzzleManager.shared.updatePuzzle(updatedPuzzle)
        
        // Save to games UserDefaults for unified results view
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "puzzle",
            "title": puzzle.title,
            "difficulty": puzzle.difficulty.rawValue,
            "score": calculateScore(),
            "attempts": attempts,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

// MARK: - Image Puzzle Piece Data
struct ImagePuzzlePieceData: Identifiable {
    let id: Int
    let correctPosition: Int
    var currentPosition: Int
}

// MARK: - FIXED Custom Image Jigsaw Piece
struct CustomImageJigsawPiece: View {
    let piece: ImagePuzzlePieceData
    let isSelected: Bool
    let gridSize: Int
    let row: Int
    let col: Int
    let puzzle: LocalPuzzle
    let pieceSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            // Calculate extension for tabs (25% of piece size)
            let extend = pieceSize * 0.25
            let fullSize = pieceSize + extend * 2
            
            ZStack {
                // Drop shadow (bottom layer)
                JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend)
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 0, y: 2)
                    .blur(radius: isSelected ? 8 : 4)
                
                // Main piece content
                ZStack {
                    // Content with image
                    CustomImagePieceContent(piece: piece, gridSize: gridSize, puzzle: puzzle, size: pieceSize, extend: extend)
                        .clipShape(JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend))
                    
                    // Subtle inner shadow for depth (top-left)
                    JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .blendMode(.overlay)
                    
                    // Bottom-right edge highlight for 3D effect
                    JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend)
                        .stroke(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                
                // Selection glow
                if isSelected {
                    JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend)
                        .stroke(Color.yellow, lineWidth: 3)
                        .shadow(color: .yellow.opacity(0.8), radius: 8)
                }
            }
            .frame(width: fullSize, height: fullSize)
            .contentShape(JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: pieceSize, height: pieceSize)
        .zIndex(isSelected ? 100 : 1)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - FIXED Custom Image Piece Content
struct CustomImagePieceContent: View {
    let piece: ImagePuzzlePieceData
    let gridSize: Int
    let puzzle: LocalPuzzle
    let size: CGFloat
    let extend: CGFloat
    
    var body: some View {
        let correctRow = piece.correctPosition / gridSize
        let correctCol = piece.correctPosition % gridSize
        
        // Total image size needs to account for all pieces + their extensions
        let totalImageSize = size * CGFloat(gridSize)
        
        ZStack {
            if let imagePath = puzzle.customImagePath,
               let customImage = LocalPuzzleManager.shared.loadCustomImage(path: imagePath) {
                GeometryReader { geometry in
                    Image(uiImage: customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: totalImageSize, height: totalImageSize)
                        .clipped()
                        .offset(
                            // Offset to show the correct piece, accounting for the extend padding
                            x: -CGFloat(correctCol) * size,
                            y: -CGFloat(correctRow) * size
                        )
                }
            } else {
                // Emoji background
                ZStack {
                    puzzle.puzzleImage.backgroundColor
                    
                    // Emoji positioned and centered in the full grid
                    Text(puzzle.puzzleImage.emoji)
                        .font(.system(size: totalImageSize * 0.6))
                        .frame(width: totalImageSize, height: totalImageSize)
                        .position(x: totalImageSize / 2, y: totalImageSize / 2)
                        .offset(
                            x: -CGFloat(correctCol) * size - size / 2,
                            y: -CGFloat(correctRow) * size - size / 2
                        )
                }
            }
        }
        .frame(width: size + extend * 2, height: size + extend * 2)
    }
}

// MARK: - Jigsaw Piece Shape
// MARK: - Jigsaw Piece Shape
struct JigsawPieceShape: Shape {
    let row, col, totalRows, totalCols: Int
    // extend: How much to extend the drawing area beyond the grid cell (for tabs)
    var extend: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // The "grid cell" bounds are inset by 'extend'
        // rect is the full drawing area (pieceSize + extend*2)
        let w = rect.width - extend * 2
        let h = rect.height - extend * 2
        
        // Tab size relative to the grid cell size
        let tabSize = min(w, h) * 0.25
        
        // Start point (top-left of grid cell)
        let startX = extend
        let startY = extend
        
        path.move(to: CGPoint(x: startX, y: startY))
        
        // Top Edge (IN) - unless first row
        if row > 0 {
            path.addLine(to: CGPoint(x: startX + w * 0.35, y: startY))
            // Curve IN (down into body)
            path.addQuadCurve(
                to: CGPoint(x: startX + w * 0.65, y: startY),
                control: CGPoint(x: startX + w * 0.5, y: startY + tabSize)
            )
        }
        path.addLine(to: CGPoint(x: startX + w, y: startY))
        
        // Right Edge (OUT) - unless last col
        if col < totalCols - 1 {
            path.addLine(to: CGPoint(x: startX + w, y: startY + h * 0.35))
            // Curve OUT (right)
            path.addQuadCurve(
                to: CGPoint(x: startX + w, y: startY + h * 0.65),
                control: CGPoint(x: startX + w + tabSize, y: startY + h * 0.5)
            )
        }
        path.addLine(to: CGPoint(x: startX + w, y: startY + h))
        
        // Bottom Edge (OUT) - unless last row
        if row < totalRows - 1 {
            path.addLine(to: CGPoint(x: startX + w * 0.65, y: startY + h))
            // Curve OUT (down)
            path.addQuadCurve(
                to: CGPoint(x: startX + w * 0.35, y: startY + h),
                control: CGPoint(x: startX + w * 0.5, y: startY + h + tabSize)
            )
        }
        path.addLine(to: CGPoint(x: startX, y: startY + h))
        
        // Left Edge (IN) - unless first col
        if col > 0 {
            path.addLine(to: CGPoint(x: startX, y: startY + h * 0.65))
            // Curve IN (right into body)
            path.addQuadCurve(
                to: CGPoint(x: startX, y: startY + h * 0.35),
                control: CGPoint(x: startX + tabSize, y: startY + h * 0.5)
            )
        }
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Puzzle Stat Pill
struct PuzzleStatPill: View {
    let icon: String, value: String, label: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline.bold())
                Text(label).font(.caption).opacity(0.8)
            }
        }
        .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10).background(Color.white.opacity(0.2)).cornerRadius(20)
    }
}

// MARK: - Puzzle Result Screen
struct PuzzleResultScreen: View {
    let isCorrect: Bool, timeElapsed: Int, attempts: Int, score: Int
    let onDismiss: () -> Void
    @State private var showConfetti = false
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: isCorrect ? [.green.opacity(0.9), .teal] : [.orange.opacity(0.9), .red.opacity(0.8)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 180, height: 180)
                    Text(isCorrect ? "🎉" : "💪").font(.system(size: 100))
                }
                .scaleEffect(showConfetti ? 1 : 0.5).animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
                Text(isCorrect ? "Amazing!" : "Almost There!").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text(isCorrect ? "Puzzle Completed!" : "Keep trying!").font(.title2).foregroundColor(.white.opacity(0.9))
                if isCorrect {
                    VStack(spacing: 16) {
                        PuzzleResultRow(icon: "star.fill", label: "Score", value: "\(score) pts", color: .yellow)
                        PuzzleResultRow(icon: "clock.fill", label: "Time", value: formatTime(timeElapsed), color: .cyan)
                        PuzzleResultRow(icon: "hand.tap.fill", label: "Attempts", value: "\(attempts)", color: .orange)
                    }
                    .padding(24).background(Color.white.opacity(0.15)).cornerRadius(24).padding(.horizontal, 40)
                }
                Spacer()
                Button(action: onDismiss) {
                    Text(isCorrect ? "Continue" : "Try Again").font(.title2.bold()).foregroundColor(isCorrect ? .green : .orange)
                        .frame(maxWidth: .infinity).frame(height: 60).background(Color.white).cornerRadius(30).shadow(radius: 10)
                }
                .padding(.horizontal, 40).padding(.bottom, 50)
            }
            
            // Celebration overlay for success
            if isCorrect && showCelebration {
                CelebrationView {
                    showCelebration = false
                }
            }
        }
        .onAppear {
            showConfetti = true
            
            if isCorrect {
                // Play kids clapping and cheering sound
                SoundEffectManager.shared.playKidsClapping()
                
                // Show celebration animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCelebration = true
                }
            }
        }
    }
    private func formatTime(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}

// MARK: - Puzzle Result Row
struct PuzzleResultRow: View {
    let icon: String, label: String, value: String, color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 40)
            Text(label).font(.headline).foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value).font(.title3.bold()).foregroundColor(.white)
        }
    }
}
