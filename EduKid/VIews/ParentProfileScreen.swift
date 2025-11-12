//
//  ParentProfileScreen.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation
import SwiftUI

struct ParentProfileScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordVisible = false
    @State private var newPasswordVisible = false
    @State private var confirmPasswordVisible = false
    @State private var showChangePassword = false
    @State private var showDeleteConfirmation = false
    @State private var activeSection: ProfileSection = .profile
    
    enum ProfileSection {
        case profile
        case password
    }
    
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
            DecorativeElementsProfile()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            authVM.authState = .parentDashboard
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for alignment
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer().frame(height: 32)
                    
                    // Section Selector
                    HStack(spacing: 0) {
                        Button(action: { activeSection = .profile }) {
                            Text("Profile")
                                .font(.system(size: 16, weight: activeSection == .profile ? .bold : .regular))
                                .foregroundColor(activeSection == .profile ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(activeSection == .profile ? Color.white.opacity(0.2) : Color.clear)
                        }
                        
                        Button(action: { activeSection = .password }) {
                            Text("Password")
                                .font(.system(size: 16, weight: activeSection == .password ? .bold : .regular))
                                .foregroundColor(activeSection == .password ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(activeSection == .password ? Color.white.opacity(0.2) : Color.clear)
                        }
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 32)
                    
                    // Content based on active section
                    if activeSection == .profile {
                        profileSection
                    } else {
                        passwordSection
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            if let parent = authVM.currentUser {
                name = parent.name
                email = parent.email
            }
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                authVM.deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 0) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                TextField("", text: $name)
                    .placeholder(when: name.isEmpty) {
                        Text("Enter your name")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .autocapitalization(.words)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                TextField("", text: $email)
                    .placeholder(when: email.isEmpty) {
                        Text("Enter your email")
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
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 32)
            
            // Error message
            if let errorMessage = authVM.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            
            // Update button
            Button(action: {
                authVM.updateProfile(
                    name: name.trimmingCharacters(in: .whitespaces).isEmpty ? nil : name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email.trimmingCharacters(in: .whitespaces)
                )
            }) {
                HStack {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                            .scaleEffect(0.8)
                    }
                    Text(authVM.isLoading ? "UPDATING..." : "UPDATE PROFILE")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(authVM.isLoading ? Color.white.opacity(0.7) : Color.white)
                .cornerRadius(30)
            }
            .disabled(authVM.isLoading)
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 40)
            
            // Delete Account button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Text("DELETE ACCOUNT")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(30)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Password Section
    private var passwordSection: some View {
        VStack(spacing: 0) {
            // Current Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    if passwordVisible {
                        TextField("", text: $currentPassword)
                            .placeholder(when: currentPassword.isEmpty) {
                                Text("Enter current password")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                    } else {
                        SecureField("", text: $currentPassword)
                            .placeholder(when: currentPassword.isEmpty) {
                                Text("Enter current password")
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
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // New Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    if newPasswordVisible {
                        TextField("", text: $newPassword)
                            .placeholder(when: newPassword.isEmpty) {
                                Text("Enter new password")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                    } else {
                        SecureField("", text: $newPassword)
                            .placeholder(when: newPassword.isEmpty) {
                                Text("Enter new password")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                    }
                    
                    Button(action: { newPasswordVisible.toggle() }) {
                        Text(newPasswordVisible ? "👁️" : "👁️‍🗨️")
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
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // Confirm Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm New Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    if confirmPasswordVisible {
                        TextField("", text: $confirmPassword)
                            .placeholder(when: confirmPassword.isEmpty) {
                                Text("Confirm new password")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                    } else {
                        SecureField("", text: $confirmPassword)
                            .placeholder(when: confirmPassword.isEmpty) {
                                Text("Confirm new password")
                                    .foregroundColor(.white.opacity(0.6))
                            }
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
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 32)
            
            // Error message
            if let errorMessage = authVM.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            
            // Change Password button
            Button(action: {
                authVM.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                    confirmPassword: confirmPassword
                )
            }) {
                HStack {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                            .scaleEffect(0.8)
                    }
                    Text(authVM.isLoading ? "CHANGING..." : "CHANGE PASSWORD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(authVM.isLoading ? Color.white.opacity(0.7) : Color.white)
                .cornerRadius(30)
            }
            .disabled(authVM.isLoading)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Decorative Elements Profile
struct DecorativeElementsProfile: View {
    var body: some View {
        ZStack {
            // Book and Globe - Top Center
            Image("book_and_globe")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .blur(radius: 1.5)
                .offset(x: 0, y: -350)
            
            // Coins - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .scaleEffect(x: -1, y: 1)
                .offset(x: 140, y: -340)
            
            // Coins - Top Left
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(15))
                .offset(x: -140, y: -330)
        }
    }
}

// MARK: - Preview
struct ParentProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ParentProfileScreen()
            .environmentObject(AuthViewModel())
    }
}
