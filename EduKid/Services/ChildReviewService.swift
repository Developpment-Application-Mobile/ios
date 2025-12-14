import Foundation

class ChildReviewService {
    static let shared = ChildReviewService()
    
    private let baseURL = "https://preterrestrial-georgann-recappable.ngrok-free.dev"
    
    private init() {}
    
    // Generate Report API Call - Now automatically gets correct MongoDB ID
    // POST /parents/:parentId/kids/:kidId/review
    func generateReview(kidId: String) async throws -> ChildReviewResponseDto {
        print("🔍 Starting report generation for child: \(kidId)")
        
        // ⭐ Get the MongoDB parent ID (not UUID)
        let parentId = try await ParentIdHelper.shared.getMongoParentId()
        
        // Construct URL
        let urlString = "\(baseURL)/parents/\(parentId)/kids/\(kidId)/review"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
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
        
        // Empty body as per backend spec
        request.httpBody = try? JSONSerialization.data(withJSONObject: [:])
        
        // Detailed logging
        print("📊 Requesting report generation...")
        print("📊 URL: \(url.absoluteString)")
        print("📊 ParentId (MongoDB): \(parentId)")
        print("📊 KidId: \(kidId)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw AuthError.invalidResponse
        }
        
        print("📊 Response status: \(httpResponse.statusCode)")
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200, 201:
            // Success - try to decode
            do {
                let report = try JSONDecoder().decode(ChildReviewResponseDto.self, from: data)
                print("✅ Report generated successfully for \(report.childName)")
                return report
            } catch {
                print("❌ Decoding Error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("📊 Raw Response (First 1000 chars): \(raw.prefix(1000))")
                }
                throw AuthError.serverError("Failed to decode report response")
            }
            
        case 404:
            // Not found - likely wrong IDs
            if let raw = String(data: data, encoding: .utf8) {
                print("❌ 404 Error Body: \(raw)")
            }
            throw AuthError.serverError("Parent or child not found. Please verify the IDs are correct.")
            
        case 401:
            throw AuthError.serverError("Authentication failed. Please log in again.")
            
        default:
            // Other errors
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.message ?? errorData.error ?? "Failed to generate report")
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("📊 Error Body: \(raw)")
            }
            
            throw AuthError.serverError("Failed to generate report (Status: \(httpResponse.statusCode))")
        }
    }
}

