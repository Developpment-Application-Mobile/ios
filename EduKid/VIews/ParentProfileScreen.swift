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
    @State private var showLogoutConfirmation = false
    @State private var activeSection: ProfileSection = .profile
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false
    
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
                    // Header (without back button)
                    HStack {
                        Spacer()
                        
                        Text("Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer().frame(height: 32)
                    
                    // Section Selector
                    HStack(spacing: 0) {
                        Button(action: {
                            activeSection = .profile
                            clearMessages()
                        }) {
                            Text("Profile")
                                .font(.system(size: 16, weight: activeSection == .profile ? .bold : .regular))
                                .foregroundColor(activeSection == .profile ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(activeSection == .profile ? Color.white.opacity(0.2) : Color.clear)
                        }
                        
                        Button(action: {
                            activeSection = .password
                            clearMessages()
                        }) {
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
                handleDeleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authVM.signOut()
            }
        } message: {
            Text("Are you sure you want to logout?")
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
                
                TextField(
                    "",
                    text: $name,
                    prompt: Text("Enter your name")
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
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                TextField(
                    "",
                    text: $email,
                    prompt: Text("Enter your email")
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
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 32)
            
            // Success message
            if let successMessage = successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            
            // Update button
            Button(action: handleUpdateProfile) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "UPDATING..." : "UPDATE PROFILE")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(isLoading ? Color.white.opacity(0.7) : Color.white)
                .cornerRadius(30)
            }
            .disabled(isLoading)
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 16)
            
            // Logout button
            Button(action: {
                showLogoutConfirmation = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.square.fill")
                        .font(.system(size: 18))
                    Text("LOGOUT")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(0.8),
                            Color.red.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 16)
            
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
                        TextField(
                            "",
                            text: $currentPassword,
                            prompt: Text("Enter current password")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                    } else {
                        SecureField(
                            "",
                            text: $currentPassword,
                            prompt: Text("Enter current password")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                    }
                    
                    Button(action: { passwordVisible.toggle() }) {
                        Image(systemName: passwordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 18))
                    }
                }
                .foregroundColor(Color.white)
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
                        TextField(
                            "",
                            text: $newPassword,
                            prompt: Text("Enter new password")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                    } else {
                        SecureField(
                            "",
                            text: $newPassword,
                            prompt: Text("Enter new password")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                    }
                    
                    Button(action: { newPasswordVisible.toggle() }) {
                        Image(systemName: newPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 18))
                    }
                }
                .foregroundColor(Color.white)
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
                        TextField(
                            "",
                            text: $confirmPassword,
                            prompt: Text("Confirm new password")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                    } else {
                        SecureField(
                            "",
                            text: $confirmPassword,
                            prompt: Text("Confirm new password")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                    }
                    
                    Button(action: { confirmPasswordVisible.toggle() }) {
                        Image(systemName: confirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 18))
                    }
                }
                .foregroundColor(Color.white)
                .frame(height: 60)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 32)
            
            // Success message
            if let successMessage = successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            
            // Change Password button
            Button(action: handleChangePassword) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "CHANGING..." : "CHANGE PASSWORD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(isLoading ? Color.white.opacity(0.7) : Color.white)
                .cornerRadius(30)
            }
            .disabled(isLoading)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Functions
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    private func handleUpdateProfile() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Email cannot be empty"
            return
        }
        
        clearMessages()
        isLoading = true
        
        Task {
            do {
                try await authVM.updateProfile(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces)
                )
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "Profile updated successfully!"
                    
                    // Update local state with new values
                    if let parent = authVM.currentUser {
                        name = parent.name
                        email = parent.email
                    }
                    
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
    
    private func handleChangePassword() {
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
        
        clearMessages()
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
                    
                    // Clear password fields
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    
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
    
    private func handleDeleteAccount() {
        isLoading = true
        
        Task {
            do {
                try await authVM.deleteAccount()
                
                await MainActor.run {
                    isLoading = false
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
