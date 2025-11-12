//
//  AuthService.swift
//  EduKid
//
//  Created by Mac Mini 11 on 6/11/2025.
//

import Foundation

class AuthService {
    static let shared = AuthService()
    
    private let baseURL = "https://tractile-trang-adaptively.ngrok-free.dev"
    // Note: localhost:3000 only works in iOS Simulator, not on physical devices
    // For physical devices, use your computer's IP address (e.g., "http://192.168.1.100:3000")
    // or use the ngrok URL if your backend is accessible via ngrok
    
    // Token storage keys
    private let tokenKey = "auth_token"
    private let rememberMeKey = "remember_me"
    private let userEmailKey = "user_email"
    private let parentIdKey = "parent_id"
    
    private init() {}
    
    // MARK: - Token Management
    func saveToken(_ token: String, rememberMe: Bool) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)
    }
    
    func getToken() -> String? {
        // Always return token if it exists (for current session)
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func shouldRestoreSession() -> Bool {
        // Only restore session on app launch if "Remember Me" was checked
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: parentIdKey)
    }
    
    func saveParentId(_ parentId: String) {
        UserDefaults.standard.set(parentId, forKey: parentIdKey)
    }
    
    func getParentId() -> String? {
        return UserDefaults.standard.string(forKey: parentIdKey)
    }
    
    func saveUserEmail(_ email: String) {
        UserDefaults.standard.set(email, forKey: userEmailKey)
    }
    
    func getUserEmail() -> String? {
        return UserDefaults.standard.string(forKey: userEmailKey)
    }
    
    func getAuthHeader() -> [String: String]? {
        guard let token = getToken() else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
    
    // MARK: - Get Current User (Validate Token)
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
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    let user = try JSONDecoder().decode(UserResponse.self, from: data)
                    // Save parentId if available
                    if let parentId = user.id {
                        saveParentId(parentId)
                    }
                    return user
                } catch {
                    // Try alternative response format
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let userDict = json["user"] as? [String: Any] ?? json["data"] as? [String: Any] ?? json
                        let user = UserResponse(
                            id: userDict["id"] as? String,
                            name: userDict["name"] as? String,
                            email: userDict["email"] as? String
                        )
                        // Save parentId if available
                        if let parentId = user.id {
                            saveParentId(parentId)
                        }
                        return user
                    }
                    throw AuthError.serverError("Failed to decode user data")
                }
            } else {
                throw AuthError.serverError("Failed to get user: \(httpResponse.statusCode)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Update Profile
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
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let email = email { body["email"] = email }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let userDict = json["user"] as? [String: Any] ?? json["data"] as? [String: Any] ?? json
                    let user = UserResponse(
                        id: userDict["id"] as? String,
                        name: userDict["name"] as? String,
                        email: userDict["email"] as? String
                    )
                    // Save parentId if available
                    if let parentId = user.id {
                        saveParentId(parentId)
                    }
                    return user
                }
                throw AuthError.serverError("Failed to decode response")
            } else {
                throw AuthError.serverError("Update failed with status code: \(httpResponse.statusCode)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Change Password
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
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                throw AuthError.serverError("Password change failed with status code: \(httpResponse.statusCode)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
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
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                throw AuthError.serverError("Account deletion failed with status code: \(httpResponse.statusCode)")
            }
            
            // Clear token after successful deletion
            clearToken()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error.localizedDescription)
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
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw AuthError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                do {
                    let signUpResponse = try JSONDecoder().decode(SignUpResponse.self, from: data)
                    return signUpResponse
                } catch {
                    // If decoding fails, but status is success, return a basic success response
                    return SignUpResponse(message: "Account created successfully", user: nil)
                }
            } else {
                // Try to decode error message
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let errorMsg = errorData.message ?? errorData.error ?? "Sign up failed"
                    throw AuthError.serverError(errorMsg)
                } else {
                    throw AuthError.serverError("Sign up failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error.localizedDescription)
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
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw AuthError.encodingError
        }
        
        do {
            // Print request for debugging
            if let requestBody = request.httpBody,
               let bodyString = String(data: requestBody, encoding: .utf8) {
                print("Login Request Body: \(bodyString)")
                print("Login URL: \(url.absoluteString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Login Response: \(responseString)")
                print("Status Code: \(httpResponse.statusCode)")
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                do {
                    let signInResponse = try JSONDecoder().decode(SignInResponse.self, from: data)
                    return signInResponse
                } catch let decodeError {
                    print("Decode Error: \(decodeError)")
                    // Try to decode as simple token response or different formats
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Response JSON: \(json)")
                        // Try different possible token field names
                        if let token = json["token"] as? String {
                            return SignInResponse(token: token, user: nil, message: nil)
                        } else if let token = json["accessToken"] as? String {
                            return SignInResponse(token: token, user: nil, message: nil)
                        } else if let token = json["access_token"] as? String {
                            return SignInResponse(token: token, user: nil, message: nil)
                        } else if let dataDict = json["data"] as? [String: Any],
                                  let token = dataDict["token"] as? String {
                            return SignInResponse(token: token, user: nil, message: nil)
                        }
                    }
                    // If we can't decode, show the actual error
                    throw AuthError.serverError("Failed to decode response: \(decodeError.localizedDescription)")
                }
            } else {
                // Print error details for debugging
                print("Login failed with status code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error Response: \(responseString)")
                }
                
                // Try to decode error message
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let errorMsg = errorData.message ?? errorData.error ?? "Sign in failed"
                    throw AuthError.serverError(errorMsg)
                } else if let responseString = String(data: data, encoding: .utf8) {
                    // Try to parse as plain JSON object
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let errorMsg = (json["message"] as? String) ?? (json["error"] as? String) {
                            throw AuthError.serverError(errorMsg)
                        }
                    }
                    throw AuthError.serverError("Sign in failed: \(responseString)")
                } else {
                    throw AuthError.serverError("Sign in failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch let error as AuthError {
            print("AuthError: \(error.localizedDescription)")
            throw error
        } catch {
            print("Network Error: \(error.localizedDescription)")
            throw AuthError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Request/Response Models
struct SignUpRequest: Codable {
    let name: String
    let email: String
    let password: String
}

struct SignUpResponse: Codable {
    let message: String?
    let user: UserResponse?
}

struct UserResponse: Codable {
    let id: String?
    let name: String?
    let email: String?
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct SignInResponse: Codable {
    let token: String?
    let user: UserResponse?
    let message: String?
}

struct ErrorResponse: Codable {
    let message: String?
    let error: String?
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case networkError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return message
        }
    }
}


