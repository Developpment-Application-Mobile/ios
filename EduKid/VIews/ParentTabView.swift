//
//  ParentTabView.swift
//  EduKid
//
//  Updated: November 22, 2025
//  Added Puzzles section alongside Quizzes
//

import SwiftUI

struct ParentTabView: View {
    let parent: Parent
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient - full screen
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
            
            // Content
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                ParentDashboardContent(parent: parent)
                    .tag(0)
                
                // Games Management Tab (Quizzes + Puzzles)
                ParentGamesManagementScreen(parent: parent)
                    .tag(1)
                
                // Profile Tab
                ParentProfileScreen()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Bottom Navigation Bar
            CustomBottomNavBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Custom Bottom Navigation Bar
struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            NavBarItem(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            NavBarItem(
                icon: "gamecontroller.fill",
                title: "Games",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            NavBarItem(
                icon: "person.fill",
                title: "Profile",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
        )
    }
}

struct NavBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color(red: 0.686, green: 0.494, blue: 0.906) : .gray)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(red: 0.686, green: 0.494, blue: 0.906) : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Parent Dashboard Content
struct ParentDashboardContent: View {
    let parent: Parent
    @EnvironmentObject var authVM: AuthViewModel
    @State private var childToDelete: Child?
    @State private var showDeleteAlert = false
    @State private var isDeletingChild = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parent Dashboard")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Manage your children's learning")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 24)
                
                // Add Child Button
                Button(action: { authVM.authState = .addChild }) {
                    Text("➕ ADD NEW CHILD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 24)
                
                // Children List
                if parent.children.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("📚")
                            .font(.system(size: 60))
                        Text("No children added yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Text("Tap 'Add New Child' to get started")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(parent.children) { child in
                                ChildCard(child: child) {
                                    authVM.selectChild(child)
                                } onDelete: {
                                    childToDelete = child
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            if isDeletingChild {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Deleting child...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color(hex: "272052"))
                .cornerRadius(16)
            }
        }
        .alert("Delete Child", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { childToDelete = nil }
            Button("Delete", role: .destructive) {
                if let child = childToDelete {
                    deleteChild(child)
                }
            }
        } message: {
            if let child = childToDelete {
                Text("Are you sure you want to delete '\(child.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func deleteChild(_ child: Child) {
        isDeletingChild = true
        Task {
            do {
                try await authVM.deleteChild(childId: child.id)
                await MainActor.run {
                    isDeletingChild = false
                    childToDelete = nil
                }
            } catch {
                await MainActor.run {
                    isDeletingChild = false
                    childToDelete = nil
                    print("❌ Failed to delete child: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Parent Games Management Screen (Quizzes + Puzzles)
struct ParentGamesManagementScreen: View {
    let parent: Parent
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedChild: Child?
    @State private var selectedGameType = 0 // 0: Quizzes, 1: Puzzles
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Games Management")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Create quizzes and puzzles for your children")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 24)
                
                // Content
                if parent.children.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("👶")
                            .font(.system(size: 60))
                        Text("No children added")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Text("Add a child first to create games")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else if selectedChild == nil {
                    // Child Selector
                    VStack(spacing: 16) {
                        Spacer()
                        Text("🎮")
                            .font(.system(size: 60))
                        Text("Select a child")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Text("Choose which child to create games for")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer().frame(height: 20)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(parent.children) { child in
                                    Button(action: { selectedChild = child }) {
                                        HStack {
                                            Image(child.avatarEmoji)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                                .background(Color.white.opacity(0.2))
                                                .clipShape(Circle())
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(child.name)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)
                                                Text("Age \(child.age) • Level \(child.level)")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .padding(16)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Game Type Selector + Content
                    VStack(spacing: 0) {
                        // Change Child button
                        HStack {
                            Spacer()
                            Button(action: { selectedChild = nil }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 12))
                                    Text("Change Child")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        // Game Type Tabs
                        HStack(spacing: 0) {
                            GameTypeTab(
                                title: "📝 Quizzes",
                                isSelected: selectedGameType == 0
                            ) {
                                selectedGameType = 0
                            }
                            
                            GameTypeTab(
                                title: "🧩 Puzzles",
                                isSelected: selectedGameType == 1
                            ) {
                                selectedGameType = 1
                            }
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Content based on selected type
                        if selectedGameType == 0 {
                            ParentQuizListScreen(child: selectedChild!)
                        } else {
                            ParentPuzzleListScreen(child: selectedChild!)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Game Type Tab
struct GameTypeTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
        }
    }
}

// MARK: - Parent Puzzle List Screen
struct ParentPuzzleListScreen: View {
    let child: Child
    @State private var puzzles: [PuzzleResponse] = []
    @State private var isLoading = false
    @State private var showGenerateSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Generate Puzzle Button
            Button(action: { showGenerateSheet = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                    Text("Generate New Puzzle")
                        .font(.headline)
                }
                .foregroundColor(Color(red: 0.153, green: 0.125, blue: 0.322))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Puzzles List
            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Spacer()
            } else if puzzles.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("🧩")
                        .font(.system(size: 60))
                    Text("No puzzles yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    Text("Generate a puzzle to get started")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(puzzles) { puzzle in
                            ParentPuzzleCard(puzzle: puzzle)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showGenerateSheet) {
            GeneratePuzzleSheet(child: child) {
                Task { await loadPuzzles() }
            }
        }
        .onAppear {
            Task { await loadPuzzles() }
        }
    }
    
    private func loadPuzzles() async {
        isLoading = true
        do {
            guard let parentId = AuthService.shared.getParentId() else { return }
            let fetched = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
            await MainActor.run {
                puzzles = fetched.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("Error loading puzzles: \(error)")
            }
        }
    }
}

// MARK: - Parent Puzzle Card
struct ParentPuzzleCard: View {
    let puzzle: PuzzleResponse
    
    var body: some View {
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
                    .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                
                HStack(spacing: 8) {
                    Label(puzzle.puzzleType.displayName, systemImage: puzzle.puzzleType.icon)
                    Label("\(puzzle.gridSize)x\(puzzle.gridSize)", systemImage: "square.grid.2x2")
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                
                Text(puzzle.puzzleDifficulty.displayName)
                    .font(.caption.bold())
                    .foregroundColor(puzzle.puzzleDifficulty.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(puzzle.puzzleDifficulty.color.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Status
            if puzzle.isCompleted {
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.title2)
                    Text("\(puzzle.score)")
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                }
            } else {
                Text("Pending")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
    }
}
