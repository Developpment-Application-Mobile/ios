//
//  PuzzleViews.swift
//  EduKid
//
//  Created by mac on 22/11/2025.
//  Simplified: Only contains shared components
//  Puzzle generation is ONLY for parents
//

import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Puzzle Card (Used by both parent and child)
struct PuzzleCard: View {
    let puzzle: PuzzleResponse
    var showScore: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(puzzle.puzzleType.color.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: puzzle.puzzleType.icon)
                        .font(.title2)
                        .foregroundColor(puzzle.puzzleType.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(puzzle.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(puzzle.puzzleType.displayName, systemImage: puzzle.puzzleType.icon)
                        Label("\(puzzle.gridSize)x\(puzzle.gridSize)", systemImage: "square.grid.2x2")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                    Text(puzzle.puzzleDifficulty.displayName)
                        .font(.caption.bold())
                        .foregroundColor(puzzle.puzzleDifficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(puzzle.puzzleDifficulty.color.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Score or Play icon
                if showScore && puzzle.isCompleted {
                    VStack(spacing: 4) {
                        Text("⭐")
                            .font(.title2)
                        Text("\(puzzle.score)")
                            .font(.headline.bold())
                            .foregroundColor(.yellow)
                    }
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
        }
    }
}

// MARK: - Generate Puzzle Sheet (PARENT ONLY)
struct GeneratePuzzleSheet: View {
    let child: Child
    let onGenerated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: PuzzleType = .word
    @State private var selectedDifficulty: PuzzleDifficulty = .easy
    @State private var topic = ""
    @State private var isGenerating = false
    @State private var useAdaptive = true
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.153, green: 0.125, blue: 0.322)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Child Info
                        HStack(spacing: 12) {
                            Image(child.avatarEmoji)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Creating puzzle for:")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(child.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Adaptive Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $useAdaptive) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                    VStack(alignment: .leading) {
                                        Text("Smart Generation")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("AI picks the best puzzle for \(child.name)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .tint(.purple)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                        
                        if !useAdaptive {
                            // Manual Options
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Puzzle Type")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(PuzzleType.allCases, id: \.self) { type in
                                        PuzzleTypeButton(
                                            type: type,
                                            isSelected: selectedType == type
                                        ) {
                                            selectedType = type
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            
                            // Difficulty
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Difficulty")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    ForEach(PuzzleDifficulty.allCases, id: \.self) { diff in
                                        DifficultyButton(
                                            difficulty: diff,
                                            isSelected: selectedDifficulty == diff
                                        ) {
                                            selectedDifficulty = diff
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            
                            // Topic
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Topic (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., Animals, Space, Numbers", text: $topic)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        // Generate Button
                        Button(action: generatePuzzle) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.153, green: 0.125, blue: 0.322)))
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGenerating ? "Generating..." : "Generate Puzzle")
                                    .font(.headline)
                            }
                            .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        .disabled(isGenerating)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Failed to generate puzzle")
            }
        }
    }
    
    private func generatePuzzle() {
        isGenerating = true
        Task {
            do {
                guard let parentId = AuthService.shared.getParentId() else {
                    throw PuzzleError.noToken
                }
                
                if useAdaptive {
                    _ = try await PuzzleService.shared.generateAdaptivePuzzle(
                        parentId: parentId,
                        kidId: child.id
                    )
                } else {
                    _ = try await PuzzleService.shared.generatePuzzle(
                        parentId: parentId,
                        kidId: child.id,
                        type: selectedType,
                        difficulty: selectedDifficulty,
                        topic: topic.isEmpty ? nil : topic
                    )
                }
                
                await MainActor.run {
                    isGenerating = false
                    onGenerated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                    print("❌ Error generating puzzle: \(error)")
                }
            }
        }
    }
}

// MARK: - Puzzle Type Button
struct PuzzleTypeButton: View {
    let type: PuzzleType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                Text(type.displayName)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : type.color)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? type.color : type.color.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - Difficulty Button
struct DifficultyButton: View {
    let difficulty: PuzzleDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(difficulty.displayName)
                    .font(.subheadline.bold())
                Text("\(difficulty.gridSize)x\(difficulty.gridSize)")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : difficulty.color)
            .foregroundColor(isSelected ? .white : difficulty.color)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isSelected ? difficulty.color : difficulty.color.opacity(0.2))
            .cornerRadius(10)
        }
    }
}
