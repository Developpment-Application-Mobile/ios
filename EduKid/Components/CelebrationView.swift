//
//  CelebrationView.swift
//  EduKid
//
//  Celebration animations for game completion
//

import SwiftUI

// MARK: - Main Celebration View
struct CelebrationView: View {
    let onComplete: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Confetti particles
            ConfettiView()
            
            // Emoji burst
            EmojiBurstView()
            
            // Star burst
            StarBurstView()
        }
        .onAppear {
            isAnimating = true
            
            // Auto-dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onComplete()
            }
        }
    }
}

// MARK: - Confetti Particle System
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .rotationEffect(particle.rotation)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink]
        
        for i in 0..<80 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -50
                ),
                rotation: .degrees(Double.random(in: 0...360)),
                opacity: 1.0
            )
            
            particles.append(particle)
            
            // Animate falling
            withAnimation(.linear(duration: Double.random(in: 2...4)).delay(Double(i) * 0.02)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].position.y = size.height + 50
                    particles[index].rotation = .degrees(Double.random(in: 360...720))
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Angle
    var opacity: Double
}

// MARK: - Emoji Burst Animation
struct EmojiBurstView: View {
    @State private var emojis: [EmojiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(emojis) { emoji in
                    Text(emoji.emoji)
                        .font(.system(size: emoji.size))
                        .position(emoji.position)
                        .scaleEffect(emoji.scale)
                        .opacity(emoji.opacity)
                }
            }
            .onAppear {
                generateEmojis(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateEmojis(in size: CGSize) {
        let emojiList = ["👏", "🎉", "⭐", "✨", "🎊", "🌟", "💫", "🎈"]
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for i in 0..<12 {
            let angle = Double(i) * (360.0 / 12.0)
            let radians = angle * .pi / 180
            
            let emoji = EmojiParticle(
                id: i,
                emoji: emojiList.randomElement()!,
                size: CGFloat.random(in: 40...60),
                position: center,
                scale: 0.1,
                opacity: 1.0
            )
            
            emojis.append(emoji)
            
            // Animate outward burst
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.05)) {
                if let index = emojis.firstIndex(where: { $0.id == emoji.id }) {
                    let distance: CGFloat = 150
                    emojis[index].position = CGPoint(
                        x: center.x + cos(radians) * distance,
                        y: center.y + sin(radians) * distance
                    )
                    emojis[index].scale = 1.5
                }
            }
            
            // Fade out
            withAnimation(.easeOut(duration: 0.5).delay(0.8 + Double(i) * 0.05)) {
                if let index = emojis.firstIndex(where: { $0.id == emoji.id }) {
                    emojis[index].opacity = 0
                    emojis[index].scale = 0.5
                }
            }
        }
    }
}

struct EmojiParticle: Identifiable {
    let id: Int
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
}

// MARK: - Star Burst Effect
struct StarBurstView: View {
    @State private var stars: [StarParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    Image(systemName: "star.fill")
                        .font(.system(size: star.size))
                        .foregroundColor(.yellow)
                        .position(star.position)
                        .scaleEffect(star.scale)
                        .rotationEffect(star.rotation)
                        .opacity(star.opacity)
                        .shadow(color: .yellow.opacity(0.6), radius: 10)
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateStars(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for i in 0..<8 {
            let angle = Double(i) * (360.0 / 8.0)
            let radians = angle * .pi / 180
            
            let star = StarParticle(
                id: i,
                size: CGFloat.random(in: 30...50),
                position: center,
                scale: 0.1,
                rotation: .degrees(0),
                opacity: 1.0
            )
            
            stars.append(star)
            
            // Animate outward
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(Double(i) * 0.08)) {
                if let index = stars.firstIndex(where: { $0.id == star.id }) {
                    let distance: CGFloat = 200
                    stars[index].position = CGPoint(
                        x: center.x + cos(radians) * distance,
                        y: center.y + sin(radians) * distance
                    )
                    stars[index].scale = 1.2
                    stars[index].rotation = .degrees(Double.random(in: 180...360))
                }
            }
            
            // Fade out
            withAnimation(.easeOut(duration: 0.6).delay(1.0 + Double(i) * 0.08)) {
                if let index = stars.firstIndex(where: { $0.id == star.id }) {
                    stars[index].opacity = 0
                }
            }
        }
    }
}

struct StarParticle: Identifiable {
    let id: Int
    let size: CGFloat
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle
    var opacity: Double
}
