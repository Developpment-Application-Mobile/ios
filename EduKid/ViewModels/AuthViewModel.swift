import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - États de Navigation
    enum AuthState: Equatable {
        case splash
        case welcome
        case parentSignUp
        case parentSignIn
        case forgotPassword
        case parentDashboard
        case parentProfile
        case editParentProfile
        case addChild
        case childDetail(Child)
        case editChildProfile(Child)
        case childQRLogin
        case childHome(Child)
        case qrCodeDisplay(Child)
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.splash, .splash), (.welcome, .welcome),
                (.parentSignUp, .parentSignUp), (.parentSignIn, .parentSignIn),
                (.forgotPassword, .forgotPassword),
                (.parentDashboard, .parentDashboard), (.parentProfile, .parentProfile),
                (.editParentProfile, .editParentProfile),
                (.addChild, .addChild), (.childQRLogin, .childQRLogin):
                return true
                
            case let (.childDetail(c1), .childDetail(c2)),
                let (.editChildProfile(c1), .editChildProfile(c2)),
                let (.childHome(c1), .childHome(c2)),
                let (.qrCodeDisplay(c1), .qrCodeDisplay(c2)):
                return c1.id == c2.id
                
            default:
                return false
            }
        }
    }
    
    
    @Published var authState: AuthState = .splash {
        didSet {
            print("🔄 Auth State Changed: \(oldValue) → \(authState)")
        }
    }
    @Published var currentUser: Parent?
    @Published var selectedChild: Child?
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    let authService = AuthService.shared
    
    
    init() {
        print("\n🚀 AuthViewModel INIT Started")
        authService.printCurrentSessionState()
        authState = .splash
    }
    
    func initializeSession() async {
        print("\n🔐 INITIALIZE SESSION: Starting...")
        authService.printCurrentSessionState()
        
        if authService.shouldRestoreSession() {
            print("✅ Should restore session - Starting restoration...")
            await restoreSession()
        } else {
            print("❌ Should NOT restore session - Going to welcome")
            await MainActor.run {
                authState = .welcome
            }
        }
    }
    
    private func restoreSession() async {
        do {
            // Try to get fresh user data from API
            let user = try await authService.getCurrentUser()
            print("✅ RESTORE SESSION: Got user data from API - Name: \(user.name ?? "N/A"), Email: \(user.email ?? "N/A")")
            
            await MainActor.run {
                let parent = Parent(
                    name: user.name ?? "Parent",
                    email: user.email ?? "",
                    children: [],
                    totalScore: 0,
                    isActive: true
                )
                self.currentUser = parent
                self.authState = .parentDashboard
            }
            
            // Load children after setting parent
            await loadChildrenForCurrentUser()
            
        } catch {
            print("⚠️ RESTORE SESSION: API call failed - \(error.localizedDescription)")
            
            // Check if it's a network error vs auth error
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                    print("📡 Network error - Using cached session data")
                    await useCachedSessionData()
                    return
                default:
                    break
                }
            }
            
            // Check if it's an auth error (invalid token)
            if let authError = error as? AuthError {
                if case .serverError(let msg) = authError,
                   msg.contains("401") || msg.contains("403") || msg.contains("token") || msg.contains("unauthorized") {
                    print("🔒 Auth error - Token invalid, going to welcome")
                    authService.clearToken()
                    await MainActor.run {
                        self.authState = .welcome
                    }
                    return
                }
            }
            
            // For other errors, try to use cached data
            print("🔄 Other error - Attempting to use cached data")
            await useCachedSessionData()
        }
    }
    
    private func useCachedSessionData() async {
        // Try to load from UserDefaults or use saved email
        let savedEmail = authService.getSavedEmail() ?? "parent@example.com"
        
        // Create a parent with available data
        await MainActor.run {
            let parent = Parent(
                name: "Parent", // Will be updated when API becomes available
                email: savedEmail,
                children: [],
                totalScore: 0,
                isActive: true
            )
            self.currentUser = parent
            self.authState = .parentDashboard
        }
        
        // Try to load children (this might also fail but won't break the flow)
        await loadChildrenForCurrentUser()
        
        // Try to refresh user data in background
        Task {
            do {
                let user = try await authService.getCurrentUser()
                await MainActor.run {
                    if let existingParent = self.currentUser {
                        self.currentUser = Parent(
                            name: user.name ?? existingParent.name,
                            email: user.email ?? existingParent.email,
                            children: existingParent.children,
                            totalScore: existingParent.totalScore,
                            isActive: existingParent.isActive
                        )
                        print("✅ Background refresh: Updated parent data")
                    }
                }
            } catch {
                print("⚠️ Background refresh failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Auth Actions
    func signUp(fullName: String, email: String, password: String, confirmPassword: String) {
        errorMessage = nil
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your full name"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await authService.signUp(
                    name: fullName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    if let token = response.token {
                        authService.saveToken(token, rememberMe: true)
                    }
                    
                    if let userId = response.user?.id {
                        authService.saveParentId(userId)
                    }
                    
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func signIn(email: String, password: String, rememberMe: Bool = false) {
        print("\n📝 SIGN IN: Started")
        print("📝 SIGN IN: Email: \(email)")
        print("📝 SIGN IN: Remember Me: \(rememberMe)")
        
        errorMessage = nil
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await authService.signIn(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )
                
                print("📝 SIGN IN: API Response received")
                print("📝 SIGN IN: Token exists: \(response.token != nil)")
                
                await MainActor.run {
                    isLoading = false
                    
                    if let token = response.token {
                        print("📝 SIGN IN: Saving token with rememberMe: \(rememberMe)")
                        authService.saveToken(token, rememberMe: rememberMe)
                    }
                    
                    if let userId = response.user?.id {
                        authService.saveParentId(userId)
                    }
                    
                    let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
                    authService.saveRememberMe(email: rememberMe ? trimmedEmail : nil, remember: rememberMe)
                    
                    let parentName = response.user?.name ?? "Parent"
                    let parentEmail = response.user?.email ?? trimmedEmail
                    
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
                
                await loadChildrenForCurrentUser()
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    print("❌ SIGN IN: Failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func signOut() {
        print("\n🚪 SIGN OUT: Starting...")
        authService.printCurrentSessionState()
        authService.clearToken()
        currentUser = nil
        selectedChild = nil
        authState = .welcome
        print("🚪 SIGN OUT: Complete")
        authService.printCurrentSessionState()
    }
    
    // MARK: - Forgot Password
    func requestPasswordReset(email: String) {
        errorMessage = nil
        successMessage = nil
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authService.requestPasswordReset(email: email.trimmingCharacters(in: .whitespaces).lowercased())
                await MainActor.run {
                    isLoading = false
                    successMessage = "Password reset link has been sent to your email"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.authState = .parentSignIn
                        self?.successMessage = nil
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
    
    // MARK: - Child Management
    func addChild(name: String, age: Int, avatarEmoji: String) async throws {
        print("🧒 ADD CHILD: Starting...")
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw AuthError.serverError("Please enter a valid name")
        }
        
        if let existingChild = currentUser?.children.first(where: {
            $0.name.lowercased() == trimmedName.lowercased()
        }) {
            throw AuthError.serverError("A child named '\(existingChild.name)' already exists")
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let childResponse = try await authService.addChild(name: trimmedName, age: age, avatarEmoji: avatarEmoji)
        
        print("🧒 ADD CHILD: Response received")
        
        let newChild = Child(
            id: childResponse.id ?? UUID().uuidString,
            name: childResponse.name,
            age: childResponse.age,
            level: "\(age - 3)",
            avatarEmoji: childResponse.avatarEmoji,
            Score: 0,
            quizzes: [],
            totalPoints: 0,
            connectionToken: childResponse.connectionToken ?? UUID().uuidString
        )
        
        await MainActor.run {
            currentUser?.children.append(newChild)
            selectedChild = newChild
            authState = .parentDashboard
            print("🧒 ADD CHILD: Child added to current user")
        }
    }
    
    func updateChild(childId: String, name: String, age: Int, avatarEmoji: String) async throws {
        print("✏️ UPDATE CHILD: Starting...")
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw AuthError.serverError("Please enter a valid name")
        }
        
        if let existingChild = currentUser?.children.first(where: {
            $0.id != childId && $0.name.lowercased() == trimmedName.lowercased()
        }) {
            throw AuthError.serverError("A child named '\(existingChild.name)' already exists")
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let childResponse = try await authService.updateChild(
            childId: childId,
            name: trimmedName,
            age: age,
            avatarEmoji: avatarEmoji
        )
        
        print("✏️ UPDATE CHILD: Response received")
        
        await MainActor.run {
            if let index = currentUser?.children.firstIndex(where: { $0.id == childId }) {
                let updatedChild = Child(
                    id: childResponse.id ?? childId,
                    name: childResponse.name,
                    age: childResponse.age,
                    level: "\(age - 3)",
                    avatarEmoji: childResponse.avatarEmoji,
                    Score: currentUser?.children[index].Score ?? 0,
                    quizzes: currentUser?.children[index].quizzes ?? [],
                    totalPoints: currentUser?.children[index].totalPoints ?? 0,
                    connectionToken: childResponse.connectionToken ?? currentUser?.children[index].connectionToken ?? ""
                )
                
                currentUser?.children[index] = updatedChild
                selectedChild = updatedChild
                print("✏️ UPDATE CHILD: Child updated in current user")
            }
        }
    }
    
    func deleteChild(childId: String) async throws {
        print("🗑️ DELETE CHILD: Starting...")
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        try await authService.deleteChild(childId: childId)
        
        print("🗑️ DELETE CHILD: Response received")
        
        await MainActor.run {
            currentUser?.children.removeAll { $0.id == childId }
            if selectedChild?.id == childId {
                selectedChild = nil
            }
            print("🗑️ DELETE CHILD: Child removed from current user")
        }
    }
    
    private func loadChildrenForCurrentUser() async {
        var parentId = authService.getParentId()
        
        if parentId == nil {
            print("⚠️ LOAD CHILDREN: No parent ID stored, attempting to fetch from /auth/me")
            do {
                let user = try await authService.getCurrentUser()
                parentId = authService.getParentId()
                print("✅ LOAD CHILDREN: Got parent ID from /auth/me: \(parentId ?? "NONE")")
            } catch {
                print("❌ LOAD CHILDREN: Failed to get user: \(error.localizedDescription)")
                return
            }
        }
        
        guard let parentId = parentId else {
            print("❌ LOAD CHILDREN: No parent ID available - skipping")
            return
        }
        
        print("🔄 LOAD CHILDREN: Starting with parent ID: \(parentId)")
        
        do {
            let childrenResponse = try await authService.getChildren()
            print("🔄 LOAD CHILDREN: Got \(childrenResponse.count) children from API")
            
            let childModels = childrenResponse.map { child in
                Child(
                    id: child.id ?? UUID().uuidString,
                    name: child.name,
                    age: child.age,
                    level: "\(child.age - 3)",
                    avatarEmoji: child.avatarEmoji,
                    Score: 0,
                    quizzes: [],
                    totalPoints: 0,
                    connectionToken: child.connectionToken ?? UUID().uuidString
                )
            }
            
            await MainActor.run {
                currentUser?.children = childModels
                print("✅ LOAD CHILDREN: Loaded \(childModels.count) children successfully")
            }
        } catch {
            print("❌ LOAD CHILDREN: Failed with error: \(error.localizedDescription)")
        }
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
    func updateProfile(name: String?, email: String?) async throws {
        print("✏️ UPDATE PROFILE: Starting...")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let updatedUser = try await authService.updateProfile(name: name, email: email)
        
        await MainActor.run {
            if let existingUser = currentUser {
                currentUser = Parent(
                    name: updatedUser.name ?? existingUser.name,
                    email: updatedUser.email ?? existingUser.email,
                    children: existingUser.children,
                    totalScore: existingUser.totalScore,
                    isActive: existingUser.isActive
                )
                
                // Update saved email if changed
                if let newEmail = updatedUser.email {
                    authService.saveRememberMe(email: newEmail, remember: authService.getRememberMeState())
                }
            }
            errorMessage = nil
            print("✅ UPDATE PROFILE: Profile updated successfully")
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) async throws {
        print("🔐 CHANGE PASSWORD: Starting...")
        
        guard newPassword == confirmPassword else {
            throw AuthError.serverError("Passwords do not match")
        }
        
        guard newPassword.count >= 6 else {
            throw AuthError.serverError("Password must be at least 6 characters")
        }
        
        guard !currentPassword.isEmpty else {
            throw AuthError.serverError("Please enter your current password")
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        
        print("✅ CHANGE PASSWORD: Password changed successfully")
    }
    
    func deleteAccount() async throws {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        try await authService.deleteAccount()
        
        await MainActor.run {
            signOut()
        }
    }
    
    
    func signOutChild() {
        selectedChild = nil
        authState = .welcome
    }
    
    
    func loginChildWithToken(_ token: String) async throws -> Child {
        print("🔐 LOGIN CHILD: Starting with token: \(token)")
        
        // First try to login via API to get a proper session
        do {
            let result = try await authService.loginChildByToken(token)
            
            // Save the child session token
            if let childToken = result.token {
                authService.saveToken(childToken, rememberMe: false)
                print("✅ LOGIN CHILD: Saved child session token")
            }
            
            let child = Child(
                id: result.child.id ?? UUID().uuidString,
                name: result.child.name,
                age: result.child.age,
                level: result.child.level ?? "\(result.child.age - 3)",
                avatarEmoji: result.child.avatarEmoji,
                Score: 0,
                quizzes: [],
                totalPoints: 0,
                connectionToken: result.child.connectionToken ?? token
            )
            
            print("✅ LOGIN CHILD: Successfully logged in via API - \(child.name)")
            return child
            
        } catch {
            print("⚠️ LOGIN CHILD: API login failed, falling back to cache - \(error.localizedDescription)")
            
            // Fallback to cached data if API fails
            let childData = try authService.getChildByConnectionToken(token)
            
            // 🆕 CRITICAL FIX: Create a mock token for child session
            let mockChildToken = "child_\(token)_\(UUID().uuidString)"
            authService.saveToken(mockChildToken, rememberMe: false)
            print("✅ LOGIN CHILD: Created mock child session token")
            
            let child = Child(
                id: childData.id ?? UUID().uuidString,
                name: childData.name,
                age: childData.age,
                level: childData.level ?? "\(childData.age - 3)",
                avatarEmoji: childData.avatarEmoji,
                Score: 0,
                quizzes: [],
                totalPoints: 0,
                connectionToken: childData.connectionToken ?? token
            )
            
            print("✅ LOGIN CHILD: Loaded child from cache - \(child.name)")
            return child
        }
    }
    
    func hasChildSession() -> Bool {
        // For child sessions, we can be more lenient
        // Check if we have a selected child OR a token
        return selectedChild != nil || authService.getToken() != nil
    }

    func clearChildSession() {
        selectedChild = nil
        // Don't clear the token here as it might be needed for API calls
        // The token will be cleared when the parent logs out or explicitly cleared
    }
    
}
