//
//  SimpleGames.swift
//  EduKid
//
//  Created by mac on 22/11/2025.
//
//
//  Simple games that don't require backend
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
        guard !matchedIndices.contains(index),
              flippedIndices.count < 2,
              !flippedIndices.contains(index) else { return }
        
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
            matchedIndices.insert(indices[0])
            matchedIndices.insert(indices[1])
            flippedIndices.removeAll()
            
            if matchedIndices.count == cards.count {
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showResult = true
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                flippedIndices.removeAll()
            }
        }
    }
    
    private func calculateScore() -> Int {
        let timeBonus = max(0, 300 - timeElapsed) / 3
        let movesPenalty = moves * 2
        return max(10, 100 + timeBonus - movesPenalty)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func saveGameResult(score: Int) {
        // Save to UserDefaults for parent view
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
                
                Button(action: onDismiss) {
                    Text("Continue")
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
