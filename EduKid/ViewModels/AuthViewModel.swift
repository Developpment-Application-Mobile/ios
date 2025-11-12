
// AuthViewModel.swift
import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - États de Navigation
    enum AuthState: Equatable {
        case splash
        case welcome
        case parentSignUp
        case parentSignIn
        case parentDashboard
        case parentProfile
        case addChild
        case childDetail(Child)
        case childQRLogin
        case childHome(Child)
        case qrCodeDisplay(Child)

        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.splash, .splash), (.welcome, .welcome),
                 (.parentSignUp, .parentSignUp), (.parentSignIn, .parentSignIn),
                 (.parentDashboard, .parentDashboard), (.parentProfile, .parentProfile),
                 (.addChild, .addChild), (.childQRLogin, .childQRLogin):
                return true

            case let (.childDetail(c1), .childDetail(c2)),
                 let (.childHome(c1), .childHome(c2)),
                 let (.qrCodeDisplay(c1), .qrCodeDisplay(c2)):
                return c1.id == c2.id

            default:
                return false
            }
        }
    }
    @Published var authState: AuthState = .splash
    @Published var currentUser: Parent?
    @Published var selectedChild: Child?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService.shared

    init() {
        // Check for stored token and auto-login if "Remember Me" was enabled
        if authService.shouldRestoreSession() && authService.getToken() != nil {
            // Token exists, try to restore session
            Task {
                do {
                    let user = try await authService.getCurrentUser()
                    await MainActor.run {
                        // Create parent object from restored user
                        let parent = Parent(
                            name: user.name ?? "Parent",
                            email: user.email ?? "",
                            children: [], // You might want to fetch children separately
                            totalScore: 0,
                            isActive: true
                        )
                        self.currentUser = parent
                        self.authState = .parentDashboard
                    }
                } catch {
                    // Token is invalid, clear it and go to welcome
                    await MainActor.run {
                        authService.clearToken()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            self?.authState = .welcome
                        }
                    }
                }
            }
        } else {
            // Simuler un chargement
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.authState = .welcome
            }
        }
    }

    // MARK: - Auth Actions
    func signUp(fullName: String, email: String, password: String, confirmPassword: String) {
        // Clear previous error
        errorMessage = nil
        
        // Validate password match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        // Validate name
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your full name"
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Make API call
        Task {
            do {
                let response = try await authService.signUp(
                    name: fullName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    // Create parent object from response
                    let parent = Parent(
                        name: fullName.trimmingCharacters(in: .whitespaces),
                        email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                        children: [],
                        totalScore: 0,
                        isActive: true
                    )
                    
                    currentUser = parent
                    errorMessage = nil
                    authState = .parentDashboard
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Validation Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func signIn(email: String, password: String, rememberMe: Bool = false) {
        // Clear previous error
        errorMessage = nil
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        // Validate password
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Make API call
        Task {
            do {
                let response = try await authService.signIn(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    // Save token if remember me is checked
                    if let token = response.token {
                        authService.saveToken(token, rememberMe: rememberMe)
                        if rememberMe {
                            authService.saveUserEmail(email.trimmingCharacters(in: .whitespaces).lowercased())
                        }
                    }
                    
                    // Create parent object from response
                    let parentName = response.user?.name ?? "Parent"
                    let parentEmail = response.user?.email ?? email.trimmingCharacters(in: .whitespaces).lowercased()
                    
                    // For now, create parent with empty children - you might want to fetch children from API
                    let parent = Parent(
                        name: parentName,
                        email: parentEmail,
                        children: [],
                        totalScore: 0,
                        isActive: true
                    )
                    
                    currentUser = parent
                    errorMessage = nil
                    authState = .parentDashboard
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        // Clear token and user data
        authService.clearToken()
        currentUser = nil
        selectedChild = nil
        authState = .welcome
    }

    // MARK: - Enfant
    func addChild(name: String, age: Int, avatarEmoji: String) {
        let level = "\(age - 3)"
        let newChild = Child(
            name: name,
            age: age,
            level: level,
            avatarEmoji: avatarEmoji,
            Score: 0,
            quizzes: [],
            totalPoints: 0,
            connectionToken: UUID().uuidString
        )
        currentUser?.children.append(newChild)
        selectedChild = newChild
        authState = .parentDashboard
    }

    func selectChild(_ child: Child) {
        selectedChild = child
        authState = .childDetail(child)
    }

    // MARK: - QR Code
    func showQRCode(for child: Child) {
        selectedChild = child
        authState = .qrCodeDisplay(child)
    }

    func handleQRScan(token: String) {
        guard let child = currentUser?.children.first(where: { $0.connectionToken == token }) else {
            errorMessage = "QR Code invalide"
            return
        }
        selectedChild = child
        authState = .childHome(child)
    }

    // MARK: - Récompenses
    func addReward(to child: Child, name: String, cost: Int) {
        guard let childIndex = currentUser?.children.firstIndex(where: { $0.id == child.id }) else { return }
        let reward = Reward(name: name, cost: cost)
        currentUser?.children[childIndex].rewards.append(reward)
    }

    func updateReward(_ reward: Reward, name: String, cost: Int) {
        guard let child = selectedChild,
              let childIndex = currentUser?.children.firstIndex(where: { $0.id == child.id }),
              let rewardIndex = currentUser?.children[childIndex].rewards.firstIndex(where: { $0.id == reward.id }) else { return }
        currentUser?.children[childIndex].rewards[rewardIndex] = Reward(id: reward.id, name: name, cost: cost, isClaimed: reward.isClaimed)
    }

    func deleteReward(_ reward: Reward) {
        guard let child = selectedChild,
              let childIndex = currentUser?.children.firstIndex(where: { $0.id == child.id }) else { return }
        currentUser?.children[childIndex].rewards.removeAll { $0.id == reward.id }
    }

    func claimReward(_ reward: Reward) {
        guard let child = selectedChild,
              child.totalPoints >= reward.cost else { return }
        // Déduire les points + marquer comme réclamée
    }
    
    // MARK: - Profile Management
    func updateProfile(name: String?, email: String?) {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let updatedUser = try await authService.updateProfile(name: name, email: email)
                await MainActor.run {
                    isLoading = false
                    if let existingUser = currentUser {
                        currentUser = Parent(
                            name: updatedUser.name ?? existingUser.name,
                            email: updatedUser.email ?? existingUser.email,
                            children: existingUser.children,
                            totalScore: existingUser.totalScore,
                            isActive: existingUser.isActive
                        )
                    }
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) {
        errorMessage = nil
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteAccount() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await authService.deleteAccount()
                await MainActor.run {
                    isLoading = false
                    signOut()
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

