//
//  ParentDashboardScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct ParentDashboardScreen: View {
    let parent: Parent
    var onAddChildClick: () -> Void = {}
    var onChildClick: (Child) -> Void = { _ in }
    var onLogoutClick: () -> Void = {}
    
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
            
            // Decorative elements
            DecorativeElementsDashboard()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Parent Dashboard")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Manage your children's learning")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    // Logout button
                    Button(action: onLogoutClick) {
                        Text("🚪")
                            .font(.system(size: 20))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 24)
                
                // Add Child Button
                Button(action: onAddChildClick) {
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
                    // Empty state
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
                    // Children cards
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(parent.children) { child in
                                ChildCard(child: child) {
                                    onChildClick(child)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Child Card
struct ChildCard: View {
    let child: Child
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Avatar
                    Text(child.avatarEmoji)
                        .font(.system(size: 32))
                        .frame(width: 60, height: 60)
                        .background(Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.2))
                        .clipShape(Circle())
                    
                    Spacer().frame(width: 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        
                        Text("Age \(child.age) • Level \(child.level)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    
                    Spacer()
                    
                    Text("▶")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.686, green: 0.494, blue: 0.906))
                }
                
                Spacer().frame(height: 16)
                
                // Progress bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Quiz Progress")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        
                        Spacer()
                        
                        Text("\(child.getCompletedQuizzes().count)/\(child.quizzes.count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.88, green: 0.88, blue: 0.88))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.686, green: 0.494, blue: 0.906))
                                .frame(
                                    width: geometry.size.width * (child.quizzes.isEmpty ? 0 : CGFloat(child.getCompletedQuizzes().count) / CGFloat(child.quizzes.count)),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
                
                Spacer().frame(height: 16)
                
                // Stats row
                HStack(spacing: 0) {
                    StatItem(
                        label: "Average Score",
                        value: "\(child.Score)%",
                        icon: "⭐"
                    )
                    
                    Rectangle()
                        .fill(Color(red: 0.88, green: 0.88, blue: 0.88))
                        .frame(width: 1, height: 40)
                        .padding(.horizontal, 20)
                    
                    StatItem(
                        label: "Completed",
                        value: "\(child.getCompletedQuizzes().count)",
                        icon: "✅"
                    )
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.95))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 16))
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
            }
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Decorative Elements Dashboard
struct DecorativeElementsDashboard: View {
    var body: some View {
        ZStack {
            // Education Book - Top Left (smaller)
            Image("education_book")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .blur(radius: 1)
                .offset(x: -140, y: -320)
            
            // Coins - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .offset(x: 145, y: -310)
            
            // Coins - Bottom Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(38.66))
                .offset(x: -140, y: 360)
        }
    }
}

// MARK: - Parent Model (if not already defined)
struct Parent: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    var children: [Child]
    let totalScore: Int
    let isActive: Bool
}

// MARK: - Preview
struct ParentDashboardScreen_Previews: PreviewProvider {
    static var previews: some View {
        let sampleChildren = [
            Child(
                name: "Emma",
                age: 8,
                level: "3",
                avatarEmoji: "👧",
                Score: 85,
                quizzes: [], connectionToken: "eee"
            ),
            Child(
                name: "Lucas",
                age: 6,
                level: "1",
                avatarEmoji: "👦",
                Score: 200,
                quizzes: [], connectionToken: "ccc"
            )
        ]
        
        let parent = Parent(
            name: "John Doe",
            email: "john.doe@example.com",
            children: sampleChildren,
            totalScore: 0,
            isActive: true
        )
        
        ParentDashboardScreen(parent: parent)
    }
}
