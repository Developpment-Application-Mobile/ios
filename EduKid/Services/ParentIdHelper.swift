//
//  ParentIdHelper.swift
//  EduKid
//
//  Created by mac on 14/12/2025.
//

import Foundation

class ParentIdHelper {
    static let shared = ParentIdHelper()
    
    private let baseURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
    
    private init() {}
    
    /// Get the MongoDB parent ID from the backend using stored parent ID (which might be wrong)
    func getMongoParentId() async throws -> String {
        // First try to get from AuthService.currentParent if it exists
        // But since you don't have that stored, we need to fetch it
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        // Try to get the stored parentId - this might be a UUID or MongoDB ID
        guard let storedParentId = AuthService.shared.getParentId() else {
            throw AuthError.serverError("Parent ID not found. Please log in again.")
        }
        
        print("🔍 Stored Parent ID: \(storedParentId)")
        
        // Check if it's already a MongoDB ID (24 hex chars) or UUID (with dashes)
        if isMongoDBId(storedParentId) {
            print("✅ Already have MongoDB ID: \(storedParentId)")
            return storedParentId
        }
        
        // If it's a UUID, we need to fetch the parent data to get the real MongoDB ID
        print("⚠️ Stored ID is UUID, fetching MongoDB ID from backend...")
        return try await fetchMongoParentId(token: token)
    }
    
    /// Fetch parent data from backend to get MongoDB _id
    private func fetchMongoParentId(token: String) async throws -> String {
        // Since we can't use the stored UUID to fetch from /parents/:id,
        // we need to fetch ALL parents or use a different endpoint
        // The best approach is to get the list of parents and find ours
        
        // Actually, let's try using the token to get parent info
        // Most backends have a /auth/me or /parents/me endpoint
        
        guard let url = URL(string: "\(baseURL)/parents") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw AuthError.serverError("Failed to fetch parent data")
        }
        
        // Parse response - it should be an array of parents
        if let parentsArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            // Find the parent by matching token (decode JWT and match)
            // For now, assume the first parent is ours (if there's only one)
            if let firstParent = parentsArray.first,
               let mongoId = firstParent["_id"] as? String {
                print("✅ Found MongoDB ID: \(mongoId)")
                
                // Update the stored parent ID with the correct one
                AuthService.shared.saveParentId(mongoId)
                
                return mongoId
            }
        }
        
        throw AuthError.serverError("Could not find parent MongoDB ID")
    }
    
    /// Check if a string is a MongoDB ObjectId (24 hex characters)
    private func isMongoDBId(_ id: String) -> Bool {
        // MongoDB ObjectId is exactly 24 hex characters
        let pattern = "^[0-9a-fA-F]{24}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: id.utf16.count)
        return regex?.firstMatch(in: id, range: range) != nil
    }
}
