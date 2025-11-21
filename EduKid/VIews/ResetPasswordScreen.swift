//
//  ResetPasswordScreen.swift
//  EduKid
//
//  Created by mac on 17/11/2025.
//

import SwiftUI

struct ResetPasswordScreen: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @EnvironmentObject var authVM: AuthViewModel
    
    var token: String

    var body: some View {
        ZStack {
            // Background gradient - matching ForgotPasswordScreen
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
            DecorativeElementsResetPassword()

            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 120)

                    // Icon
                    Image(systemName: "lock.rotation.open")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    // Title
                    Text("Reset Password")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 10)

                    // Description
                    Text("Enter your new password below")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Spacer().frame(height: 40)

                    // New password field
                    SecureField(
                        "",
                        text: $newPassword,
                        prompt: Text("New Password")
                            .foregroundColor(Color.white.opacity(0.6))
                    )
                        .foregroundColor(Color.white)
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)

                    Spacer().frame(height: 16)

                    // Confirm password field
                    SecureField(
                        "",
                        text: $confirmPassword,
                        prompt: Text("Confirm New Password")
                            .foregroundColor(Color.white.opacity(0.6))
                    )
                        .foregroundColor(Color.white)
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)

                    Spacer().frame(height: 32)

                    // Success message
                    if let successMessage = authVM.successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }

                    // Error message
                    if let errorMessage = authVM.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    // Reset password button
                    Button(action: {
                        guard !authVM.isLoading else { return }
                        authVM.resetPassword(token: token, newPassword: newPassword, confirm: confirmPassword)
                    }) {
                        HStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                                    .scaleEffect(0.8)
                            }
                            Text(authVM.isLoading ? "UPDATING..." : "RESET PASSWORD")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(authVM.isLoading ? Color.white.opacity(0.7) : Color.white)
                        .cornerRadius(30)
                    }
                    .disabled(authVM.isLoading)

                    Spacer().frame(height: 24)

                    // Back to sign in
                    Button(action: {
                        authVM.authState = .parentSignIn
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back to Sign In")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Decorative Elements Reset Password
struct DecorativeElementsResetPassword: View {
    var body: some View {
        ZStack {
            // Education Book - Top Left
            Image("education_book")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .blur(radius: 1)
                .offset(x: -140, y: -300)
            
            // Coins - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .offset(x: 140, y: -290)
            
            // Book Stacks - Bottom Right
            Image("book_stacks")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
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
struct ResetPasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordScreen(token: "dummy-token")
            .environmentObject(AuthViewModel())
    }
}
