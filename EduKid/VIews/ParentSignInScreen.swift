//
//  ParentSignInScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct ParentSignInScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var passwordVisible = false
    @State private var rememberMe = false
    
    var onSignInClick: (String, String, Bool) -> Void = { _, _, _ in }
    var onSignUpClick: () -> Void = {}
    var onForgotPasswordClick: () -> Void = {}
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
            DecorativeElementsSignIn()
            
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 100)
                    
                    // Title
                    Text("Welcome Back,\nParent!")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    Spacer().frame(height: 10)
                    
                    Text("Sign in to manage your child's learning journey")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Spacer().frame(height: 40)
                    
                    // Email field
                    TextField("", text: $email)
                        .placeholder(when: email.isEmpty) {
                            Text("Email")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .foregroundColor(.white)
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Spacer().frame(height: 16)
                    
                    // Password field
                    HStack {
                        if passwordVisible {
                            TextField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("Password")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                        } else {
                            SecureField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("Password")
                                        .foregroundColor(.white.opacity(0.6))
                                }
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
                    
                    Spacer().frame(height: 12)
                    
                    // Remember Me checkbox
                    HStack {
                        Button(action: { rememberMe.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                    .foregroundColor(rememberMe ? .white : .white.opacity(0.7))
                                    .font(.system(size: 18))
                                Text("Remember Me")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: onForgotPasswordClick) {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
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
                    
                    // Sign in button
                    Button(action: {
                        guard !isLoading else { return }
                        onSignInClick(email, password, rememberMe)
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "SIGNING IN..." : "SIGN IN")
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
                    
                    // Sign up prompt
                    HStack {
                        Text("Don't have an account? ")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Button(action: onSignUpClick) {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .onAppear {
                    // Pre-fill email if "Remember Me" was previously checked
                    if let savedEmail = AuthService.shared.getUserEmail() {
                        email = savedEmail
                        rememberMe = true
                    }
                }
            }
        }
    }
}

// MARK: - Decorative Elements SignIn
struct DecorativeElementsSignIn: View {
    var body: some View {
        ZStack {
            // Education Book - Top Left (smaller)
            Image("education_book")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .blur(radius: 1)
                .offset(x: -140, y: -300)
            
            // Coins - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .offset(x: 140, y: -290)
            
            // Book Stacks - Bottom Right
            Image("book_stacks")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .blur(radius: 2)
                .offset(x: 120, y: 320)
            
            // Coins - Bottom Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(38.66))
                .offset(x: -140, y: 350)
        }
    }
}

// MARK: - Preview
struct ParentSignInScreen_Previews: PreviewProvider {
    static var previews: some View {
        ParentSignInScreen()
    }
}
