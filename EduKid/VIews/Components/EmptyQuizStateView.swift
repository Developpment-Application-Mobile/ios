//
//  EmptyQuizStateView.swift
//  EduKid
//
//  Created by mac on 21/11/2025.
//


import SwiftUI


// MARK: - Empty Quiz State View
struct EmptyQuizStateView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Text Content
            VStack(spacing: 12) {
                Text("No Quizzes Yet")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Create your first smart quiz and watch your child learn with AI-powered adaptive learning")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Generate Button
            Button(action: onGenerate) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                    Text("Generate First Quiz")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(Color(hex: "272052"))
                .frame(width: 240, height: 56)
                .background(Color.white)
                .cornerRadius(28)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            
            Spacer()
        }
    }
}
