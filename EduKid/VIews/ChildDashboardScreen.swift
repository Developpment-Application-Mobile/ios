//
//  ChildDashboardScreen.swift
//  EduKid
//
//  FIXED: All 4 games now working - NO placeholders
//

import SwiftUI

// MARK: - Game Type Enum
enum SimpleGameType: String, Identifiable, CaseIterable {
    case memory = "Memory Match"
    case color = "Color Match"
    case shape = "Shape Match"
    case sequence = "Number Sequence"
    case math = "Math Quiz"
    case emoji = "Emoji Match"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .memory: return "brain.head.profile"
        case .color: return "paintpalette.fill"
        case .shape: return "square.on.circle"
        case .sequence: return "number.circle"
        case .math: return "function"
        case .emoji: return "face.smiling.fill"
        }
    }
    var color: Color {
        switch self {
        case .memory: return .purple
        case .color: return .orange
        case .shape: return .green
        case .sequence: return .blue
        case .math: return .cyan
        case .emoji: return .pink
        }
    }
    var description: String {
        switch self {
        case .memory: return "Match pairs of cards"
        case .color: return "Match colors and patterns"
        case .shape: return "Identify matching shapes"
        case .sequence: return "Complete number patterns"
        case .math: return "Solve math problems"
        case .emoji: return "Match emoji to name"
        }
    }
}

// MARK: - Main Child Dashboard Screen
struct ChildDashboardScreen: View {
    let child: Child
    @EnvironmentObject var authVM: AuthViewModel
    @State private var quizzes: [AIQuizResponse] = []
    @State private var isLoading = false
    @State private var selectedMainTab = 0
    @State private var selectedGame: SimpleGameType?
    @State private var localPuzzles: [LocalPuzzle] = []
    @State private var serverPuzzles: [PuzzleResponse] = []
    @State private var games: [[String: Any]] = []
    @State private var inventory: [Gift] = [] // Add inventory state
    @State private var showMenu = false // Menu visibility state
    
    // Calculate total earnings (Gross) for passing to Shop
    var grossTotalScore: Int {
        let quizScore = completedQuizzes.reduce(0) { $0 + $1.score }
        let localPuzzleScore = localPuzzles.filter { $0.isCompleted }.reduce(0) { $0 + $1.score }
        let serverPuzzleScore = serverPuzzles.filter { $0.isCompleted }.reduce(0) { $0 + $1.score }
        let gameScore = games.compactMap { $0["score"] as? Int }.reduce(0, +)
        return quizScore + localPuzzleScore + serverPuzzleScore + gameScore
    }
    
    var calculatedTotalScore: Int {
        // Calculate total earnings (Gross)
        let grossScore = grossTotalScore
        
        // Calculate spending (new logic)
        let totalSpent = inventory.reduce(0) { $0 + $1.cost }
        
        // Return Net Score (Available Balance)
        return max(0, grossScore - totalSpent)
    }
    
    var pendingQuizzes: [AIQuizResponse] {
        let pending = quizzes.filter { !$0.isAnswered }
        print("🔍 PENDING QUIZZES: \(pending.count) quizzes from total \(quizzes.count)")
        return pending
    }
    var completedQuizzes: [AIQuizResponse] {
        let completed = quizzes.filter { $0.isAnswered }
        print("🔍 COMPLETED QUIZZES: \(completed.count) quizzes")
        return completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                
                // Hamburger Menu Button with Section Name (Top Left)
                VStack {
                    HStack(spacing: 12) {
                        Button(action: { showMenu.toggle() }) {
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 2)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 2)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 2)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        // Section Name
                        Text(getSectionName())
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .zIndex(2)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 40)
                        
                        ChildInfoCardView(
                            child: child, 
                            totalScore: calculatedTotalScore
                        )
                            .padding(.horizontal, 20)
                        
                        // Tab Content (No Tab Grid - Direct Content)
                        Group {
                            switch selectedMainTab {
                            case 0:
                                ChildScheduledActivitiesView(
                                    child: child,
                                    onQuizCompleted: { Task { await loadData() } }
                                )
                            case 1:
                                ChildQuizContent(
                                    pendingQuizzes: pendingQuizzes,
                                    completedQuizzes: completedQuizzes,
                                    child: child,
                                    onQuizCompleted: { Task { await loadData() } }
                                )
                            case 2:
                                ChildPuzzleContentView(
                                    child: child,
                                    onPuzzleCompleted: { Task { await loadData() } }
                                )
                            case 3:
                                ChildGamesContent(child: child, selectedGame: $selectedGame)
                            case 4:
                                if let parentId = AuthService.shared.getParentId() {
                                    QuestListView(childId: child.id, parentId: parentId)
                                } else {
                                    Text("Error: Parent not found")
                                }
                            case 5:
                                if let parentId = AuthService.shared.getParentId() {
                                    ShopView(childId: child.id, parentId: parentId, initialPoints: grossTotalScore)
                                } else {
                                    Text("Error: Parent not found")
                                }
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Hidden Logout Button (tap 5 times on child's name to logout)
                        
                        Spacer().frame(height: 40)
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5)
                }
                
                // Slide-out Menu
                if showMenu {
                    ZStack(alignment: .leading) {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showMenu = false
                                }
                            }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            // Menu Header with Gradient
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Spacer()
                                    Button(action: { 
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showMenu = false
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(.top, 50)
                                .padding(.horizontal, 20)
                                
                                Text("Menu")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60, height: 4)
                                    .cornerRadius(2)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            }
                            .padding(.bottom, 30)
                            
                            // Navigation Menu Items
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 12) {
                                    MenuNavigationItem(
                                        title: "My Tasks",
                                        color: .blue,
                                        isSelected: selectedMainTab == 0
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMainTab = 0
                                            showMenu = false
                                        }
                                    }
                                    
                                    MenuNavigationItem(
                                        title: "Quizzes",
                                        color: .green,
                                        isSelected: selectedMainTab == 1
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMainTab = 1
                                            showMenu = false
                                        }
                                    }
                                    
                                    MenuNavigationItem(
                                        title: "Puzzles",
                                        color: .orange,
                                        isSelected: selectedMainTab == 2
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMainTab = 2
                                            showMenu = false
                                        }
                                    }
                                    
                                    MenuNavigationItem(
                                        title: "More Games",
                                        color: .purple,
                                        isSelected: selectedMainTab == 3
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMainTab = 3
                                            showMenu = false
                                        }
                                    }
                                    
                                    MenuNavigationItem(
                                        title: "Quests",
                                        color: .red,
                                        isSelected: selectedMainTab == 4
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMainTab = 4
                                            showMenu = false
                                        }
                                    }
                                    
                                    MenuNavigationItem(
                                        title: "Shop",
                                        color: .pink,
                                        isSelected: selectedMainTab == 5
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMainTab = 5
                                            showMenu = false
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            Spacer()
                            
                            // Logout Button - Professional Design
                            VStack(spacing: 16) {
                                Button(action: { 
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showMenu = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        authVM.signOutChild()
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.red.opacity(0.3),
                                                            Color.red.opacity(0.1)
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "arrow.uturn.left")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.red)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Logout")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            Text("Exit your session")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.25),
                                                        Color.white.opacity(0.15)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // App Version Info
                                Text("EduKid ")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 50)
                        }
                        .frame(width: 280)
                        .frame(maxHeight: .infinity)
                        .background(
                            ZStack {
                                // Base gradient
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.153, green: 0.125, blue: 0.322),
                                        Color(red: 0.1, green: 0.08, blue: 0.25)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                // Overlay gradient for depth
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .topLeading,
                                    startRadius: 50,
                                    endRadius: 300
                                )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 30, x: 10, y: 0)
                        .edgesIgnoringSafeArea(.vertical)
                        .offset(x: showMenu ? 0 : -280)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMenu)
                    }
                    .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .onAppear { Task { await loadData() } }
            .onChange(of: selectedMainTab) { _ in
                Task { await loadData() }
            }
            .refreshable { await loadData() }
            .fullScreenCover(item: $selectedGame) { game in
                switch game {
                case .memory:
                    MemoryMatchGame(child: child) { _ in selectedGame = nil }
                case .color:
                    ColorMatchGame(child: child) { _ in selectedGame = nil }
                case .shape:
                    ShapeMatchingGame(child: child) { _ in selectedGame = nil }
                case .sequence:
                    NumberSequenceGame(child: child) { _ in selectedGame = nil }
                case .math:
                    MathQuizGame(child: child) { _ in selectedGame = nil }
                case .emoji:
                    EmojiMatchGame(child: child) { _ in selectedGame = nil }
                }
            }
        }
    }
    
    private func getSectionName() -> String {
        switch selectedMainTab {
        case 0: return "My Tasks"
        case 1: return "Quizzes"
        case 2: return "Puzzles"
        case 3: return "More Games"
        case 4: return "Quests"
        case 5: return "Shop"
        default: return "Dashboard"
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // Load Games
        if let loadedGames = UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] {
            games = loadedGames
        }
        
        // Load Local Puzzles
        localPuzzles = LocalPuzzleManager.shared.getAllPuzzles(for: child.id)
        
        guard let parentId = AuthService.shared.getParentId() else {
            print("⚠️ No parentId found in AuthService - cannot load data")
            await MainActor.run { isLoading = false }
            return
        }
        
        print("📚 Loading data for child: \(child.id), parent: \(parentId)")
        
        // Load Quizzes independently
        do {
            let fetchedQuizzes = try await AIQuizService.shared.getQuizzes(parentId: parentId, kidId: child.id)
            await MainActor.run {
                print("✅ Loaded \(fetchedQuizzes.count) quizzes for child dashboard")
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
        
        // Load Server Puzzles independently
        do {
            let fetchedPuzzles = try await PuzzleService.shared.getPuzzles(parentId: parentId, kidId: child.id)
            await MainActor.run {
                print("✅ Loaded \(fetchedPuzzles.count) puzzles for child dashboard")
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
        
        // Load Inventory for Net Point Calculation
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
                                self.inventory = loadedInventory
                                print("✅ Loaded \(loadedInventory.count) items in inventory for point calculation")
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

// MARK: - Compact Tab Button (No Icons, Smaller Size)
struct CompactTabButton: View {
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
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
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
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? color.opacity(0.6) : Color.white.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isSelected ? 8 : 3,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
                .scaleEffect(isSelected ? 1.0 : 0.96)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Child Info Card View
struct ChildInfoCardView: View {
    let child: Child
    let totalScore: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(child.avatarEmoji)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color.white.opacity(0.3))
                .clipShape(Circle())
                .shadow(radius: 8)
            
            Text(child.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                ChildStatBadge(icon: "star.fill", label: "Points", value: "\(totalScore)", color: .yellow)
                ChildStatBadge(icon: "chart.bar.fill", label: "Level", value: child.level, color: .green)
                ChildStatBadge(icon: "calendar", label: "Age", value: "\(child.age)", color: .blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
    }
}

// MARK: - Child Stat Badge
struct ChildStatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.3)).frame(width: 50, height: 50)
                Image(systemName: icon).font(.title3).foregroundColor(color)
            }
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Child Quiz Content
struct ChildQuizContent: View {
    let pendingQuizzes: [AIQuizResponse]
    let completedQuizzes: [AIQuizResponse]
    let child: Child
    let onQuizCompleted: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if pendingQuizzes.isEmpty && completedQuizzes.isEmpty {
                ChildEmptyState(icon: "doc.text.fill", title: "No quizzes yet!", message: "Ask your parent to assign quizzes")
            } else {
                if !pendingQuizzes.isEmpty {
                    ChildSectionHeader(title: "Ready to Take", icon: "play.circle.fill")
                    ForEach(pendingQuizzes) { quiz in
                        NavigationLink(destination: QuizTakingScreen(quiz: quiz, child: child, onQuizCompleted: onQuizCompleted)) {
                            ChildQuizCard(quiz: quiz)
                        }
                    }
                }
                if !completedQuizzes.isEmpty {
                    ChildSectionHeader(title: "Completed", icon: "checkmark.circle.fill")
                    ForEach(completedQuizzes.prefix(3)) { quiz in
                        ChildCompletedQuizCard(quiz: quiz)
                    }
                }
            }
        }
    }
}

// MARK: - Child Quiz Card
struct ChildQuizCard: View {
    let quiz: AIQuizResponse
    
    var subjectIcon: String {
        switch quiz.subject.lowercased() {
        case "math": return "function"
        case "science": return "flask.fill"
        case "english": return "book.fill"
        default: return "star.fill"
        }
    }
    
    var iconColor: Color {
        switch quiz.subject.lowercased() {
        case "math": return .blue
        case "science": return .green
        case "english": return .purple
        default: return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(iconColor.opacity(0.3)).frame(width: 70, height: 70)
                Image(systemName: subjectIcon).font(.system(size: 28)).foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 8) {
                // CHANGÉ: Utiliser meaningfulTitle
                Text(quiz.meaningfulTitle).font(.title3.bold()).foregroundColor(.white).lineLimit(2)
                Text(quiz.subject.capitalized).font(.subheadline).foregroundColor(.white.opacity(0.8))
                HStack(spacing: 12) {
                    Label("\(quiz.questions.count) questions", systemImage: "questionmark.circle.fill")
                    Label(quiz.difficulty.capitalized, systemImage: "star")
                }
                .font(.caption).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "play.circle.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .background(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(20)
    }
}

// MARK: - Child Completed Quiz Card
struct ChildCompletedQuizCard: View {
    let quiz: AIQuizResponse
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
                // CHANGÉ: Utiliser meaningfulTitle
                Text(quiz.meaningfulTitle).font(.subheadline.bold()).foregroundColor(.white).lineLimit(2)
                Text(quiz.subject.capitalized).font(.caption).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("⭐")
                Text("\(quiz.score)%").font(.headline.bold()).foregroundColor(.yellow)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}




// MARK: - Child Empty State
struct ChildEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 50)).foregroundColor(.white.opacity(0.5))
            Text(title).font(.title3).foregroundColor(.white.opacity(0.7))
            Text(message).font(.subheadline).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Child Games Content
struct ChildGamesContent: View {
    let child: Child
    @Binding var selectedGame: SimpleGameType?
    @State private var gameHistory: [[String: Any]] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text(" Fun Games")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // All Game Cards
            ForEach(SimpleGameType.allCases, id: \.self) { game in
                ChildGameCard(
                    title: game.rawValue,
                    description: game.description,
                    icon: game.icon,
                    color: game.color,
                    gamesPlayed: getGamesPlayedCount(type: game.rawValue.lowercased().replacingOccurrences(of: " ", with: ""))
                ) {
                    selectedGame = game
                }
            }
            
            // Game History
            if !gameHistory.isEmpty {
                ChildGameHistory(child: child)
            }
        }
        .onAppear {
            loadGameHistory()
        }
    }
    
    private func loadGameHistory() {
        gameHistory = (UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []).reversed()
    }
    
    private func getGamesPlayedCount(type: String) -> Int {
        let typeKey: String
        switch type {
        case "memorymatch": typeKey = "memory"
        case "colormatch": typeKey = "color"
        case "shapematch": typeKey = "shape"
        case "numbersequence": typeKey = "sequence"
        default: typeKey = type
        }
        return gameHistory.filter { ($0["type"] as? String) == typeKey }.count
    }
}

// MARK: - Child Game Card
struct ChildGameCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gamesPlayed: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.3))
                        .frame(width: 70, height: 70)
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    if gamesPlayed > 0 {
                        Text("Played \(gamesPlayed) times")
                            .font(.caption)
                            .foregroundColor(color)
                    }
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(Color.white.opacity(0.15))
            .cornerRadius(20)
        }
    }
}

// MARK: - Child Game History
struct ChildGameHistory: View {
    let child: Child
    @State private var games: [[String: Any]] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Recent Games").font(.headline).foregroundColor(.white)
            
            if games.isEmpty {
                Text("No games played yet!").font(.subheadline).foregroundColor(.white.opacity(0.7))
                    .padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).cornerRadius(12)
            } else {
                ForEach(games.prefix(3).indices, id: \.self) { index in
                    ChildGameHistoryRow(game: games[index])
                }
            }
        }
        .onAppear {
            games = (UserDefaults.standard.array(forKey: "child_\(child.id)_games") as? [[String: Any]] ?? []).reversed()
        }
    }
}

// MARK: - Child Game History Row
struct ChildGameHistoryRow: View {
    let game: [String: Any]
    
    var gameType: SimpleGameType? {
        guard let typeString = game["type"] as? String else { return nil }
        switch typeString {
        case "memory": return .memory
        case "color": return .color
        case "shape": return .shape
        case "sequence": return .sequence
        case "math": return .math
        case "emoji": return .emoji
        default: return nil
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let gameType = gameType {
                ZStack {
                    Circle().fill(gameType.color.opacity(0.3)).frame(width: 40, height: 40)
                    Image(systemName: gameType.icon).font(.system(size: 18)).foregroundColor(gameType.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let gameType = gameType {
                    Text(gameType.rawValue).font(.subheadline.bold()).foregroundColor(.white)
                } else {
                    Text("Unknown Game").font(.subheadline.bold()).foregroundColor(.white)
                }
                
                if let date = game["date"] as? String {
                    Text("Recently played")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if let score = game["score"] as? Int {
                Text("\(score) pts")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}


// MARK: - Menu Navigation Item
struct MenuNavigationItem: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Color indicator bar on left
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? color : color.opacity(0.3))
                    .frame(width: 4, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? color.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
