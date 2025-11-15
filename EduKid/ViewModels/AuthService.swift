import Foundation
import UIKit

class AuthService {
    static let shared = AuthService()
    
    private let baseURL = "https://accessorial-zaida-soggily.ngrok-free.dev"
    
    // Token storage keys
    private let tokenKey = "auth_token"
    private let rememberMeKey = "remember_me"
    private let userEmailKey = "user_email"
    private let parentIdKey = "parent_id"
    
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
        print("CLEAR TOKEN: Only removing token & remember-me")
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
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
    
    func getAuthHeader() -> [String: String]? {
        guard let token = getToken() else { return nil }
        return ["Authorization": "Bearer \(token)"]
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
        guard let url = URL(string: "\(baseURL)/auth/me") else {
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let userDict = json["user"] as? [String: Any] ?? json["data"] as? [String: Any] ?? json
                let user = UserResponse(
                    id: userDict["id"] as? String,
                    name: userDict["name"] as? String,
                    email: userDict["email"] as? String,
                    profileImageUrl: userDict["profileImageUrl"] as? String
                )
                if let parentId = user.id {
                    saveParentId(parentId)
                }
                return user
            }
            throw AuthError.serverError("Failed to decode user data")
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("SIGN UP RAW RESPONSE: \(jsonString)")
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let token = json["token"] as? String ?? json["accessToken"] as? String
                let userDict = json["user"] as? [String: Any] ?? json
                
                let user = UserResponse(
                    id: userDict["id"] as? String,
                    name: userDict["name"] as? String,
                    email: userDict["email"] as? String,
                    profileImageUrl: userDict["profileImageUrl"] as? String
                )
                
                if let token = token {
                    saveToken(token, rememberMe: true)
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
                        return SignInResponse(token: token, user: updatedUser, message: nil)
                    }
                }
                
                return SignInResponse(token: token, user: user, message: nil)
            }
            throw AuthError.serverError("Failed to decode response")
        } else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.message ?? errorData.error ?? "Sign in failed")
            }
            throw AuthError.serverError("Sign in failed with status code: \(httpResponse.statusCode)")
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
        
        let body = ["token": token, "newPassword": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.message ?? "Failed to reset password")
            }
            throw AuthError.serverError("Failed to reset password")
        }
        
        print("Password reset successfully")
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
        
        return ChildResponse(
            id: newChildDict.id ?? newChildDict._id,
            name: newChildDict.name,
            age: newChildDict.age,
            level: newChildDict.level,
            avatarEmoji: newChildDict.avatarEmoji ?? "",
            connectionToken: newChildDict.connectionToken
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
        return parent.children.map {
            ChildResponse(
                id: $0.id ?? $0._id,
                name: $0.name,
                age: $0.age,
                level: $0.level,
                avatarEmoji: $0.avatarEmoji ?? "",
                connectionToken: $0.connectionToken
            )
        }
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
        
        // Try to decode as single child first, fallback to parent response
        if let childDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return ChildResponse(
                id: childDict["_id"] as? String ?? childDict["id"] as? String,
                name: childDict["name"] as? String ?? "",
                age: childDict["age"] as? Int ?? 0,
                level: childDict["level"] as? String,
                avatarEmoji: childDict["avatarEmoji"] as? String ?? "",
                connectionToken: childDict["connectionToken"] as? String
            )
        }
        
        // Fallback to parent response structure
        let parentResponse = try JSONDecoder().decode(ParentFullResponse.self, from: data)
        guard let updatedChildDict = parentResponse.children.first(where: {
            $0.id == childId || $0._id == childId
        }) else {
            throw AuthError.serverError("Updated child not found in response")
        }
        
        return ChildResponse(
            id: updatedChildDict.id ?? updatedChildDict._id,
            name: updatedChildDict.name,
            age: updatedChildDict.age,
            level: updatedChildDict.level,
            avatarEmoji: updatedChildDict.avatarEmoji ?? "",
            connectionToken: updatedChildDict.connectionToken
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
            return UserResponse(
                id: userDict["id"] as? String,
                name: userDict["name"] as? String,
                email: userDict["email"] as? String,
                profileImageUrl: userDict["profileImageUrl"] as? String
            )
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
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body = ["currentPassword": currentPassword, "newPassword": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            throw AuthError.serverError("Password change failed")
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
    
    private enum CodingKeys: String, CodingKey {
        case _id, id, name, age, level, avatarEmoji, connectionToken, Score
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
