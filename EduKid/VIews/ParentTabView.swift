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
                
                // Games and Activities Tab (Quizzes + Puzzles + Schedule + Shop)
                ParentGamesAndActivitiesScreen(parent: parent)
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
                title: "Activities",
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

// MARK: - Parent Games and Activities Screen (Quizzes + Puzzles + Schedule + Shop)
struct ParentGamesAndActivitiesScreen: View {
    let parent: Parent
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedChild: Child?
    @State private var selectedActivityType = 0 // 0: Quizzes, 1: Puzzles, 2: Schedule, 3: Shop
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Games & Activities")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Manage learning activities for your children")
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
                        Text("Add a child first to create activities")
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
                        Text("Choose which child to manage activities for")
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
                    // Activity Type Selector + Content
                    VStack(spacing: 0) {
                        // Child Info Header with Activity Title
                        HStack(spacing: 12) {
                            Image(selectedChild!.avatarEmoji)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(selectedChild!.name)'s \(getActivityTitle())")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Age \(selectedChild!.age) • Level \(selectedChild!.level)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button(action: { selectedChild = nil }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 11))
                                    Text("Change")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Activity Type Tabs - Non-scrollable, all visible
                        HStack(spacing: 8) {
                            ModernActivityTab(
                                title: "Quizzes",
                                icon: "doc.text.fill",
                                color: Color.green,
                                isSelected: selectedActivityType == 0
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedActivityType = 0
                                }
                            }
                            
                            ModernActivityTab(
                                title: "Puzzles",
                                icon: "puzzlepiece.fill",
                                color: Color.orange,
                                isSelected: selectedActivityType == 1
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedActivityType = 1
                                }
                            }
                            
                            ModernActivityTab(
                                title: "Schedule",
                                icon: "calendar.badge.clock",
                                color: Color.blue,
                                isSelected: selectedActivityType == 2
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedActivityType = 2
                                }
                            }
                            
                            ModernActivityTab(
                                title: "Shop",
                                icon: "cart.fill",
                                color: Color.pink,
                                isSelected: selectedActivityType == 3
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedActivityType = 3
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Content based on selected type
                        if selectedActivityType == 0 {
                            ParentQuizListScreen(child: selectedChild!)
                        } else if selectedActivityType == 1 {
                            ParentPuzzleListScreen(child: selectedChild!)
                        } else if selectedActivityType == 2 {
                            ParentScheduleScreen(child: selectedChild!)
                        } else {
                            ParentShopManagementScreen(child: selectedChild!)
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to get activity title
    private func getActivityTitle() -> String {
        switch selectedActivityType {
        case 0: return "Quizzes"
        case 1: return "Puzzles"
        case 2: return "Schedule"
        case 3: return "Shop"
        default: return "Activities"
        }
    }
}

// MARK: - Modern Activity Tab
struct ModernActivityTab: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(isSelected ? 0.3 : 0.15),
                                    color.opacity(isSelected ? 0.15 : 0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? color : color.opacity(0.7))
                }
                
                // Title
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
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
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? color.opacity(0.5) : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// MARK: - Parent Schedule Screen
struct ParentScheduleScreen: View {
    let child: Child
    
    var body: some View {
        ParentScheduleTabView(child: child)
    }
}

// MARK: - Parent Shop Management Screen
struct ParentShopManagementScreen: View {
    let child: Child
    
    var body: some View {
        if let parentId = AuthService.shared.getParentId() {
            GiftManagementView(childId: child.id, parentId: parentId)
        } else {
            Text("Error: Parent not found")
                .foregroundColor(.white)
        }
    }
}
