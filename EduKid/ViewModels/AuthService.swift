import Foundation
import UIKit

class AuthService {
    static let shared = AuthService()
    
    private let baseURL =
    "https://preterrestrial-georgann-recappable.ngrok-free.dev"



    
    // Token storage keys
    private let tokenKey = "auth_token"
    private let rememberMeKey = "remember_me"
    private let userEmailKey = "user_email"
    private let parentIdKey = "parent_id"
    private let cachedChildrenKey = "cached_children_data"
    private let activeChildIdKey = "active_child_id"
    private let activeChildNameKey = "active_child_name"
    private let activeChildAgeKey = "active_child_age"
    
    var useMockMode: Bool = false
    
    private init() {}
    
    // MARK: - Token Management
    func saveToken(_ token: String, rememberMe: Bool) {
        print("SAVE TOKEN: Saving token with rememberMe: \(rememberMe)")
        print("SAVE TOKEN: Token value: \(token.prefix(20))...")
        
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)
        UserDefaults.standard.synchronize()
        
        print("SAVE TOKEN: Token saved successfully")
        printCurrentSessionState()
    }
    
    func getToken() -> String? {
        let token = UserDefaults.standard.string(forKey: tokenKey)
        print("GET TOKEN: Retrieved token: \(token != nil ? "\(token!.prefix(20))..." : "NONE")")
        return token
    }
    
    func shouldRestoreSession() -> Bool {
        let token = getToken()
        let hasToken = token != nil
        let rememberMeEnabled = UserDefaults.standard.bool(forKey: rememberMeKey)
        
        print("""
        SHOULD RESTORE SESSION CHECK:
        - Has Token: \(hasToken ? "YES" : "NO")
        - Token Value: \(token?.prefix(20) ?? "NONE")...
        - Remember Me Key Value: \(rememberMeEnabled ? "YES" : "NO")
        - Should Restore: \(hasToken && rememberMeEnabled ? "YES" : "NO")
        """)
        
        return hasToken && rememberMeEnabled
    }
    
    func validateAndRestoreSession() async -> Bool {
        guard shouldRestoreSession(), let token = getToken() else {
            print("No valid session to restore")
            return false
        }
        
        do {
            let user = try await getCurrentUser()
            print("Session restored for: \(user.email ?? "unknown")")
            return true
        } catch {
            // Only clear if token is truly invalid (401/403)
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .cannotConnectToHost, .networkConnectionLost:
                    print("Network error – keep session: \(error.localizedDescription)")
                    return true
                default:
                    break
                }
            }
            
            if let authError = error as? AuthError,
               case .serverError(let msg) = authError,
               msg.contains("401") || msg.contains("403") {
                print("Token invalid – clearing session")
                clearToken()
                return false
            }
            
            print("Other error – keep session: \(error.localizedDescription)")
            return true
        }
    }
    
    func clearToken() {
        print("CLEAR TOKEN: Removing token and remember-me (keeping cached children)")
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        UserDefaults.standard.removeObject(forKey: activeChildIdKey)
        UserDefaults.standard.removeObject(forKey: activeChildNameKey)
        UserDefaults.standard.removeObject(forKey: activeChildAgeKey)
        // Don't clear cache here - children need it to login!
        UserDefaults.standard.synchronize()
        printCurrentSessionState()
    }
    
    
    func saveParentId(_ parentId: String) {
        print("SAVE PARENT ID: \(parentId)")
        UserDefaults.standard.set(parentId, forKey: parentIdKey)
        UserDefaults.standard.synchronize()
    }
    
    func getParentId() -> String? {
        return UserDefaults.standard.string(forKey: parentIdKey)
    }
    
    // MARK: - Remember Me helpers
    func saveRememberMe(email: String?, remember: Bool) {
        print("SAVE REMEMBER ME: remember=\(remember), email=\(email ?? "nil")")
        
        UserDefaults.standard.set(remember, forKey: rememberMeKey)
        
        if remember, let email = email, !email.isEmpty {
            UserDefaults.standard.set(email, forKey: userEmailKey)
            print("SAVE REMEMBER ME: Saved email: \(email)")
        } else {
            UserDefaults.standard.removeObject(forKey: userEmailKey)
            print("SAVE REMEMBER ME: Cleared saved email")
        }
        
        UserDefaults.standard.synchronize()
        print("SAVE REMEMBER ME: UserDefaults synchronized")
        printCurrentSessionState()
    }
    
    func printCurrentSessionState() {
        let token = getToken()
        let rememberMe = UserDefaults.standard.bool(forKey: rememberMeKey)
        let savedEmail = UserDefaults.standard.string(forKey: userEmailKey)
        let parentId = getParentId()
        
        print("""
        
        ========== CURRENT SESSION STATE ==========
        - Token exists: \(token != nil ? "YES (\(token!.prefix(20))...)" : "NO")
        - Remember Me: \(rememberMe ? "YES" : "NO")
        - Saved Email: \(savedEmail ?? "NONE")
        - Parent ID: \(parentId ?? "NONE")
        - Should Restore: \(shouldRestoreSession() ? "YES" : "NO")
        ============================================
        
        """)
    }
    
    func getSavedEmail() -> String? {
        guard UserDefaults.standard.bool(forKey: rememberMeKey) else { return nil }
        return UserDefaults.standard.string(forKey: userEmailKey)
    }
    
    func getRememberMeState() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }
    
    // MARK: - Child Session Management
    func saveActiveChildSession(childId: String, childName: String, childAge: Int) {
        print("👶 SAVE CHILD SESSION: id=\(childId), name=\(childName), age=\(childAge)")
        UserDefaults.standard.set(childId, forKey: activeChildIdKey)
        UserDefaults.standard.set(childName, forKey: activeChildNameKey)
        UserDefaults.standard.set(childAge, forKey: activeChildAgeKey)
        UserDefaults.standard.synchronize()
    }
    
    func getActiveChildSession() -> (id: String, name: String, age: Int)? {
        guard let childId = UserDefaults.standard.string(forKey: activeChildIdKey),
              let childName = UserDefaults.standard.string(forKey: activeChildNameKey),
              UserDefaults.standard.object(forKey: activeChildAgeKey) != nil else {
            return nil
        }
        let childAge = UserDefaults.standard.integer(forKey: activeChildAgeKey)
        print("👶 GET CHILD SESSION: id=\(childId), name=\(childName), age=\(childAge)")
        return (childId, childName, childAge)
    }
    
    func hasActiveChildSession() -> Bool {
        return getActiveChildSession() != nil
    }
    
    func clearActiveChildSession() {
        print("👶 CLEAR CHILD SESSION")
        UserDefaults.standard.removeObject(forKey: activeChildIdKey)
        UserDefaults.standard.removeObject(forKey: activeChildNameKey)
        UserDefaults.standard.removeObject(forKey: activeChildAgeKey)
        UserDefaults.standard.synchronize()
    }
    
    
    // Save children data to UserDefaults when parent logs in
    func cacheChildrenData(_ children: [ChildResponse]) {
        if let encoded = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(encoded, forKey: cachedChildrenKey)
            UserDefaults.standard.synchronize()
            print("📦 CACHE: Saved \(children.count) children to local storage")
        }
    }
    
    // Load children data from UserDefaults
    func getCachedChildren() -> [ChildResponse]? {
        guard let data = UserDefaults.standard.data(forKey: cachedChildrenKey),
              let children = try? JSONDecoder().decode([ChildResponse].self, from: data) else {
            print("📦 CACHE: No cached children found")
            return nil
        }
        print("📦 CACHE: Loaded \(children.count) children from cache")
        return children
    }
    
    // Clear cached children when signing out
    func clearCachedChildren() {
        UserDefaults.standard.removeObject(forKey: cachedChildrenKey)
        print("📦 CACHE: Cleared cached children")
    }
    
    // Get child by connection token from cache
    func getChildByConnectionToken(_ connectionToken: String) throws -> ChildResponse {
        guard let cachedChildren = getCachedChildren() else {
            throw AuthError.serverError("No children data available. Please ask your parent to log in first.")
        }
        
        print("🔍 Searching for child with token: \(connectionToken)")
        print("📦 Available children in cache:")
        for child in cachedChildren {
            print("   - \(child.name): id=\(child.id ?? "NONE"), token=\(child.connectionToken ?? "NONE")")
        }
        
        // Try to match by connectionToken OR by id
        guard let child = cachedChildren.first(where: {
            $0.connectionToken == connectionToken || $0.id == connectionToken
        }) else {
            print("❌ No matching child found!")
            throw AuthError.serverError("Invalid QR code or access code")
        }
        
        print("✅ Found child from cache: \(child.name)")
        return child
    }
    
    // MARK: - JWT Helpers
    private func decodeJWTForUserId(_ token: String) -> String? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        var base64String = segments[1]
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String = base64String.padding(toLength: base64String.count + 4 - remainder,
                                                withPad: "=", startingAt: 0)
        }
        
        guard let data = Data(base64Encoded: base64String) else { return nil }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json["userId"] as? String ??
            json["id"] as? String ??
            json["_id"] as? String ??
            json["sub"] as? String ??
            json["parentId"] as? String
        }
        return nil
    }
    
    // MARK: - Get Current User
    func getCurrentUser() async throws -> UserResponse {
        // Use the existing parent ID to fetch from /parents/:id
        guard let parentId = getParentId() else {
            throw AuthError.serverError("No parent ID found")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("GET CURRENT USER RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // The response is the parent object directly
                let user = UserResponse(
                    id: json["_id"] as? String ?? json["id"] as? String,
                    name: json["name"] as? String,
                    email: json["email"] as? String,
                    profileImageUrl: json["profileImageUrl"] as? String
                )
                if let parentId = user.id {
                    saveParentId(parentId)
                }
                print("✅ GET CURRENT USER: Success - Name: \(user.name ?? "N/A"), Email: \(user.email ?? "N/A")")
                return user
            }
            throw AuthError.serverError("Failed to decode user data")
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthError.serverError("401 - Unauthorized")
        } else {
            throw AuthError.serverError("Failed to get user: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String) async throws -> SignUpResponse {
        guard let url = URL(string: "\(baseURL)/auth/signup") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let requestBody = SignUpRequest(name: name, email: email, password: password)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("SIGN UP RAW RESPONSE: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let token = json["token"] as? String ?? json["accessToken"] as? String
                let userDict = json["user"] as? [String: Any] ?? json
                
                let user = UserResponse(
                    id: userDict["id"] as? String ?? userDict["_id"] as? String,
                    name: userDict["name"] as? String,
                    email: userDict["email"] as? String,
                    profileImageUrl: userDict["profileImageUrl"] as? String
                )
                
                if let token = token {
                    saveToken(token, rememberMe: true)
                }
                
                if let userId = user.id {
                    saveParentId(userId)
                }
                
                return SignUpResponse(message: "Success", user: user, token: token)
            }
            return SignUpResponse(message: "Account created successfully", user: nil, token: nil)
        } else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.message ?? errorData.error ?? "Sign up failed")
            }
            throw AuthError.serverError("Sign up failed with status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> SignInResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let requestBody = SignInRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let token = json["token"] as? String ??
                    json["accessToken"] as? String ??
                    json["access_token"] as? String ??
                    (json["data"] as? [String: Any])?["token"] as? String
                    
                    var userDict = json["user"] as? [String: Any]
                    if userDict == nil { userDict = (json["data"] as? [String: Any])?["user"] as? [String: Any] }
                    if userDict == nil { userDict = json }
                    
                    var userId: String? = userDict?["id"] as? String
                    if userId == nil { userId = userDict?["_id"] as? String }
                    if userId == nil { userId = userDict?["userId"] as? String }
                    if userId == nil { userId = userDict?["parentId"] as? String }
                    
                    let user = UserResponse(
                        id: userId,
                        name: userDict?["name"] as? String,
                        email: userDict?["email"] as? String,
                        profileImageUrl: userDict?["profileImageUrl"] as? String ?? userDict?["profile_image_url"] as? String
                    )
                    
                    print("SIGN IN: Extracted token: \(token != nil ? "YES" : "NO")")
                    print("SIGN IN: User ID: \(user.id ?? "NONE")")
                    print("SIGN IN: User Name: \(user.name ?? "NONE")")
                    print("SIGN IN: User Email: \(user.email ?? "NONE")")
                    
                    if user.id == nil, let token = token {
                        if let decodedId = decodeJWTForUserId(token) {
                            print("SIGN IN: Extracted user ID from JWT: \(decodedId)")
                            let updatedUser = UserResponse(
                                id: decodedId,
                                name: user.name,
                                email: user.email,
                                profileImageUrl: user.profileImageUrl
                            )
                            if let id = updatedUser.id {
                                saveParentId(id)
                            }
                            return SignInResponse(token: token, user: updatedUser, message: nil)
                        }
                    }
                    
                    if let id = user.id {
                        saveParentId(id)
                    }
                    
                    return SignInResponse(token: token, user: user, message: nil)
                }
                throw AuthError.serverError("Failed to decode response")
            } else {
                // Try to decode error message from server
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let errorMsg = errorData.message ?? errorData.error ?? "Sign in failed"
                    
                    // Check for specific error patterns and provide clearer messages
                    if errorMsg.lowercased().contains("invalid credentials") ||
                       errorMsg.lowercased().contains("unauthorized") {
                        // Check if it's likely a password issue (401 typically means wrong password)
                        if httpResponse.statusCode == 401 {
                            throw AuthError.serverError("Incorrect email or password")
                        }
                    }
                    
                    if errorMsg.lowercased().contains("email") && errorMsg.lowercased().contains("not found") {
                        throw AuthError.serverError("Email not found. Please check your email or sign up.")
                    }
                    
                    if errorMsg.lowercased().contains("password") {
                        throw AuthError.serverError("Incorrect password")
                    }
                    
                    throw AuthError.serverError(errorMsg)
                }
                
                // Try to parse as simple JSON
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    
                    if message.lowercased().contains("invalid credentials") ||
                       message.lowercased().contains("unauthorized") {
                        throw AuthError.serverError("Incorrect email or password")
                    }
                    
                    if message.lowercased().contains("email") && message.lowercased().contains("not found") {
                        throw AuthError.serverError("Email not found. Please check your email or sign up.")
                    }
                    
                    if message.lowercased().contains("password") {
                        throw AuthError.serverError("Incorrect password")
                    }
                    
                    throw AuthError.serverError(message)
                }
                
                // Fallback based on status code
                if httpResponse.statusCode == 401 {
                    throw AuthError.serverError("Incorrect email or password")
                } else if httpResponse.statusCode == 404 {
                    throw AuthError.serverError("Email not found. Please check your email or sign up.")
                }
                
                throw AuthError.serverError("Sign in failed. Please try again.")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            print("❌ Sign In Network Error: \(error.localizedDescription)")
            throw AuthError.serverError("Network error. Please check your connection and try again.")
        }
    }
    
    // MARK: - Forgot Password
    func requestPasswordReset(email: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.message ?? "Failed to send reset email")
            }
            throw AuthError.serverError("Failed to send reset email")
        }
        
        print("Password reset email sent to: \(email)")
    }
    
    // MARK: - Reset Password with Token
    func resetPassword(token: String, newPassword: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/reset-password") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body: [String: Any] = [
            "token": token,
            "newPassword": newPassword
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.message ?? errorData.error ?? "Password reset failed")
            }
            throw AuthError.serverError("Password reset failed with status code: \(httpResponse.statusCode)")
        }
        
        print("✅ Password reset successfully")
    }
    
    // MARK: - Profile Image Upload
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let parentId = getParentId() else {
            throw AuthError.serverError("Parent ID not found")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/profile-image") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token")
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw AuthError.serverError("Failed to compress image")
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profileImage\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to upload image")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let imageUrl = json["imageUrl"] as? String ?? json["profileImageUrl"] as? String {
            print("Profile image uploaded: \(imageUrl)")
            return imageUrl
        }
        
        throw AuthError.serverError("Failed to get image URL from response")
    }
    
    // MARK: - Children Management
    
    func addChild(name: String, age: Int, avatarEmoji: String) async throws -> ChildResponse {
        guard let parentId = getParentId() else {
            throw AuthError.serverError("Parent ID not found")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body: [String: Any] = [
            "name": name,
            "age": age,
            "level": "\(age - 3)",
            "avatarEmoji": avatarEmoji
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("ADD CHILD RAW RESPONSE: \(raw)")
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.message
            ?? "Failed to add child – status \(statusCode)"
            throw AuthError.serverError(msg)
        }
        
        let parentResponse = try JSONDecoder().decode(ParentFullResponse.self, from: data)
        
        guard let newChildDict = parentResponse.children.last else {
            throw AuthError.serverError("Child not found in response")
        }
        
        guard let childId = newChildDict.id ?? newChildDict._id else {
            throw AuthError.serverError("Server returned child without ID")
        }
        
        return ChildResponse(
            id: childId,
            name: newChildDict.name,
            age: newChildDict.age,
            level: newChildDict.level,
            avatarEmoji: newChildDict.avatarEmoji ?? "",
            connectionToken: childId,  // 🆕 Use the child's ID as the token!
            shopCatalog: nil,
            inventory: nil,
            quests: nil
        )
    }
    
    
    func getChildren() async throws -> [ChildResponse] {
        guard let parentId = getParentId() else { throw AuthError.serverError("No parent ID") }
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)") else { throw AuthError.invalidURL }
        guard let token = getToken() else { throw AuthError.serverError("No token") }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let raw = String(data: data, encoding: .utf8) { print("GET PARENT RAW: \(raw)") }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to get parent: \(statusCode)")
        }
        
        let parent = try JSONDecoder().decode(ParentFullResponse.self, from: data)
        let children = parent.children.map { child -> ChildResponse in
            guard let childId = child.id ?? child._id else {
                print("⚠️ Skipping child without ID")
                // In a map, we can't easily throw, so we might return a placeholder or filter it out. 
                // Better approach: return a result and compactMap. 
                // For minimally invasive change, let's use an empty string and filter later if needed, 
                // OR technically if this happens, the backend data is corrupt. 
                // Let's force a crash/fail for the specific item or handle it safely.
                // Given the map context, let's return a dummy or handle it. 
                // Actually, let's look at the map closure.
                return ChildResponse(
                    id: "", // Invalid ID that will fail intentionally if used
                    name: child.name,
                    age: child.age,
                    level: child.level,
                    avatarEmoji: child.avatarEmoji ?? "",
                    connectionToken: "", 
                    shopCatalog: child.shopCatalog,
                    inventory: child.inventory,
                    quests: child.quests
                )
            }
            return ChildResponse(
                id: childId,
                name: child.name,
                age: child.age,
                level: child.level,
                avatarEmoji: child.avatarEmoji ?? "",
                connectionToken: childId,  // 🆕 Use the child's ID as the token!
                shopCatalog: child.shopCatalog,
                inventory: child.inventory,
                quests: child.quests
            )
        }
        .filter { !($0.id?.isEmpty ?? true) } // Filter out invalid children
        
        // Cache the children data
        cacheChildrenData(children)
        
        return children
    }
    
    // MARK: - Update Child (PATCH /parents/:id/kids/:kidId)
    func updateChild(childId: String, name: String?, age: Int?, avatarEmoji: String?) async throws -> ChildResponse {
        guard let parentId = getParentId() else {
            throw AuthError.serverError("Parent ID not found")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(childId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let age = age { body["age"] = age; body["level"] = "\(age - 3)" }
        if let avatarEmoji = avatarEmoji { body["avatarEmoji"] = avatarEmoji }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("UPDATE CHILD RAW RESPONSE: \(raw)")
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.message
            ?? "Failed to update child – status \(statusCode)"
            throw AuthError.serverError(msg)
        }
        
        // Try to decode as single child first
        if let childDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let id = childDict["_id"] as? String ?? childDict["id"] as? String ?? childId
            return ChildResponse(
                id: id,
                name: childDict["name"] as? String ?? "",
                age: childDict["age"] as? Int ?? 0,
                level: childDict["level"] as? String,
                avatarEmoji: childDict["avatarEmoji"] as? String ?? "",
                connectionToken: id,  // 🆕 Use the child's ID
                shopCatalog: nil,
                inventory: nil,
                quests: nil
            )
        }
        
        // Fallback to parent response structure
        let parentResponse = try JSONDecoder().decode(ParentFullResponse.self, from: data)
        guard let updatedChildDict = parentResponse.children.first(where: {
            $0.id == childId || $0._id == childId
        }) else {
            throw AuthError.serverError("Updated child not found in response")
        }
        
        let id = updatedChildDict.id ?? updatedChildDict._id ?? childId
        
        return ChildResponse(
            id: id,
            name: updatedChildDict.name,
            age: updatedChildDict.age,
            level: updatedChildDict.level,
            avatarEmoji: updatedChildDict.avatarEmoji ?? "",
            connectionToken: id,  // 🆕 Use the child's ID
            shopCatalog: updatedChildDict.shopCatalog,
            inventory: updatedChildDict.inventory,
            quests: updatedChildDict.quests
        )
    }
    // MARK: - Delete Child (DELETE /parents/:id/kids/:kidId)
    func deleteChild(childId: String) async throws {
        guard let parentId = getParentId() else {
            throw AuthError.serverError("Parent ID not found")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)/kids/\(childId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("DELETE CHILD RAW RESPONSE: \(raw)")
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.message
            ?? "Failed to delete child – status \(statusCode)"
            throw AuthError.serverError(msg)
        }
        
        print("✅ Child deleted successfully")
    }
    
    // MARK: - Profile Management
    func updateProfile(name: String?, email: String?) async throws -> UserResponse {
        guard let parentId = getParentId() else {
            throw AuthError.serverError("Parent ID not found. Please sign in again.")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let email = email { body["email"] = email }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("UPDATE PROFILE RAW RESPONSE: \(raw)")
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.message
            ?? "Update failed – status \(statusCode)"
            throw AuthError.serverError(msg)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let userDict = json["user"] as? [String: Any] ?? json["data"] as? [String: Any] ?? json
            let user = UserResponse(
                id: userDict["id"] as? String ?? userDict["_id"] as? String,
                name: userDict["name"] as? String,
                email: userDict["email"] as? String,
                profileImageUrl: userDict["profileImageUrl"] as? String
            )
            print("✅ Profile updated: Name=\(user.name ?? "N/A"), Email=\(user.email ?? "N/A")")
            return user
        }
        throw AuthError.serverError("Failed to decode response")
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/change-password") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body = ["currentPassword": currentPassword, "newPassword": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let raw = String(data: data, encoding: .utf8) {
                print("CHANGE PASSWORD RAW RESPONSE: \(raw)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError("Invalid server response. Please try again.")
            }
            
            print("📡 Change Password Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                // Try to decode error message from server
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let errorMsg = errorData.message ?? errorData.error ?? "Password change failed"
                    print("❌ Server Error Message: \(errorMsg)")
                    
                    // Check for specific error messages from backend
                    if errorMsg.lowercased().contains("incorrect") || 
                       errorMsg.lowercased().contains("wrong") ||
                       errorMsg.lowercased().contains("invalid password") ||
                       errorMsg.lowercased().contains("current password") {
                        throw AuthError.serverError("Incorrect current password")
                    }
                    
                    throw AuthError.serverError(errorMsg)
                }
                
                // Try to parse as simple JSON with message field
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let message = json["message"] as? String {
                        print("❌ JSON Error Message: \(message)")
                        
                        if message.lowercased().contains("incorrect") || 
                           message.lowercased().contains("wrong") ||
                           message.lowercased().contains("current password") {
                            throw AuthError.serverError("Incorrect current password")
                        }
                        
                        throw AuthError.serverError(message)
                    }
                    
                    if let error = json["error"] as? String {
                        print("❌ JSON Error: \(error)")
                        
                        if error.lowercased().contains("incorrect") || 
                           error.lowercased().contains("current password") {
                            throw AuthError.serverError("Incorrect current password")
                        }
                        
                        throw AuthError.serverError(error)
                    }
                }
                
                // Provide user-friendly error messages based on status code
                switch httpResponse.statusCode {
                case 400:
                    throw AuthError.serverError("Invalid password format. Please check your passwords and try again.")
                case 401:
                    throw AuthError.serverError("Incorrect current password")
                case 403:
                    throw AuthError.serverError("You don't have permission to change this password.")
                case 404:
                    throw AuthError.serverError("Password change feature is currently unavailable. Please contact support.")
                case 500...599:
                    throw AuthError.serverError("Server error. Please try again later.")
                default:
                    throw AuthError.serverError("Failed to change password. Please try again.")
                }
            }
            
            print("✅ Password changed successfully")
            
        } catch let error as AuthError {
            throw error
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            
            if error.localizedDescription.contains("Cannot PUT") || 
               error.localizedDescription.contains("Cannot POST") ||
               error.localizedDescription.contains("404") ||
               error.localizedDescription.contains("Not Found") {
                throw AuthError.serverError("Password change feature is currently unavailable. Please contact support.")
            }
            
            if error.localizedDescription.contains("network") || 
               error.localizedDescription.contains("connection") {
                throw AuthError.serverError("Network error. Please check your connection and try again.")
            }
            
            throw AuthError.serverError("Failed to change password. Please try again.")
        }
    }
    
    func deleteAccount() async throws {
        guard let parentId = getParentId() else {
            throw AuthError.serverError("Parent ID not found")
        }
        
        guard let url = URL(string: "\(baseURL)/parents/\(parentId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            throw AuthError.serverError("No token")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthError.serverError("Account deletion failed")
        }
        
        clearToken()
    }
    
    func loginChildWithConnectionToken(_ connectionToken: String) async throws -> ChildResponse {
        guard let url = URL(string: "\(baseURL)/children/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body = ["connectionToken": connectionToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("CHILD LOGIN RAW RESPONSE: \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let childDict = json["child"] as? [String: Any] ?? json
                
                return ChildResponse(
                    id: childDict["_id"] as? String ?? childDict["id"] as? String,
                    name: childDict["name"] as? String ?? "",
                    age: childDict["age"] as? Int ?? 0,
                    level: childDict["level"] as? String,
                    avatarEmoji: childDict["avatarEmoji"] as? String ?? "",
                    connectionToken: childDict["connectionToken"] as? String,
                    shopCatalog: nil, // TODO: Parse if needed from login
                    inventory: nil,
                    quests: nil
                )
            }
            throw AuthError.serverError("Failed to decode child data")
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
            throw AuthError.serverError("Invalid QR code or access code")
        } else {
            throw AuthError.serverError("Login failed with status code: \(httpResponse.statusCode)")
        }
    }
    
    
    
    
    // MARK: - Child Login by Token
    func loginChildByToken(_ token: String) async throws -> (child: ChildResponse, parentId: String?, token: String?) {
        print("AUTH SERVICE: Login child by token - \(token)")
        
        // 🆕 FIX: Use the correct endpoint that exists
        let endpoint = "\(baseURL)/auth/child-login"
        
        guard let url = URL(string: endpoint) else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body: [String: Any] = ["connectionToken": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AuthError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("AUTH SERVICE: Child login raw response - \(raw)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("AUTH SERVICE: Child login response status - \(httpResponse.statusCode)")
        
        // 🆕 FIX: Handle different status codes appropriately
        if httpResponse.statusCode == 404 {
            // Endpoint not found - we'll handle this gracefully with fallback
            throw AuthError.serverError("Child login endpoint not available")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.message ?? "Login failed")
            }
            throw AuthError.serverError("Invalid login code. Please check with your parent.")
        }
        
        // Try to decode the response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let childDict = json["child"] as? [String: Any] ?? json
            let token = json["token"] as? String ?? json["accessToken"] as? String
            
            let childResponse = ChildResponse(
                id: childDict["_id"] as? String ?? childDict["id"] as? String,
                name: childDict["name"] as? String ?? "",
                age: childDict["age"] as? Int ?? 0,
                level: childDict["level"] as? String,
                avatarEmoji: childDict["avatarEmoji"] as? String ?? "",
                connectionToken: childDict["connectionToken"] as? String,
                shopCatalog: nil, // TODO: Parse if needed
                inventory: nil,
                quests: nil
            )
            
            let parentId = childDict["parentId"] as? String ?? json["parentId"] as? String
            
            print("AUTH SERVICE: Child login successful - \(childResponse.name)")
            
            return (child: childResponse, parentId: parentId, token: token)
        }
        
        throw AuthError.serverError("Failed to decode login response")
    }
    
    func validateChildSession() async -> Bool {
        guard let token = getToken() else {
            return false
        }
        
        // For child sessions, we might want to use a simpler validation
        // since children don't have the same profile endpoints
        return true // Or implement proper child session validation
    }
    
}
// MARK: - Models
struct SignUpRequest: Codable { let name: String; let email: String; let password: String }
struct SignUpResponse: Codable { let message: String?; let user: UserResponse?; let token: String? }
struct UserResponse: Codable { let id: String?; let name: String?; let email: String?; let profileImageUrl: String? }
struct SignInRequest: Codable { let email: String; let password: String }
struct SignInResponse: Codable { let token: String?; let user: UserResponse?; let message: String? }
struct ErrorResponse: Codable { let message: String?; let error: String? }

struct ChildResponse: Codable {
    let id: String?
    let name: String
    let age: Int
    let level: String?
    let avatarEmoji: String
    let connectionToken: String?
    let shopCatalog: [Gift]?
    let inventory: [Gift]?
    let quests: [Quest]?
}

// MARK: - Helper models for parent response
private struct ParentFullResponse: Codable {
    let _id: String
    let name: String
    let email: String
    let children: [ChildInParent]
    let totalScore: Int
    let isActive: Bool
    
    private enum CodingKeys: String, CodingKey {
        case _id, name, email, children, totalScore, isActive
    }
}

private struct ChildInParent: Codable {
    let _id: String?
    let id: String?
    let name: String
    let age: Int
    let level: String?
    let avatarEmoji: String?
    let connectionToken: String?
    let Score: Int?
    let shopCatalog: [Gift]?
    let inventory: [Gift]?
    let quests: [Quest]?
    
    private enum CodingKeys: String, CodingKey {
        case _id, id, name, age, level, avatarEmoji, connectionToken, Score, shopCatalog, inventory, quests
    }
}

struct ChildLoginResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let parentId: String?
    let child: ChildResponse
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case token
        case parentId
        case child
    }
}


enum AuthError: LocalizedError {
    case invalidURL, encodingError, invalidResponse, networkError(String), serverError(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .encodingError: return "Failed to encode request"
        case .invalidResponse: return "Invalid response from server"
        case .networkError(let msg): return "Network error: \(msg)"
        case .serverError(let msg): return msg
        }
    }
}


