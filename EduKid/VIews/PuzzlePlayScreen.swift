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
    @State private var mainImage: UIImage?  // Shared image for all pieces
    @State private var showingPreview = true  // Show complete image first
    @State private var previewCountdown = 5  // 5 second countdown
    
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
                                                pieceSize: pieceSize,
                                                mainImageUrl: puzzle.imageUrl,
                                                displayPosition: displayIndex,
                                                sharedImage: mainImage  // Pass shared image
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
            
            // Preview Overlay - Show complete image for 5 seconds
            if showingPreview, let image = mainImage {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("🎯")
                            .font(.system(size: 60))
                        
                        Text("Remember this!")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        // Show complete image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .cornerRadius(20)
                            .shadow(radius: 20)
                        
                        Text("Puzzle will shuffle in...")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(previewCountdown)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .animation(.spring(), value: previewCountdown)
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            setupPuzzle()
            loadMainImage()  // Load image once for all pieces
            startPreviewCountdown()  // Start preview countdown
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
        
        // Start with pieces in correct order for preview
        // They will be shuffled after preview countdown
        for index in 0..<pieces.count {
            pieces[index].currentPosition = pieces[index].correctPosition
        }
    }
    
    private func shufflePieces() {
        // Shuffle pieces after preview
        let shuffled = Array(0..<totalPieces).shuffled()
        for (index, newPos) in shuffled.enumerated() {
            if index < pieces.count {
                pieces[index].currentPosition = newPos
            }
        }
        
        // Ensure at least some pieces are out of place
        var correctCount = pieces.filter { $0.currentPosition == $0.correctPosition }.count
        while correctCount == totalPieces {
            // Re-shuffle if all pieces ended up correct
            let reshuffled = Array(0..<totalPieces).shuffled()
            for (index, newPos) in reshuffled.enumerated() {
                if index < pieces.count {
                    pieces[index].currentPosition = newPos
                }
            }
            correctCount = pieces.filter { $0.currentPosition == $0.correctPosition }.count
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func startPreviewCountdown() {
        // Start countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if showingPreview {
                previewCountdown -= 1
                
                if previewCountdown <= 0 {
                    // End preview, shuffle pieces, start game timer
                    timer?.invalidate()
                    
                    // Shuffle pieces
                    shufflePieces()
                    
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
    }
    
    private func loadMainImage() {
        guard puzzle.puzzleType == .image,
              let imageUrlString = puzzle.imageUrl,
              let url = URL(string: imageUrlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.mainImage = image
                }
            }
        }.resume()
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
    let mainImageUrl: String?
    let displayPosition: Int
    let sharedImage: UIImage?  // Shared loaded image
    let onTap: () -> Void
    
    var body: some View {
        let row = displayPosition / gridSize
        let col = displayPosition % gridSize
        let extend = pieceSize * 0.15  // Extension for tabs
        let fullSize = pieceSize + extend * 2
        
        Button(action: onTap) {
            ZStack {
                // Drop shadow
                JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend)
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 0, y: 2)
                    .blur(radius: isSelected ? 8 : 4)
                
                // Main piece
                ZStack {
                    // Background gradient
                    JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend)
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [.yellow, .orange] : [.white, Color.white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Content - cropped image
                    if puzzleType == .image, let image = sharedImage {
                        if let croppedImage = cropImage(image, pieceId: piece.correctPosition) {
                            Image(uiImage: croppedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: pieceSize, height: pieceSize)
                                .offset(x: extend, y: extend)
                                .clipShape(JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend))
                        }
                    } else if puzzleType == .image {
                        // Loading
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                        .frame(width: pieceSize, height: pieceSize)
                        .offset(x: extend, y: extend)
                        .clipShape(JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend))
                    } else {
                        PieceContentView(piece: piece, puzzleType: puzzleType, size: pieceSize)
                            .offset(x: extend, y: extend)
                            .clipShape(JigsawPieceShape(row: row, col: col, totalRows: gridSize, totalCols: gridSize, extend: extend))
                    }
                    
                    // Inner shadow for depth
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
                    
                    // Bottom-right edge highlight
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
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .zIndex(isSelected ? 100 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func cropImage(_ image: UIImage, pieceId: Int) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let row = pieceId / gridSize
        let col = pieceId % gridSize
        
        let width = CGFloat(cgImage.width) / CGFloat(gridSize)
        let height = CGFloat(cgImage.height) / CGFloat(gridSize)
        
        let x = CGFloat(col) * width
        let y = CGFloat(row) * height
        
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
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
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    }
                    .frame(width: size, height: size)
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

// MARK: - Cropped Image Piece View (for AI puzzles)
struct CroppedImagePieceView: View {
    let mainImageUrl: String
    let pieceId: Int
    let gridSize: Int
    let size: CGFloat
    
    @State private var loadedImage: UIImage?
    
    var body: some View {
        ZStack {
            if let uiImage = loadedImage {
                let row = pieceId / gridSize
                let col = pieceId % gridSize
                
                // Crop the UIImage
                if let croppedImage = cropImage(uiImage, row: row, col: col) {
                    Image(uiImage: croppedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: size, height: size)
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                }
                .frame(width: size, height: size)
                .onAppear {
                    loadImage()
                }
            }
        }
    }
    
    private func loadImage() {
        guard let url = URL(string: mainImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.loadedImage = image
                }
            }
        }.resume()
    }
    
    private func cropImage(_ image: UIImage, row: Int, col: Int) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = CGFloat(cgImage.width) / CGFloat(gridSize)
        let height = CGFloat(cgImage.height) / CGFloat(gridSize)
        
        let x = CGFloat(col) * width
        let y = CGFloat(row) * height
        
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
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

