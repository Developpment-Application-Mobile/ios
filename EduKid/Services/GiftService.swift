import Foundation

class GiftService {
    static let shared = GiftService()
    private let baseURL =  "https://preterrestrial-georgann-recappable.ngrok-free.dev"
    private let apiURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
    
    private init() {}
    
    // MARK: - Create Gift
    func createGift(parentId: String, kidId: String, title: String, cost: Int) async throws -> Gift {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)/gifts") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body: [String: Any] = [
            "title": title,
            "cost": cost
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw AuthError.serverError("Failed to create gift")
        }
        
        return try JSONDecoder().decode(Gift.self, from: data)
    }
    
    // MARK: - Get Gifts
    func getGifts(parentId: String, kidId: String) async throws -> [Gift] {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)/gifts") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to fetch gifts")
        }
        
        return try JSONDecoder().decode([Gift].self, from: data)
    }
    
    // MARK: - Buy Gift
    func buyGift(parentId: String, kidId: String, giftId: String) async throws -> (message: String, remainingScore: Int, gift: Gift) {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)/gifts/\(giftId)/buy") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        var body = Data() // Empty body for POST
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
             if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                 throw AuthError.serverError(errorData.message ?? errorData.error ?? "Failed to buy gift")
             }
             throw AuthError.serverError("Failed to buy gift")
        }

        struct BuyResponse: Decodable {
            let message: String
            let remainingScore: Int
            let gift: Gift
        }
        
        let decoded = try JSONDecoder().decode(BuyResponse.self, from: data)
        return (decoded.message, decoded.remainingScore, decoded.gift)
    }
    
    // MARK: - Delete Gift
    func deleteGift(parentId: String, kidId: String, giftId: String) async throws {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)/gifts/\(giftId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw AuthError.serverError("Failed to delete gift")
        }
    }
    
    // MARK: - Sync Child Score (Frontend Workaround)
    // This updates the backend Score to match calculated points
    func syncChildScore(parentId: String, kidId: String, calculatedScore: Int) async throws {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"  // FIXED: Use PATCH instead of PUT
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        // Update only the Score field
        let body: [String: Any] = [
            "Score": calculatedScore
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("⚠️ Failed to sync Score field: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw AuthError.serverError("Failed to sync Score")
        }
        
        print("✅ Successfully synced backend Score to \(calculatedScore) points")
    }
}
