import Foundation

class QuestService {
    static let shared = QuestService()
    private let apiURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
    
    private init() {}
    
    // MARK: - Get Quests
    func getQuests(parentId: String, kidId: String) async throws -> [Quest] {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)/quests") else {
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
            throw AuthError.serverError("Failed to fetch quests")
        }
        
        return try JSONDecoder().decode([Quest].self, from: data)
    }
    
    // MARK: - Claim Quest Reward
    func claimQuestReward(parentId: String, kidId: String, questId: String) async throws -> Child {
        guard let url = URL(string: "\(apiURL)/parents/\(parentId)/kids/\(kidId)/quests/\(questId)/claim") else {
            throw AuthError.invalidURL
        }
        
        guard let token = AuthService.shared.getToken() else {
            throw AuthError.serverError("No token found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
             if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                 throw AuthError.serverError(errorData.message ?? "Failed to claim reward")
             }
            throw AuthError.serverError("Failed to claim reward")
        }
        
        // The backend returns the updated Child object
         // Decoding logic for Child - we need to map the response to our Child model
         // The backend returns the full child object
         
        // Helper to match the backend response structure
        // Often backend returns just the child object, but let's check carefully.
        // Assuming it returns the Child JSON directly.
        
        // Note: Child model expects specific fields. The backend response might have _id.
        // We rely on Child decodable logic. However, Child model doesn't strictly handle _id -> id mapping in init(decoder) unless we add CodingKeys?
        // Wait, Child struct in Child.swift is default Codable. It expects keys like "id".
        // The backend logic (Node.js) usually sends "_id".
        // I might need a custom decoder for Child or mapping logic if I haven't added it.
        // Reviewing Child.swift: It is default Codable.
        // Reviewing AuthService.swift: It manually maps responses to ChildResponse or Child objects.
        // I should probably follow the pattern in AuthService.swift: decode a response generic struct and map to Child.
        
        // Let's decode to a dictionary first to be safe or use a response struct if I knew it.
        // The backend code says: return { ...childObj, parentId: ... }
        
        // I'll assume for now I can decode to `Child` BUT I should probably add CodingKeys to Child.swift strictly speaking if I want automatic decoding, OR do manual mapping.
        // Given I just rewrote Child.swift without CodingKeys, I should probably stick to manual mapping or update Child.swift again.
        // Actually, AuthService manually maps "ChildResponse" to "Child".
        // I should return the raw data or a "ChildResponse" and let ViewModel handle the mapping to "Child" model?
        // OR, I can update Child to accept `_id`.
        // Let's stick to returning `ChildResponse` (from AuthService scope? No, that's internal to AuthService probably).
        // I'll duplicate the `ChildResponse` struct here or make it public if it isn't.
        // Wait, `ChildResponse` was used in AuthService but I don't see it defined in the file view I had (it was cut off or I missed it). It's likely in AuthService.swift or a separate file.
        
        // Better approach: Since I am writing `QuestService`, let's just decoding to `Child` directly via a helper or custom decoding to match existing patterns.
        // I'll try to decode `Child` directly, but if that fails, I'll return the dictionary.
        // Actually, the best way is to let the ViewModel handle the state update by fetching the child again or trusting the return.
        // Let's try to decoding to `Child` but I need to be careful about `id` vs `_id`.
        
        // For now, I will return `Child` and assume the backend sends `id` or I will add a coding key strategy to the decoder.
        let decoder = JSONDecoder()
        // No custom key strategy usually handles _id -> id automatically without keys.
        
        // Let's define a local Codable struct matching backend child exactly.
        struct BackendChild: Codable {
            let _id: String
            let name: String
            let age: Int
            let level: String?
            let avatarEmoji: String?
            let Score: Int?
            let totalPoints: Int?
            let connectionToken: String?
            let parentId: String?
            // gifts, quests etc...
        }
        
        // It's getting complicated to map perfectly without seeing the full Backend response.
        // BUT, the `AuthViewModel` has a `loadChildrenForCurrentUser` that maps `ChildResponse` to `Child`.
        // Ideally I should reuse that logic.
        
        // I will return `Data` or `Any` and let the ViewModel handle it? No, type safety.
        // I'll return `Child` but I'll add a helper init to Child or just manually map here.
        
        // Let's act like AuthService: Decode to a struct that matches JSON, then map to Child.
        
        struct ResponseData: Codable {
            let _id: String
            let name: String
            let age: Int
            let level: String?
            let avatarEmoji: String?
            let Score: Int?
            let totalPoints: Int?
            let connectionToken: String?
            let parentId: String?
            let quests: [Quest]?
            let shopCatalog: [Gift]?
            let inventory: [Gift]?
        }
        
        let res = try decoder.decode(ResponseData.self, from: data)
        
        return Child(
            id: res._id,
            name: res.name,
            age: res.age,
            level: res.level ?? "1",
            avatarEmoji: res.avatarEmoji ?? "😀",
            Score: res.Score ?? 0,
            quizzes: [], // Backend might not return full quizzes or we might ignore them
            totalPoints: res.totalPoints ?? 0,
            connectionToken: res.connectionToken ?? "",
            rewards: [], // Legacy rewards
            parentId: res.parentId,
            shopCatalog: res.shopCatalog,
            inventory: res.inventory,
            quests: res.quests
        )
    }
}
