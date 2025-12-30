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
    
    // Field-specific error messages
    @State private var fullNameError: String? = nil
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    
    var onSignUpClick: (String, String, String, String) -> Void = { _, _, _, _ in }
    var onSignInClick: () -> Void = {}
    var onBackToWelcome: () -> Void = {}
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
                .zIndex(0)
            
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
                    VStack(alignment: .leading, spacing: 4) {
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
                                    .stroke(fullNameError != nil ? Color.red : Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .textInputAutocapitalization(.words)
                        
                        if let error = fullNameError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                    
                    Spacer().frame(height: 16)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 4) {
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
                                    .stroke(emailError != nil ? Color.red : Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        
                        if let error = emailError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                    
                    Spacer().frame(height: 16)
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 4) {
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
                                .stroke(passwordError != nil ? Color.red : Color.white.opacity(0.5), lineWidth: 1)
                        )
                        
                        if let error = passwordError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                    
                    Spacer().frame(height: 16)
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 4) {
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
                                .stroke(confirmPasswordError != nil ? Color.red : Color.white.opacity(0.5), lineWidth: 1)
                        )
                        
                        if let error = confirmPasswordError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
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
                    
                    // Sign up button
                    Button(action: {
                        guard !isLoading else { return }
                        
                        // Clear all previous errors
                        fullNameError = nil
                        emailError = nil
                        passwordError = nil
                        confirmPasswordError = nil
                        
                        // Validate each field
                        var hasError = false
                        
                        // Validate full name
                        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
                            fullNameError = "Full name cannot be blank"
                            hasError = true
                        }
                        
                        // Validate email
                        if email.trimmingCharacters(in: .whitespaces).isEmpty {
                            emailError = "Email cannot be blank"
                            hasError = true
                        } else if !isValidEmail(email) {
                            emailError = "Please enter a valid email address"
                            hasError = true
                        }
                        
                        // Validate password
                        if password.isEmpty {
                            passwordError = "Password cannot be blank"
                            hasError = true
                        } else if password.count < 6 {
                            passwordError = "Password must be at least 6 characters"
                            hasError = true
                        }
                        
                        // Validate confirm password
                        if confirmPassword.isEmpty {
                            confirmPasswordError = "Confirm password cannot be blank"
                            hasError = true
                        } else if password != confirmPassword {
                            confirmPasswordError = "Passwords do not match"
                            hasError = true
                        }
                        
                        // Only proceed if there are no errors
                        if !hasError {
                            onSignUpClick(fullName, email, password, confirmPassword)
                        }
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
            .zIndex(1)
            
            // Back Button (Top Left) - Above everything
            VStack {
                HStack {
                    Button(action: onBackToWelcome) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                Spacer()
            }
            .zIndex(10)
        }
    }
    
    // Helper function for email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
