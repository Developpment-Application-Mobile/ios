import Foundation
import SwiftUI

struct ParentSignInScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var passwordVisible = false
    
    // Field-specific error messages
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    
    var onSignInClick: (String, String) -> Void = { _, _ in }
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
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(
                            "",
                            text: $email,
                            prompt: Text("Email")
                                .foregroundColor(Color.white.opacity(0.6))
                        )
                            .foregroundColor(.white)
                            .frame(height: 60)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(emailError != nil ? Color.red : Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
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
                                Image(systemName: passwordVisible ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.white.opacity(0.7))
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
                    
                    Spacer().frame(height: 12)
                    
                    // Forgot Password
                    HStack {
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
                        
                        // Clear all previous errors
                        emailError = nil
                        passwordError = nil
                        
                        // Validate each field
                        var hasError = false
                        
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
                        }
                        
                        // Only proceed if there are no errors
                        if !hasError {
                            onSignInClick(email, password)
                        }
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
            }
        }
        .onAppear {
            print("\n📱 SIGN IN SCREEN: onAppear called")
            
            // Auto-restore saved email for mobile convenience
            if let savedEmail = AuthService.shared.getSavedEmail(), !savedEmail.isEmpty {
                print("📱 SIGN IN SCREEN: Restoring email: \(savedEmail)")
                email = savedEmail
            } else {
                print("📱 SIGN IN SCREEN: No saved email to restore")
                email = ""
            }
        }
    }
    
    // Helper function for email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
