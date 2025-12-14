import Foundation

// Review Request - empty as per backend spec
struct GenerateReviewDto: Codable {}

// Topic Performance Helper
struct ReviewTopicPerformance: Codable, Identifiable {
    let topic: String
    let quizzesCompleted: Int
    let averageScore: Double
    let highestScore: Int
    let lowestScore: Int
    
    var id: String { topic }
}

// Main Response Model
struct ChildReviewResponseDto: Codable {
    let childName: String
    let childAge: Int
    let childLevel: String
    let progressionLevel: Int
    let totalQuizzes: Int
    let overallAverage: Double
    let lifetimeScore: Int
    let currentScore: Int
    let performanceByTopic: [ReviewTopicPerformance]
    
    // AI Analysis Sections
    let strengths: String
    let weaknesses: String
    let recommendations: String
    let summary: String
    
    // Metadata
    let generatedAt: String
    let pdfBase64: String
    
    // Helper to get Date object
    var generatedDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: generatedAt) ?? Date()
    }
}
