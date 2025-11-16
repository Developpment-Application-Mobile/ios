//
//  HomeScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//  Fixed: November 15, 2025 - Removed duplicate Quiz struct
//

import Foundation
import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab = 0
    let childName = "Moss"
    let points = 602
    
    let sampleQuizzes = [
        quiz(title: "Advanced Calculus", category: "Math", questions: [], completionPercentage: 65, type: .math),
        quiz(title: "Biology Basics", category: "Science", questions: [], completionPercentage: 40, type: .science),
        quiz(title: "World War II", category: "History", questions: [], completionPercentage: 80, type: .history),
        quiz(title: "European Capitals", category: "Geography", questions: [], completionPercentage: 10, type: .geography),
        quiz(title: "Shakespeare Works", category: "English", questions: [], completionPercentage: 30, type: .english),
        quiz(title: "General Knowledge", category: "General", questions: [], completionPercentage: 75, type: .general)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.988, green: 0.988, blue: 0.996)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Header(name: childName, points: points)
                
                Spacer().frame(height: 34)
                
                // Title
                Text("What would you like to play today?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(red: 0.275, green: 0.335, blue: 0.482))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 15)
                
                // Featured Quiz Cards
                FeaturedQuizCards()
                
                Spacer().frame(height: 16)
                
                // Page Indicator
                PageIndicator()
                
                Spacer().frame(height: 20)
                
                // Unfinished Games Title
                Text("Unfinished Games")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.275, green: 0.335, blue: 0.482))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 13)
                
                // Unfinished Games List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sampleQuizzes) { quizItem in
                            UnfinishedGameItem(quiz: quizItem)
                        }
                    }
                    .padding(.bottom, 90)
                }
            }
            
            // Bottom Navigation Bar
            BottomNavigationBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Header
struct Header: View {
    let name: String
    let points: Int
    
    var body: some View {
        HStack {
            Text("Hello, \(name)!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.275, green: 0.335, blue: 0.482))
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(points)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                
                Image("coins")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .clipShape(Circle())
                    .padding(.trailing, 4)
            }
            .frame(height: 34)
            .background(Color(red: 0.573, green: 0.478, blue: 1.0))
            .cornerRadius(17)
        }
        .padding(.horizontal, 20)
        .padding(.top, 52)
    }
}

// MARK: - Featured Quiz Cards
struct FeaturedQuizCards: View {
    var body: some View {
        HStack(spacing: 11) {
            FeaturedQuizCard(
                title: "Sport Quiz",
                questions: "20 Questions",
                progress: 66,
                imageRes: "sport",
                progressColor: Color(red: 0.573, green: 0.478, blue: 1.0)
            )
            
            FeaturedQuizCard(
                title: "Science Quiz",
                questions: "20 Questions",
                progress: 66,
                imageRes: "science",
                progressColor: Color(red: 0.988, green: 0.376, blue: 0.286)
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Featured Quiz Card
struct FeaturedQuizCard: View {
    let title: String
    let questions: String
    let progress: Int
    let imageRes: String
    let progressColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Image(imageRes)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.275, green: 0.335, blue: 0.482))
                
                Text(questions)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.776, green: 0.757, blue: 0.878))
                
                Spacer().frame(height: 5)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.949, green: 0.941, blue: 0.973))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * CGFloat(progress) / 100, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(12)
        }
        .frame(height: 203)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.949, green: 0.941, blue: 0.973), lineWidth: 1)
        )
    }
}

// MARK: - Page Indicator
struct PageIndicator: View {
    var body: some View {
        HStack(spacing: 2.32) {
            ForEach([Color(red: 0.573, green: 0.478, blue: 1.0),
                     Color(red: 0.906, green: 0.898, blue: 0.949),
                     Color(red: 0.906, green: 0.898, blue: 0.949)], id: \.self) { color in
                RoundedRectangle(cornerRadius: 100)
                    .fill(color)
                    .frame(width: 15.45, height: 4)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Unfinished Game Item
struct UnfinishedGameItem: View {
    let quiz: quiz
    
    var iconRes: String {
        switch quiz.type ?? .general {
        case .math: return "function"
        case .science: return "flask"
        case .english: return "book"
        case .history: return "clock"
        case .geography: return "globe"
        case .general: return "star"
        }
    }
    
    var backgroundColor: Color {
        switch quiz.type ?? .general {
        case .math: return Color.blue.opacity(0.2)
        case .science: return Color.green.opacity(0.2)
        case .english: return Color.purple.opacity(0.2)
        case .history: return Color.orange.opacity(0.2)
        case .geography: return Color.cyan.opacity(0.2)
        case .general: return Color.yellow.opacity(0.2)
        }
    }
    
    var progressColor: Color {
        switch quiz.type ?? .general {
        case .math: return .blue
        case .science: return .green
        case .english: return .purple
        case .history: return .orange
        case .geography: return .cyan
        case .general: return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconRes)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(width: 48, height: 48)
                .background(backgroundColor)
                .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.275, green: 0.335, blue: 0.482))
                
                Text("\(quiz.questions.count) Questions")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.776, green: 0.757, blue: 0.878))
            }
            
            Spacer()
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color(red: 0.949, green: 0.941, blue: 0.973), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: CGFloat(quiz.completionPercentage ?? 0) / 100)
                    .stroke(progressColor, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(quiz.completionPercentage ?? 0)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(progressColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(height: 70)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.949, green: 0.941, blue: 0.973), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            Button(action: { selectedTab = 0 }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 0 ? Color(red: 0.573, green: 0.478, blue: 1.0) : Color(red: 0.875, green: 0.863, blue: 0.929))
                    .frame(width: 38, height: 38)
            }
            
            Spacer()
            
            Button(action: { selectedTab = 1 }) {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 1 ? Color(red: 0.573, green: 0.478, blue: 1.0) : Color(red: 0.875, green: 0.863, blue: 0.929))
                    .frame(width: 38, height: 38)
            }
            
            Spacer()
            
            Button(action: { selectedTab = 2 }) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 2 ? Color(red: 0.573, green: 0.478, blue: 1.0) : Color(red: 0.875, green: 0.863, blue: 0.929))
                    .frame(width: 38, height: 38)
            }
            
            Spacer()
        }
        .frame(height: 70)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
    }
}

// MARK: - Preview
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
