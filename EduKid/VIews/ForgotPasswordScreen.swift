//
//  ForgotPasswordScreen.swift
//  EduKid
//
//  Created by mac on 13/11/2025.
//

import Foundation
import SwiftUI

struct ForgotPasswordScreen: View {
    
    @State private var email = ""
       @EnvironmentObject var authVM: AuthViewModel
       
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
               DecorativeElementsForgotPassword()
               
               // Main content
               ScrollView {
                   VStack(spacing: 0) {
                       Spacer().frame(height: 120)
                       
                       // Icon
                       Image(systemName: "lock.rotation")
                           .font(.system(size: 60))
                           .foregroundColor(.white)
                           .padding(.bottom, 20)
                       
                       // Title
                       Text("Forgot Password?")
                           .font(.system(size: 32, weight: .medium))
                           .foregroundColor(.white)
                           .multilineTextAlignment(.center)
                       
                       Spacer().frame(height: 10)
                       
                       Text("Enter your email address and we'll send you a link to reset your password")
                           .font(.system(size: 14))
                           .foregroundColor(.white.opacity(0.9))
                           .multilineTextAlignment(.center)
                           .padding(.horizontal, 30)
                       
                       Spacer().frame(height: 40)
                       
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
                       
                       Spacer().frame(height: 32)
                       
                       // Success message with continue button
                       if let successMessage = authVM.successMessage {
                           VStack(spacing: 16) {
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
                               
                               // Continue to reset password button
                               Button(action: {
                                   // Use a mock token to navigate to reset screen
                                   authVM.handleResetPasswordToken("mock-reset-token-\(UUID().uuidString)")
                               }) {
                                   HStack {
                                       Image(systemName: "arrow.right.circle.fill")
                                       Text("Continue to Reset Password")
                                           .font(.system(size: 16, weight: .semibold))
                                   }
                                   .foregroundColor(.white)
                                   .padding()
                                   .frame(maxWidth: .infinity)
                                   .background(Color.blue)
                                   .cornerRadius(10)
                               }
                           }
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
                           authVM.requestPasswordReset(email: email)
                       }) {
                           HStack {
                               if authVM.isLoading {
                                   ProgressView()
                                       .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.18, green: 0.18, blue: 0.18)))
                                       .scaleEffect(0.8)
                               }
                               Text(authVM.isLoading ? "SENDING..." : "SEND RESET LINK")
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
// MARK: - Decorative Elements Forgot Password
struct DecorativeElementsForgotPassword: View {
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
struct ForgotPasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordScreen()
            .environmentObject(AuthViewModel())
    }
}
