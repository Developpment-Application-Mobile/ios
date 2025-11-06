//
//  HomeScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab = 0
    let childName = "Moss"
    let points = 602
    
    let sampleQuizzes = [
        Quiz(title: "Advanced Calculus", questions: [], completionPercentage: 65, type: .math),
        Quiz(title: "Biology Basics", questions: [], completionPercentage: 40, type: .science),
        Quiz(title: "World War II", questions: [], completionPercentage: 80, type: .history),
        Quiz(title: "European Capitals", questions: [], completionPercentage: 10, type: .geography),
        Quiz(title: "Shakespeare Works", questions: [], completionPercentage: 30, type: .literature),
        Quiz(title: "General Knowledge", questions: [], completionPercentage: 75, type: .general)
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
                        ForEach(sampleQuizzes) { quiz in
                            UnfinishedGameItem(quiz: quiz)
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
    let quiz: Quiz
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(quiz.type.iconRes)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .frame(width: 48, height: 48)
                .background(quiz.type.backgroundColor)
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
                    .trim(from: 0, to: CGFloat(quiz.completionPercentage) / 100)
                    .stroke(quiz.type.progressColor, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(quiz.completionPercentage)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(quiz.type.progressColor)
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

// MARK: - Quiz Model
struct Quiz: Identifiable {
    let id = UUID()
    let title: String
    let questions: [String]
    let completionPercentage: Int
    let type: QuizType
}

enum QuizType {
    case math, science, history, geography, literature, general
    
    var iconRes: String {
        switch self {
        case .math: return "calculator"
        case .science: return "flask"
        case .history: return "book"
        case .geography: return "globe"
        case .literature: return "book.pages"
        case .general: return "star"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .math: return Color(red: 1.0, green: 0.8, blue: 0.8)
        case .science: return Color(red: 0.8, green: 1.0, blue: 0.8)
        case .history: return Color(red: 0.8, green: 0.8, blue: 1.0)
        case .geography: return Color(red: 1.0, green: 1.0, blue: 0.8)
        case .literature: return Color(red: 1.0, green: 0.9, blue: 1.0)
        case .general: return Color(red: 0.9, green: 0.9, blue: 0.9)
        }
    }
    
    var progressColor: Color {
        switch self {
        case .math: return Color(red: 0.988, green: 0.376, blue: 0.286)
        case .science: return Color(red: 0.298, green: 0.686, blue: 0.314)
        case .history: return Color(red: 0.573, green: 0.478, blue: 1.0)
        case .geography: return Color(red: 1.0, green: 0.757, blue: 0.027)
        case .literature: return Color(red: 0.906, green: 0.298, blue: 0.235)
        case .general: return Color(red: 0.4, green: 0.4, blue: 0.4)
        }
    }
}

// MARK: - Preview
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
