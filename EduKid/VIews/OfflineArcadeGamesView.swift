import SwiftUI

// MARK: - Arcade Games Hub
struct OfflineArcadeGamesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedGame: ArcadeGame?
    
    enum ArcadeGame: Identifiable {
        case snakeGame
        case memoryMatch
        case colorCatch
        
        var id: String {
            switch self {
            case .snakeGame: return "snake"
            case .memoryMatch: return "memory"
            case .colorCatch: return "color"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("🎮 Arcade Games")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Offline Badge
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("No Internet Required")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.2))
                .cornerRadius(20)
                .padding(.bottom, 30)
                
                // Games Grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Snake Game
                        GameCard(
                            title: "Snake Classic",
                            emoji: "🐍",
                            description: "Guide the snake, eat apples, grow longer!",
                            difficulty: "Easy",
                            color: Color.green,
                            gradient: [Color.green, Color.mint]
                        ) {
                            selectedGame = .snakeGame
                        }
                        
                        // Memory Match
                        GameCard(
                            title: "Memory Match",
                            emoji: "🧠",
                            description: "Find matching pairs of emojis!",
                            difficulty: "Medium",
                            color: Color.purple,
                            gradient: [Color.purple, Color.pink]
                        ) {
                            selectedGame = .memoryMatch
                        }
                        
                        // Color Catch
                        GameCard(
                            title: "Color Catch",
                            emoji: "🎨",
                            description: "Tap the matching colors before time runs out!",
                            difficulty: "Hard",
                            color: Color.orange,
                            gradient: [Color.orange, Color.red]
                        ) {
                            selectedGame = .colorCatch
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(item: $selectedGame) { game in
            switch game {
            case .snakeGame:
                SnakeGameView()
            case .memoryMatch:
                MemoryMatchGameView()
            case .colorCatch:
                ColorCatchGameView()
            }
        }
    }
}

// MARK: - Game Card
struct GameCard: View {
    let title: String
    let emoji: String
    let description: String
    let difficulty: String
    let color: Color
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(emoji)
                        .font(.system(size: 50))
                    
                    Spacer()
                    
                    Text(difficulty)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.8))
                        .cornerRadius(12)
                }
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack {
                    Spacer()
                    
                    Text("Play Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: color.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(ArcadeScaleButtonStyle())
    }
}

// MARK: - Game 1: Snake Classic
struct SnakeGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var snake: [CGPoint] = [CGPoint(x: 5, y: 5)]
    @State private var food: CGPoint = CGPoint(x: 10, y: 10)
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right
    @State private var score: Int = 0
    @State private var isGameOver = false
    @State private var gameTimer: Timer?
    
    let gridSize = 20
    let cellSize: CGFloat = 18
    
    enum Direction {
        case up, down, left, right
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("🐍 Snake")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Score: \(score)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Button(action: resetGame) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                Spacer()
                
                // Game Board
                ZStack {
                    // Grid background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Food
                    Circle()
                        .fill(Color.red)
                        .frame(width: cellSize - 2, height: cellSize - 2)
                        .position(
                            x: food.x * cellSize + cellSize / 2,
                            y: food.y * cellSize + cellSize / 2
                        )
                    
                    // Snake
                    ForEach(0..<snake.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == 0 ? Color.green : Color.green.opacity(0.8))
                            .frame(width: cellSize - 2, height: cellSize - 2)
                            .position(
                                x: snake[index].x * cellSize + cellSize / 2,
                                y: snake[index].y * cellSize + cellSize / 2
                            )
                    }
                }
                .frame(width: CGFloat(gridSize) * cellSize, height: CGFloat(gridSize) * cellSize)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            let horizontal = abs(value.translation.width) > abs(value.translation.height)
                            if horizontal {
                                nextDirection = value.translation.width > 0 ? .right : .left
                            } else {
                                nextDirection = value.translation.height > 0 ? .down : .up
                            }
                        }
                )
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    Button(action: { nextDirection = .up }) {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                    
                    HStack(spacing: 40) {
                        Button(action: { nextDirection = .left }) {
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(15)
                        }
                        
                        Button(action: { nextDirection = .right }) {
                            Image(systemName: "arrowtriangle.right.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(15)
                        }
                    }
                    
                    Button(action: { nextDirection = .down }) {
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Game Over Overlay
            if isGameOver {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Game Over!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score: \(score)")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Button(action: resetGame) {
                        Text("Play Again")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(25)
                    }
                }
            }
        }
        .onAppear(perform: startGame)
        .onDisappear(perform: stopGame)
    }
    
    func startGame() {
        resetGame()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            moveSnake()
        }
    }
    
    func stopGame() {
        gameTimer?.invalidate()
    }
    
    func resetGame() {
        snake = [CGPoint(x: 5, y: 5)]
        food = generateFood()
        direction = .right
        nextDirection = .right
        score = 0
        isGameOver = false
    }
    
    func moveSnake() {
        guard !isGameOver else { return }
        
        // Update direction
        let oppositeDirections: [Direction: Direction] = [
            .up: .down, .down: .up, .left: .right, .right: .left
        ]
        if nextDirection != oppositeDirections[direction] {
            direction = nextDirection
        }
        
        var newHead = snake[0]
        switch direction {
        case .up: newHead.y -= 1
        case .down: newHead.y += 1
        case .left: newHead.x -= 1
        case .right: newHead.x += 1
        }
        
        // Check collision with walls
        if newHead.x < 0 || newHead.x >= CGFloat(gridSize) ||
           newHead.y < 0 || newHead.y >= CGFloat(gridSize) {
            isGameOver = true
            return
        }
        
        // Check collision with self
        if snake.contains(where: { $0 == newHead }) {
            isGameOver = true
            return
        }
        
        snake.insert(newHead, at: 0)
        
        // Check if ate food
        if newHead == food {
            score += 10
            food = generateFood()
        } else {
            snake.removeLast()
        }
    }
    
    func generateFood() -> CGPoint {
        var newFood: CGPoint
        repeat {
            newFood = CGPoint(
                x: CGFloat(Int.random(in: 0..<gridSize)),
                y: CGFloat(Int.random(in: 0..<gridSize))
            )
        } while snake.contains(where: { $0 == newFood })
        return newFood
    }
}

// MARK: - Game 2: Memory Match
struct MemoryMatchGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cards: [MemoryGameCard] = []
    @State private var flippedIndices: [Int] = []
    @State private var matchedIndices: Set<Int> = []
    @State private var score: Int = 0
    @State private var moves: Int = 0
    @State private var isGameComplete = false
    
    let emojis = ["🍎", "🍌", "🍇", "🍊", "🍓", "🍉", "🍒", "🥝"]
    let columns = [GridItem(.adaptive(minimum: 80), spacing: 15)]
    
    struct MemoryGameCard: Identifiable {
        let id = UUID()
        let emoji: String
        var isFlipped = false
        var isMatched = false
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.pink]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("🧠 Memory Match")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            Text("Moves: \(moves)")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Score: \(score)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Button(action: resetGame) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                // Game Board
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(0..<cards.count, id: \.self) { index in
                            MemoryGameCardView(
                                card: cards[index],
                                isFlipped: flippedIndices.contains(index) || matchedIndices.contains(index)
                            )
                            .onTapGesture {
                                cardTapped(at: index)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            
            // Win Overlay
            if isGameComplete {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("🎉")
                        .font(.system(size: 80))
                    
                    Text("You Win!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        Text("Moves: \(moves)")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Score: \(score)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: resetGame) {
                        Text("Play Again")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.purple)
                            .cornerRadius(25)
                    }
                }
            }
        }
        .onAppear(perform: resetGame)
    }
    
    func resetGame() {
        var newCards: [MemoryGameCard] = []
        for emoji in emojis {
            newCards.append(MemoryGameCard(emoji: emoji))
            newCards.append(MemoryGameCard(emoji: emoji))
        }
        cards = newCards.shuffled()
        flippedIndices = []
        matchedIndices = []
        score = 0
        moves = 0
        isGameComplete = false
    }
    
    func cardTapped(at index: Int) {
        guard !matchedIndices.contains(index),
              !flippedIndices.contains(index),
              flippedIndices.count < 2 else { return }
        
        flippedIndices.append(index)
        
        if flippedIndices.count == 2 {
            moves += 1
            checkForMatch()
        }
    }
    
    func checkForMatch() {
        let firstIndex = flippedIndices[0]
        let secondIndex = flippedIndices[1]
        
        if cards[firstIndex].emoji == cards[secondIndex].emoji {
            matchedIndices.insert(firstIndex)
            matchedIndices.insert(secondIndex)
            score += 100
            flippedIndices = []
            
            if matchedIndices.count == cards.count {
                isGameComplete = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                flippedIndices = []
            }
        }
    }
}

struct MemoryGameCardView: View {
    let card: MemoryMatchGameView.MemoryGameCard
    let isFlipped: Bool
    
    var body: some View {
        ZStack {
            if isFlipped {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(radius: 5)
                
                Text(card.emoji)
                    .font(.system(size: 50))
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(radius: 5)
                
                Text("?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 100)
        .rotation3DEffect(
            .degrees(isFlipped ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.3), value: isFlipped)
    }
}

// MARK: - Game 3: Color Catch
struct ColorCatchGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var targetColor: Color = .red
    @State private var fallingItems: [FallingItem] = []
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var timeRemaining: Int = 60
    @State private var isGameOver = false
    @State private var gameTimer: Timer?
    @State private var spawnTimer: Timer?
    
    let colors: [(color: Color, name: String)] = [
        (.red, "Red"),
        (.blue, "Blue"),
        (.green, "Green"),
        (.yellow, "Yellow"),
        (.purple, "Purple"),
        (.orange, "Orange")
    ]
    
    struct FallingItem: Identifiable {
        let id = UUID()
        var position: CGFloat
        var xPosition: CGFloat
        let color: Color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("🎨 Color Catch")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                HStack(spacing: 4) {
                                    ForEach(0..<lives, id: \.self) { _ in
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Text("Score: \(score)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("⏱️ \(timeRemaining)s")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: resetGame) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Target Color
                    VStack(spacing: 10) {
                        Text("Tap this color:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(targetColor)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    }
                    .padding(.bottom, 20)
                    
                    // Game Area
                    ZStack {
                        ForEach(fallingItems) { item in
                            Circle()
                                .fill(item.color)
                                .frame(width: 50, height: 50)
                                .position(x: item.xPosition, y: item.position)
                                .onTapGesture {
                                    itemTapped(item)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                }
                
                // Game Over Overlay
                if isGameOver {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Text(lives > 0 ? "Time's Up!" : "Game Over!")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Final Score: \(score)")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Button(action: resetGame) {
                            Text("Play Again")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color.orange)
                                .cornerRadius(25)
                        }
                    }
                }
            }
            .onAppear {
                startGame(in: geometry)
            }
            .onDisappear(perform: stopGame)
        }
    }
    
    func startGame(in geometry: GeometryProxy) {
        resetGame()
        targetColor = colors.randomElement()!.color
        
        // Spawn items
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            spawnItem(in: geometry)
        }
        
        // Move items and countdown
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            moveItems(in: geometry)
            
            // Countdown every 50 ticks (1 second)
            if Int.random(in: 0..<50) == 0 {
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    isGameOver = true
                    stopGame()
                }
            }
        }
    }
    
    func stopGame() {
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
    }
    
    func resetGame() {
        fallingItems = []
        score = 0
        lives = 3
        timeRemaining = 60
        isGameOver = false
        targetColor = colors.randomElement()!.color
    }
    
    func spawnItem(in geometry: GeometryProxy) {
        let newItem = FallingItem(
            position: -50,
            xPosition: CGFloat.random(in: 50...(geometry.size.width - 50)),
            color: colors.randomElement()!.color
        )
        fallingItems.append(newItem)
    }
    
    func moveItems(in geometry: GeometryProxy) {
        for index in fallingItems.indices {
            fallingItems[index].position += 3
            
            // Remove items that went off screen
            if fallingItems[index].position > geometry.size.height {
                if fallingItems[index].color == targetColor {
                    lives -= 1
                    if lives <= 0 {
                        isGameOver = true
                        stopGame()
                    }
                }
                fallingItems.remove(at: index)
                break
            }
        }
    }
    
    func itemTapped(_ item: FallingItem) {
        if item.color == targetColor {
            score += 10
            // Change target color
            targetColor = colors.randomElement()!.color
        } else {
            lives -= 1
            if lives <= 0 {
                isGameOver = true
                stopGame()
            }
        }
        
        fallingItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Arcade Button Style
struct ArcadeScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
