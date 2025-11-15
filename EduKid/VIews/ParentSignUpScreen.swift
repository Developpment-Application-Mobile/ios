//
//  ParentSignUpScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct ParentSignUpScreen: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordVisible = false
    @State private var confirmPasswordVisible = false
    
    var onSignUpClick: (String, String, String, String) -> Void = { _, _, _, _ in }
    var onSignInClick: () -> Void = {}
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
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
            DecorativeElementsSignUp()
            
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 150)
                    
                    // Title
                    Text("Create Parent\nAccount")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    Spacer().frame(height: 10)
                    
                    Text("Join us to guide your child's learning adventure")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Spacer().frame(height: 32)
                    
                    // Full Name field
                    TextField(
                        "",
                        text: $fullName,
                        prompt: Text("Full Name")
                            .foregroundColor(Color.white.opacity(0.6))
                    )
                        .foregroundColor(Color.white)
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.words)
                    
                    Spacer().frame(height: 16)
                    
                    // Email field
                    TextField(
                        "",
                        text: $email,
                        prompt: Text("Email")
                            .foregroundColor(Color.white.opacity(0.6))
                    )
                        .foregroundColor(Color.white)
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    Spacer().frame(height: 16)
                    
                    // Password field
                    HStack {
                        if passwordVisible {
                            TextField(
                                "",
                                text: $password,
                                prompt: Text("Password")
                                    .foregroundColor(Color.white.opacity(0.6))
                            )
                        } else {
                            SecureField(
                                "",
                                text: $password,
                                prompt: Text("Password")
                                    .foregroundColor(Color.white.opacity(0.6))
                            )
                        }
                        
                        Button(action: { passwordVisible.toggle() }) {
                            Text(passwordVisible ? "👁️" : "👁️‍🗨️")
                                .font(.system(size: 18))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    
                    Spacer().frame(height: 16)
                    
                    // Confirm Password field
                    HStack {
                        if confirmPasswordVisible {
                            TextField(
                                "",
                                text: $confirmPassword,
                                prompt: Text("Confirm Password")
                                    .foregroundColor(Color.white.opacity(0.6))
                            )
                        } else {
                            SecureField(
                                "",
                                text: $confirmPassword,
                                prompt: Text("Confirm Password")
                                    .foregroundColor(Color.white.opacity(0.6))
                            )
                        }
                        
                        Button(action: { confirmPasswordVisible.toggle() }) {
                            Text(confirmPasswordVisible ? "👁️" : "👁️‍🗨️")
                                .font(.system(size: 18))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    
                    Spacer().frame(height: 32)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    
                    // Sign up button
                    Button(action: {
                        guard !isLoading else { return }
                        onSignUpClick(fullName, email, password, confirmPassword)
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "CREATING..." : "CREATE ACCOUNT")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(isLoading ? Color.white.opacity(0.7) : Color.white)
                        .cornerRadius(30)
                    }
                    .disabled(isLoading)
                    
                    Spacer().frame(height: 24)
                    
                    // Sign in prompt
                    HStack {
                        Text("Already have an account? ")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Button(action: onSignInClick) {
                            Text("Sign In")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer().frame(height: 150)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Decorative Elements SignUp
struct DecorativeElementsSignUp: View {
    var body: some View {
        ZStack {
            // Book and Globe - Top Center (smaller and blurred)
            Image("book_and_globe")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .blur(radius: 1.5)
                .offset(x: 0, y: -320)
            
            // Coins - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .scaleEffect(x: -1, y: 1)
                .offset(x: 140, y: -310)
            
            // Coins - Top Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(15))
                .offset(x: -140, y: -300)
            
            // Book Stacks - Bottom Right
            Image("book_stacks")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .blur(radius: 2)
                .offset(x: 130, y: 350)
            
            // Coins - Bottom Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .rotationEffect(.degrees(38.66))
                .offset(x: -150, y: 360)
        }
    }
}

// MARK: - Preview
struct ParentSignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        ParentSignUpScreen()
    }
}
