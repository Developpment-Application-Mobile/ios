//
//  SimpleGames.swift
//  EduKid
//
//  Complete with all 4 games: Memory, Color, Shape, Number Sequence
//

import SwiftUI

// MARK: - Memory Match Game
struct MemoryMatchGame: View {
    let child: Child
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var cards: [MemoryCard] = []
    @State private var flippedIndices: Set<Int> = []
    @State private var matchedIndices: Set<Int> = []
    @State private var moves = 0
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    
    let emojis = ["🍎", "🍌", "🍊", "🍇", "🍓", "🍒", "🍑", "🍉"]
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
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
                    
                    VStack(spacing: 4) {
                        Text("Memory Match")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Find all pairs!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text(formatTime(timeElapsed))
                            .font(.headline.monospacedDigit())
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Stats
                HStack(spacing: 40) {
                    StatLabel(icon: "hand.tap.fill", label: "Moves", value: "\(moves)")
                    StatLabel(icon: "checkmark.circle.fill", label: "Matched", value: "\(matchedIndices.count/2)/\(cards.count/2)")
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                // Game Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(cards.indices, id: \.self) { index in
                        MemoryCardView(
                            card: cards[index],
                            isFlipped: flippedIndices.contains(index) || matchedIndices.contains(index),
                            isMatched: matchedIndices.contains(index)
                        ) {
                            cardTapped(at: index)
                        }
                    }
                }
                .padding(20)
                
                Spacer()
            }
        }
        .onAppear {
            setupGame()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            GameResultScreen(
                title: "Memory Match Complete!",
                score: calculateScore(),
                moves: moves,
                time: timeElapsed,
                emoji: "🧠"
            ) {
                let score = calculateScore()
                saveGameResult(score: score)
                onComplete(score)
                dismiss()
            }
        }
    }
    
    private func setupGame() {
        let selectedEmojis = Array(emojis.prefix(8))
        let pairedEmojis = selectedEmojis + selectedEmojis
        cards = pairedEmojis.shuffled().map { MemoryCard(emoji: $0) }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func cardTapped(at index: Int) {
        guard cards[index].id != cards.first?.id,
              matchedIndices.count < cards.count,
              flippedIndices.count < 2,
              !matchedIndices.contains(index),
              !flippedIndices.contains(index) else { return }
        
        // Play fun pop sound when flipping card
        SoundEffectManager.shared.playPop()
        
        flippedIndices.insert(index)
        
        if flippedIndices.count == 2 {
            moves += 1
            checkForMatch()
        }
    }
    
    private func checkForMatch() {
        let indices = Array(flippedIndices)
        let first = cards[indices[0]]
        let second = cards[indices[1]]
        
        if first.emoji == second.emoji {
            // Match found! Play cheerful ding
            SoundEffectManager.shared.playDing()
            
            matchedIndices.insert(indices[0])
            matchedIndices.insert(indices[1])
            flippedIndices.removeAll()
            
            if matchedIndices.count == cards.count {
                timer?.invalidate()
                showResult = true
            }
        } else {
            // No match - play gentle oops
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                SoundEffectManager.shared.playOops()
                flippedIndices.removeAll()
            }
        }
    }
    
    private func calculateScore() -> Int {
        let timeBonus = max(0, 300 - timeElapsed)
        let movesPenalty = moves * 2
        return max(10, 100 + timeBonus - movesPenalty)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func saveGameResult(score: Int) {
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "memory",
            "score": score,
            "moves": moves,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

// MARK: - Memory Card Model
struct MemoryCard: Identifiable {
    let id = UUID()
    let emoji: String
}

// MARK: - Memory Card View
struct MemoryCardView: View {
    let card: MemoryCard
    let isFlipped: Bool
    let isMatched: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isMatched ? Color.green.opacity(0.3) : Color.white)
                    .shadow(radius: isFlipped ? 8 : 4)
                
                if isFlipped {
                    Text(card.emoji)
                        .font(.system(size: 40))
                } else {
                    Text("?")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeInOut(duration: 0.3), value: isFlipped)
        }
        .disabled(isMatched)
    }
}

// MARK: - Color Match Game
struct ColorMatchGame: View {
    let child: Child
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var targetColor: String = ""
    @State private var options: [ColorOption] = []
    @State private var score = 0
    @State private var round = 0
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var feedback = ""
    
    let totalRounds = 10
    let colors: [String: Color] = [
        "Red": .red, "Blue": .blue, "Green": .green,
        "Yellow": .yellow, "Purple": .purple, "Orange": .orange,
        "Pink": .pink, "Brown": .brown
    ]
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Color Match")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Round \(round)/\(totalRounds)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("⭐ \(score)")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Target Color Name
                VStack(spacing: 16) {
                    Text("Find the color:")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(targetColor)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                }
                
                // Feedback
                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.title2.bold())
                        .foregroundColor(feedback.contains("✓") ? .green : .red)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Color Options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(options) { option in
                        Button(action: { selectColor(option) }) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(option.color)
                                .frame(height: 120)
                                .shadow(radius: 8)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            setupRound()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            GameResultScreen(
                title: "Color Match Complete!",
                score: score,
                moves: totalRounds,
                time: timeElapsed,
                emoji: "🎨"
            ) {
                saveGameResult()
                onComplete(score)
                dismiss()
            }
        }
    }
    
    private func setupRound() {
        round += 1
        feedback = ""
        
        let allColors = Array(colors.keys)
        targetColor = allColors.randomElement()!
        
        var optionColors = [targetColor]
        while optionColors.count < 4 {
            let randomColor = allColors.randomElement()!
            if !optionColors.contains(randomColor) {
                optionColors.append(randomColor)
            }
        }
        
        options = optionColors.shuffled().map { name in
            ColorOption(name: name, color: colors[name]!)
        }
    }
    
    private func selectColor(_ option: ColorOption) {
        if option.name == targetColor {
            // Correct answer! Play cheerful yay
            SoundEffectManager.shared.playYay()
            
            score += 10
            feedback = "✓ Correct!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if round < totalRounds {
                    setupRound()
                } else {
                    timer?.invalidate()
                    showResult = true
                }
            }
        } else {
            // Wrong answer - play gentle buzz
            SoundEffectManager.shared.playBuzz()
            
            feedback = "✗ Try again!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                feedback = ""
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func saveGameResult() {
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "color",
            "score": score,
            "rounds": totalRounds,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

struct ColorOption: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

// MARK: - Shape Matching Game
struct ShapeMatchingGame: View {
    let child: Child
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var targetShape: ShapeType = .circle
    @State private var options: [ShapeType] = []
    @State private var score = 0
    @State private var round = 0
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var feedback = ""
    
    let totalRounds = 10
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Shape Match")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Round \(round)/\(totalRounds)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("⭐ \(score)")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Target Shape
                VStack(spacing: 16) {
                    Text("Find the:")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(targetShape.name)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                }
                
                // Feedback
                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.title2.bold())
                        .foregroundColor(feedback.contains("✓") ? .green : .red)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Shape Options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(options, id: \.self) { shape in
                        Button(action: { selectShape(shape) }) {
                            shape.view
                                .frame(height: 120)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 8)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            setupRound()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            GameResultScreen(
                title: "Shape Match Complete!",
                score: score,
                moves: totalRounds,
                time: timeElapsed,
                emoji: "🔷"
            ) {
                saveGameResult()
                onComplete(score)
                dismiss()
            }
        }
    }
    
    private func setupRound() {
        round += 1
        feedback = ""
        
        targetShape = ShapeType.allCases.randomElement()!
        
        var shapeOptions = [targetShape]
        while shapeOptions.count < 4 {
            let randomShape = ShapeType.allCases.randomElement()!
            if !shapeOptions.contains(randomShape) {
                shapeOptions.append(randomShape)
            }
        }
        
        options = shapeOptions.shuffled()
    }
    
    private func selectShape(_ shape: ShapeType) {
        if shape == targetShape {
            // Correct shape! Play cheerful ding
            SoundEffectManager.shared.playDing()
            
            score += 10
            feedback = "✓ Perfect!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if round < totalRounds {
                    setupRound()
                } else {
                    timer?.invalidate()
                    showResult = true
                }
            }
        } else {
            // Wrong shape - play gentle oops
            SoundEffectManager.shared.playOops()
            
            feedback = "✗ Try again!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                feedback = ""
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func saveGameResult() {
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "shape",
            "score": score,
            "rounds": totalRounds,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

// MARK: - Shape Type
enum ShapeType: String, CaseIterable {
    case circle, square, triangle, star, heart, diamond
    
    var name: String { rawValue.capitalized }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .circle:
            Circle()
                .fill(Color.blue)
                .padding(20)
        case .square:
            Rectangle()
                .fill(Color.red)
                .padding(20)
        case .triangle:
            Triangle()
                .fill(Color.green)
                .padding(20)
        case .star:
            Star()
                .fill(Color.yellow)
                .padding(20)
        case .heart:
            Heart()
                .fill(Color.pink)
                .padding(20)
        case .diamond:
            Diamond()
                .fill(Color.purple)
                .padding(20)
        }
    }
}

// MARK: - Custom Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5
        
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: height * 0.3))
        
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.25),
            control1: CGPoint(x: width / 2, y: 0),
            control2: CGPoint(x: 0, y: height * 0.1)
        )
        
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: 0, y: height * 0.5),
            control2: CGPoint(x: width / 2, y: height * 0.75)
        )
        
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.25),
            control1: CGPoint(x: width / 2, y: height * 0.75),
            control2: CGPoint(x: width, y: height * 0.5)
        )
        
        path.addCurve(
            to: CGPoint(x: width / 2, y: height * 0.3),
            control1: CGPoint(x: width, y: height * 0.1),
            control2: CGPoint(x: width / 2, y: 0)
        )
        
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Number Sequence Game
struct NumberSequenceGame: View {
    let child: Child
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var targetNumber: Int = 1
    @State private var currentSequence: [Int] = []
    @State private var availableNumbers: [Int] = []
    @State private var score = 0
    @State private var level = 1
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    
    let maxLevel = 5
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Number Sequence")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Level \(level)/\(maxLevel)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("⭐ \(score)")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Instructions
                Text("Put numbers in order!")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                // Current Sequence
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentSequence, id: \.self) { number in
                            Text("\(number)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(16)
                        }
                        
                        // Next slot
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 3)
                            .frame(width: 70, height: 70)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Available Numbers
                Text("Tap the next number:")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(availableNumbers, id: \.self) { number in
                        Button(action: { selectNumber(number) }) {
                            Text("\(number)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            setupLevel()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            GameResultScreen(
                title: "Number Sequence Complete!",
                score: score,
                moves: level,
                time: timeElapsed,
                emoji: "🔢"
            ) {
                saveGameResult()
                onComplete(score)
                dismiss()
            }
        }
    }
    
    private func setupLevel() {
        let range = min(5 + level * 2, 15)
        targetNumber = 1
        currentSequence = []
        availableNumbers = Array(1...range).shuffled()
    }
    
    private func selectNumber(_ number: Int) {
        if number == targetNumber {
            // Correct number! Play cheerful yay
            SoundEffectManager.shared.playYay()
            
            currentSequence.append(number)
            availableNumbers.removeAll { $0 == number }
            targetNumber += 1
            score += 10
            
            if availableNumbers.isEmpty {
                if level < maxLevel {
                    level += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        setupLevel()
                    }
                } else {
                    timer?.invalidate()
                    showResult = true
                }
            }
        } else {
            // Wrong number - play buzz
            SoundEffectManager.shared.playBuzz()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func saveGameResult() {
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "sequence",
            "score": score,
            "level": level,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

// MARK: - Math Quiz Game
struct MathQuizGame: View {
    let child: Child
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var currentQuestion = 0
    @State private var score = 0
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var feedback = ""
    
    @State private var num1 = 0
    @State private var num2 = 0
    @State private var operation = "+"
    @State private var correctAnswer = 0
    @State private var options: [Int] = []
    
    let totalQuestions = 10
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
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
                    
                    VStack(spacing: 4) {
                        Text("Math Quiz")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Solve the problems!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("⭐ \(score)")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Progress
                Text("Question \(currentQuestion + 1)/\(totalQuestions)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Math Problem
                VStack(spacing: 20) {
                    Text("\(num1) \(operation) \(num2) = ?")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(30)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                    
                    if !feedback.isEmpty {
                        Text(feedback)
                            .font(.title3.bold())
                            .foregroundColor(feedback.contains("✓") ? .green : .orange)
                    }
                }
                
                Spacer()
                
                // Answer Options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(options, id: \.self) { option in
                        Button(action: { selectAnswer(option) }) {
                            Text("\(option)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            setupQuestion()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            GameResultScreen(
                title: "Math Quiz Complete!",
                score: score,
                moves: totalQuestions,
                time: timeElapsed,
                emoji: "🧮"
            ) {
                saveGameResult()
                onComplete(score)
                dismiss()
            }
        }
    }
    
    private func setupQuestion() {
        // Generate random math problem
        num1 = Int.random(in: 1...10)
        num2 = Int.random(in: 1...10)
        operation = ["+", "-"].randomElement()!
        
        if operation == "+" {
            correctAnswer = num1 + num2
        } else {
            // Ensure no negative results
            if num1 < num2 {
                swap(&num1, &num2)
            }
            correctAnswer = num1 - num2
        }
        
        // Generate options
        var optionSet = Set<Int>()
        optionSet.insert(correctAnswer)
        
        while optionSet.count < 4 {
            let offset = Int.random(in: -5...5)
            let option = max(0, correctAnswer + offset)
            optionSet.insert(option)
        }
        
        options = Array(optionSet).shuffled()
        feedback = ""
    }
    
    private func selectAnswer(_ answer: Int) {
        if answer == correctAnswer {
            SoundEffectManager.shared.playDing()
            score += 10
            feedback = "✓ Correct!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                currentQuestion += 1
                if currentQuestion < totalQuestions {
                    setupQuestion()
                } else {
                    timer?.invalidate()
                    showResult = true
                }
            }
        } else {
            SoundEffectManager.shared.playOops()
            feedback = "✗ Try again!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                feedback = ""
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func saveGameResult() {
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "math",
            "score": score,
            "questions": totalQuestions,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

// MARK: - Emoji Match Game
struct EmojiMatchGame: View {
    let child: Child
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var currentRound = 0
    @State private var score = 0
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var feedback = ""
    
    @State private var targetEmoji = ""
    @State private var targetName = ""
    @State private var options: [String] = []
    
    let totalRounds = 10
    let emojiPairs: [(emoji: String, name: String)] = [
        ("🐶", "Dog"), ("🐱", "Cat"), ("🐭", "Mouse"), ("🐹", "Hamster"),
        ("🐰", "Rabbit"), ("🦊", "Fox"), ("🐻", "Bear"), ("🐼", "Panda"),
        ("🐨", "Koala"), ("🐯", "Tiger"), ("🦁", "Lion"), ("🐮", "Cow"),
        ("🐷", "Pig"), ("🐸", "Frog"), ("🐵", "Monkey"), ("🐔", "Chicken"),
        ("🦆", "Duck"), ("🦅", "Eagle"), ("🦉", "Owl"), ("🦋", "Butterfly"),
        ("🐝", "Bee"), ("🐞", "Ladybug"), ("🐢", "Turtle"), ("🐠", "Fish")
    ]
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
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
                    
                    VStack(spacing: 4) {
                        Text("Emoji Match")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Match emoji to name!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("⭐ \(score)")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Progress
                Text("Round \(currentRound + 1)/\(totalRounds)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Target Emoji
                VStack(spacing: 20) {
                    Text(targetEmoji)
                        .font(.system(size: 100))
                        .padding(30)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                    
                    Text("What is this?")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    if !feedback.isEmpty {
                        Text(feedback)
                            .font(.title3.bold())
                            .foregroundColor(feedback.contains("✓") ? .green : .orange)
                    }
                }
                
                Spacer()
                
                // Name Options
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button(action: { selectName(option) }) {
                            Text(option)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            setupRound()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $showResult) {
            GameResultScreen(
                title: "Emoji Match Complete!",
                score: score,
                moves: totalRounds,
                time: timeElapsed,
                emoji: "😊"
            ) {
                saveGameResult()
                onComplete(score)
                dismiss()
            }
        }
    }
    
    private func setupRound() {
        currentRound += 1
        feedback = ""
        
        // Select random emoji
        let pair = emojiPairs.randomElement()!
        targetEmoji = pair.emoji
        targetName = pair.name
        
        // Generate options
        var optionNames = [targetName]
        while optionNames.count < 4 {
            let randomPair = emojiPairs.randomElement()!
            if !optionNames.contains(randomPair.name) {
                optionNames.append(randomPair.name)
            }
        }
        
        options = optionNames.shuffled()
    }
    
    private func selectName(_ name: String) {
        if name == targetName {
            SoundEffectManager.shared.playYay()
            score += 10
            feedback = "✓ Correct!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if currentRound < totalRounds {
                    setupRound()
                } else {
                    timer?.invalidate()
                    showResult = true
                }
            }
        } else {
            SoundEffectManager.shared.playBuzz()
            feedback = "✗ Try again!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                feedback = ""
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func saveGameResult() {
        var games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        games.append([
            "type": "emoji",
            "score": score,
            "rounds": totalRounds,
            "time": timeElapsed,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        UserDefaults.standard.set(games, forKey: "child_\(child.id)_games")
    }
}

// MARK: - Shared Components
struct StatLabel: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct GameResultScreen: View {
    let title: String
    let score: Int
    let moves: Int
    let time: Int
    let emoji: String
    let onDismiss: () -> Void
    
    @State private var showCelebration = false
    @State private var animateEmoji = false
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Text(emoji)
                    .font(.system(size: 100))
                    .scaleEffect(animateEmoji ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateEmoji)
                
                Text(title)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    StatRow(icon: "star.fill", label: "Score", value: "\(score)", color: .yellow)
                    StatRow(icon: "hand.tap.fill", label: "Moves", value: "\(moves)", color: .blue)
                    StatRow(icon: "clock.fill", label: "Time", value: formatTime(time), color: .orange)
                }
                .padding(24)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button("Continue") {
                    onDismiss()
                }
                .font(.headline.bold())
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            
            // Celebration overlay
            if showCelebration {
                CelebrationView {
                    showCelebration = false
                }
            }
        }
        .onAppear {
            // Play kids clapping and cheering sound
            SoundEffectManager.shared.playKidsClapping()
            
            // Animate emoji
            animateEmoji = true
            
            // Show celebration after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCelebration = true
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(color)
            }
            
            Spacer()
        }
    }
}
