//
//  EditParentProfileScreen.swift
//  EduKid
//
//  Created by mac on 15/11/2025.
//

import SwiftUI

struct EditParentProfileScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var email: String
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showChangePassword = false
    @State private var showDeleteAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    init() {
        _name = State(initialValue: "")
        _email = State(initialValue: "")
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "AF7EE7").opacity(0.6),
                    Color(hex: "272052")
                ]),
                center: .init(x: 0.15, y: 0.15),
                startRadius: 50,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Profile")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Update your information")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Profile Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Profile Information")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("", text: $name)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("", text: $email)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    // Save Profile Button
                    Button(action: saveProfile) {
                        HStack {
                            if isLoading && !showChangePassword {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading && !showChangePassword ? "SAVING..." : "SAVE CHANGES")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "2E2E2E"))
                        .cornerRadius(30)
                    }
                    .disabled(isLoading)
                    
                    // Change Password Section
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: { showChangePassword.toggle() }) {
                            HStack {
                                Text("Change Password")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: showChangePassword ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        if showChangePassword {
                            VStack(spacing: 16) {
                                // Current Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Password")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    SecureField("", text: $currentPassword)
                                        .padding()
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                
                                // New Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("New Password")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    SecureField("", text: $newPassword)
                                        .padding()
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                
                                // Confirm Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm New Password")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    SecureField("", text: $confirmPassword)
                                        .padding()
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                
                                Button(action: changePassword) {
                                    HStack {
                                        if isLoading && showChangePassword {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                                .scaleEffect(0.8)
                                        }
                                        Text(isLoading && showChangePassword ? "CHANGING..." : "CHANGE PASSWORD")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.white)
                                    .foregroundColor(Color(hex: "2E2E2E"))
                                    .cornerRadius(30)
                                }
                                .disabled(isLoading)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    
                    // Success/Error Messages
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(12)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                    
                    // Delete Account Button
                    Button(action: { showDeleteAlert = true }) {
                        Text("DELETE ACCOUNT")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .onAppear {
            if let user = authVM.currentUser {
                name = user.name
                email = user.email
            }
        }
    }
    
    private func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Email cannot be empty"
            return
        }
        
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        Task {
            do {
                try await authVM.updateProfile(name: name, email: email)
                await MainActor.run {
                    isLoading = false
                    successMessage = "Profile updated successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func changePassword() {
        guard !currentPassword.isEmpty else {
            errorMessage = "Please enter your current password"
            return
        }
        
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        Task {
            do {
                try await authVM.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                    confirmPassword: confirmPassword
                )
                await MainActor.run {
                    isLoading = false
                    successMessage = "Password changed successfully!"
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        successMessage = nil
                        showChangePassword = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteAccount() {
        isLoading = true
        Task {
            do {
                try await authVM.deleteAccount()
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}


