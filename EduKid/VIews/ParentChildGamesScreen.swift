//
//  ParentChildGamesScreen.swift
//  EduKid
//
//  Created on December 29, 2025.
//  Unified screen for parents to manage all child activities: Quiz, Puzzle, Schedule, Shop
//

import SwiftUI

struct ParentChildGamesScreen: View {
    let child: Child
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var selectedTab = 0
    @State private var quizzes: [AIQuizResponse] = []
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var inventory: [Gift] = []
    @State private var isLoading = false
    @State private var showCreateQuiz = false
    @State private var showCreatePuzzle = false
    
    let tabs = ["Quiz", "Puzzle", "Schedule", "Shop"]
    
    // Calculate total score for Shop
    var grossTotalScore: Int {
        let quizScore = completedQuizzes.reduce(0) { $0 + $1.score }
        let localPuzzleScore = localPuzzles.filter { $0.isCompleted }.reduce(0) { $0 + $1.score }
        let serverPuzzleScore = serverPuzzles.filter { $0.isCompleted }.reduce(0) { $0 + $1.score }
        let gameScore = games.compactMap { $0["score"] as? Int }.reduce(0, +)
        return quizScore + localPuzzleScore + serverPuzzleScore + gameScore
    }
    
    var calculatedTotalScore: Int {
        let grossScore = grossTotalScore
        let totalSpent = inventory.reduce(0) { $0 + $1.cost }
        return max(0, grossScore - totalSpent)
    }
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.isAnswered || $0.answered > 0 }
    }
    
    var pendingQuizzes: [AIQuizResponse] {
        quizzes.filter { !$0.isAnswered && $0.answered == 0 }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Text("Games & Activities")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                // Child Info Card
                HStack(spacing: 16) {
                    Image(child.avatarEmoji)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Age \(child.age) • Level \(child.level)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(calculatedTotalScore)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text("Points")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Tab Bar
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 12) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        CompactGameTabButton(
                            title: tabs[index],
                            color: getTabColor(index),
                            isSelected: selectedTab == index
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Tab Content
                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                } else {
                    Group {
                        switch selectedTab {
                        case 0:
                            ParentQuizTabView(
                                child: child,
                                quizzes: quizzes,
                                onRefresh: { Task { await loadData() } }
                            )
                        case 1:
                            ParentPuzzleTabView(
                                child: child,
                                localPuzzles: localPuzzles,
                                serverPuzzles: serverPuzzles,
                                onRefresh: { Task { await loadData() } }
                            )
                        case 2:
                            ParentScheduleTabView(child: child)
                        case 3:
                            if let parentId = AuthService.shared.getParentId() {
                                ShopView(childId: child.id, parentId: parentId, initialPoints: grossTotalScore)
                            } else {
                                Text("Error: Parent not found")
                                    .foregroundColor(.white)
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await loadData() }
        }
    }
    
    private func getTabColor(_ index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .purple
        case 2: return .orange
        case 3: return .pink
        default: return .purple
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // Load local data
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        games = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []
        
        guard let parentId = AuthService.shared.getParentId() else {
            await MainActor.run { isLoading = false }
            return
        }
        
        // Load quizzes
        do {
            let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
            await MainActor.run {
                // Check if any quiz has a date
                let hasAnyDates = fetchedQuizzes.contains { $0.createdAt != nil }
                
                if hasAnyDates {
                    // Sort by createdAt descending (newest first) - handle nil dates
                    quizzes = fetchedQuizzes.sorted { quiz1, quiz2 in
                        if let date1 = quiz1.createdAt, let date2 = quiz2.createdAt {
                            return date1 > date2
                        }
                        if quiz1.createdAt != nil { return true }
                        if quiz2.createdAt != nil { return false }
                        return false
                    }
                } else {
                    // If no dates, reverse the array (assuming API returns oldest first)
                    quizzes = Array(fetchedQuizzes.reversed())
                }
            }
        } catch {
            print("❌ Error loading quizzes: \(error.localizedDescription)")
        }
        
        // Load server puzzles
        do {
            let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
            await MainActor.run {
                // Check if any puzzle has a date
                let hasAnyDates = fetchedPuzzles.contains { $0.createdAt != nil }
                
                if hasAnyDates {
                    // Sort by createdAt descending (newest first) - handle nil dates
                    serverPuzzles = fetchedPuzzles.sorted { puzzle1, puzzle2 in
                        if let date1 = puzzle1.createdAt, let date2 = puzzle2.createdAt {
                            return date1 > date2
                        }
                        if puzzle1.createdAt != nil { return true }
                        if puzzle2.createdAt != nil { return false }
                        return false
                    }
                } else {
                    // If no dates, reverse the array (assuming API returns oldest first)
                    serverPuzzles = Array(fetchedPuzzles.reversed())
                }
            }
        } catch {
            print("❌ Error loading puzzles: \(error.localizedDescription)")
        }
        
        // Load inventory for point calculation
        if let token = AuthService.shared.getToken() {
            let baseURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
            let pUrl = URL(string: "\(baseURL)/parents/\(parentId)")!
            var req = URLRequest(url: pUrl)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
            
            do {
                let (d, _) = try await URLSession.shared.data(for: req)
                if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                   let childrenArr = json["children"] as? [[String: Any]] {
                    if let childDict = childrenArr.first(where: { ($0["_id"] as? String) == child.id || ($0["id"] as? String) == child.id }) {
                        if let invArr = childDict["inventory"] as? [[String: Any]] {
                            let data = try JSONSerialization.data(withJSONObject: invArr)
                            let loadedInventory = try JSONDecoder().decode([Gift].self, from: data)
                            await MainActor.run {
                                inventory = loadedInventory
                            }
                        }
                    }
                }
            } catch {
                print("❌ Error loading inventory: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run { isLoading = false }
    }
}

// MARK: - Compact Game Tab Button
struct CompactGameTabButton: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.9),
                                    color.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected ? color.opacity(0.6) : Color.white.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: isSelected ? 3 : 2
                )
                .scaleEffect(isSelected ? 1.0 : 0.96)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Parent Quiz Tab View
struct ParentQuizTabView: View {
    let child: Child
    let quizzes: [AIQuizResponse]
    let onRefresh: () -> Void
    
    @State private var selectedQuiz: AIQuizResponse?
    @State private var showQuizDetail = false
    @State private var showCreateQuiz = false
    
    var pendingQuizzes: [AIQuizResponse] {
        quizzes.filter { !$0.isAnswered && $0.answered == 0 }
    }
    
    var completedQuizzes: [AIQuizResponse] {
        quizzes.filter { $0.isAnswered || $0.answered > 0 }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Create Quiz Button
            Button(action: { showCreateQuiz = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Create New Quiz")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            }
            .padding(.horizontal, 20)
            
            // Quiz List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if !pendingQuizzes.isEmpty {
                        ParentSectionHeader(title: "Pending Quizzes", icon: "clock.fill", color: .orange)
                            .padding(.horizontal, 20)
                        
                        ForEach(pendingQuizzes) { quiz in
                            Button(action: {
                                selectedQuiz = quiz
                                showQuizDetail = true
                            }) {
                                ParentQuizCard(quiz: quiz, isPending: true)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    if !completedQuizzes.isEmpty {
                        ParentSectionHeader(title: "Completed Quizzes", icon: "checkmark.circle.fill", color: .green)
                            .padding(.horizontal, 20)
                        
                        ForEach(completedQuizzes.prefix(5)) { quiz in
                            Button(action: {
                                selectedQuiz = quiz
                                showQuizDetail = true
                            }) {
                                ParentQuizCard(quiz: quiz, isPending: false)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    if quizzes.isEmpty {
                        VStack(spacing: 16) {
                            Text("📝")
                                .font(.system(size: 60))
                            
                            Text("No Quizzes Yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Create your first quiz for \(child.name)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showQuizDetail) {
            if let quiz = selectedQuiz {
                ParentQuizDetailView(quiz: quiz, child: child)
            }
        }
        .sheet(isPresented: $showCreateQuiz) {
            NavigationStack {
                AdaptiveQuizGenerationScreen(child: child, quizHistory: quizzes, onQuizGenerated: {
                    showCreateQuiz = false
                    onRefresh()
                })
            }
        }
    }
}

// MARK: - Parent Puzzle Tab View
struct ParentPuzzleTabView: View {
    let child: Child
    let localPuzzles: [LocalPuzzle]
    let serverPuzzles: [PuzzleResponse]
    let onRefresh: () -> Void
    
    @State private var showCreatePuzzle = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Create Puzzle Button
            Button(action: { showCreatePuzzle = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Create New Puzzle")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            }
            .padding(.horizontal, 20)
            
            // Puzzle List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if !serverPuzzles.isEmpty {
                        ParentSectionHeader(title: "AI Puzzles", icon: "puzzlepiece.fill", color: .purple)
                            .padding(.horizontal, 20)
                        
                        ForEach(serverPuzzles) { puzzle in
                            ParentPuzzleCard(puzzle: puzzle)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    if !localPuzzles.isEmpty {
                        ParentSectionHeader(title: "Photo Puzzles", icon: "photo.fill", color: .blue)
                            .padding(.horizontal, 20)
                        
                        ForEach(localPuzzles) { puzzle in
                            ParentLocalPuzzleCard(puzzle: puzzle, childId: child.id)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    if localPuzzles.isEmpty && serverPuzzles.isEmpty {
                        VStack(spacing: 16) {
                            Text("🧩")
                                .font(.system(size: 60))
                            
                            Text("No Puzzles Yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Create your first puzzle for \(child.name)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCreatePuzzle) {
            NavigationStack {
                ParentPuzzleCreationSheet(child: child, onCreated: {
                    showCreatePuzzle = false
                    onRefresh()
                })
            }
        }
    }
}

// MARK: - Parent Schedule Tab View
struct ParentScheduleTabView: View {
    let child: Child
    
    var body: some View {
        ParentActivitySchedulerScreen(child: child)
    }
}

// MARK: - Helper Views

struct ParentSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct ParentQuizCard: View {
    let quiz: AIQuizResponse
    let isPending: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isPending ? Color.orange.opacity(0.3) : Color.green.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: isPending ? "clock.fill" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(isPending ? .orange : .green)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(quiz.meaningfulTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(quiz.subject.capitalized)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    Label("\(quiz.questions.count) questions", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Score (if completed)
            if !isPending {
                VStack(spacing: 2) {
                    Text("\(quiz.score)%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ParentPuzzleCard: View {
    let puzzle: PuzzleResponse
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(puzzle.isCompleted ? Color.green.opacity(0.3) : Color.purple.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: puzzle.isCompleted ? "checkmark.circle.fill" : "puzzlepiece.fill")
                    .font(.title2)
                    .foregroundColor(puzzle.isCompleted ? .green : .purple)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Puzzle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(puzzle.difficulty.capitalized) • \(puzzle.pieces) pieces")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Score
            if puzzle.isCompleted {
                VStack(spacing: 2) {
                    Text("\(puzzle.score)%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ParentLocalPuzzleCard: View {
    let puzzle: LocalPuzzle
    let childId: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            if let imagePath = puzzle.customImagePath,
               let uiImage = LocalPuzzleManager.shared.loadCustomImage(path: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(puzzle.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(puzzle.difficulty.rawValue.capitalized) • \(puzzle.gridSize)x\(puzzle.gridSize)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Status
            if puzzle.isCompleted {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Done")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
