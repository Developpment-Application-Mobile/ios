//
//  AdaptiveQuizSystem.swift
//  EduKid
//
//  Created by mac on 21/11/2025.
//

import Foundation

// MARK: - Performance Analytics
struct ChildPerformanceAnalytics {
    let childId: String
    let averageScore: Double
    let strongSubjects: [SubjectPerformance]
    let weakSubjects: [SubjectPerformance]
    let recommendedDifficulty: String
    let recommendedSubject: String
    let recommendedTopic: String
    let performanceTrend: PerformanceTrend
    let totalQuizzesTaken: Int
    let recentImprovement: Bool
}

struct SubjectPerformance {
    let subject: String
    let averageScore: Double
    let quizzesTaken: Int
    let lastScore: Int?
    let topics: [TopicPerformance]
}

struct TopicPerformance {
    let topic: String
    let averageScore: Double
    let attemptsCount: Int
}

enum PerformanceTrend {
    case improving
    case stable
    case declining
    case insufficient_data
}

// MARK: - Adaptive Quiz Service
class AdaptiveQuizService {
    static let shared = AdaptiveQuizService()
    
    private init() {}
    
    // MARK: - Analyze Child Performance
    func analyzePerformance(quizzes: [AIQuizResponse]) -> ChildPerformanceAnalytics {
        print("📊 ANALYZING PERFORMANCE: \(quizzes.count) quizzes")
        
        guard !quizzes.isEmpty else {
            return ChildPerformanceAnalytics(
                childId: "",
                averageScore: 0,
                strongSubjects: [],
                weakSubjects: [],
                recommendedDifficulty: "beginner",
                recommendedSubject: "math",
                recommendedTopic: "counting",
                performanceTrend: .insufficient_data,
                totalQuizzesTaken: 0,
                recentImprovement: false
            )
        }
        
        // Calculate overall average score
        let attemptedQuizzes = quizzes.filter { $0.answered > 0 }
        let totalScore = attemptedQuizzes.reduce(0.0) { result, quiz in
            let percentage = quiz.questions.count > 0 ?
                Double(quiz.score) / Double(quiz.questions.count) * 100.0 : 0.0
            return result + percentage
        }
        let averageScore = attemptedQuizzes.isEmpty ? 0 : totalScore / Double(attemptedQuizzes.count)
        
        // Analyze by subject
        let subjectPerformances = analyzeSubjects(quizzes: attemptedQuizzes)
        
        // Identify strong and weak subjects
        let sortedByPerformance = subjectPerformances.sorted { $0.averageScore > $1.averageScore }
        let strongSubjects = Array(sortedByPerformance.prefix(2))
        let weakSubjects = Array(sortedByPerformance.suffix(2).reversed())
        
        // Determine performance trend
        let trend = determinePerformanceTrend(quizzes: attemptedQuizzes)
        
        // Get recommendations
        let (recommendedSubject, recommendedTopic) = getNextRecommendation(
            weakSubjects: weakSubjects,
            strongSubjects: strongSubjects,
            allPerformances: subjectPerformances,
            trend: trend
        )
        
        let recommendedDifficulty = determineDifficulty(
            averageScore: averageScore,
            trend: trend,
            totalQuizzes: attemptedQuizzes.count
        )
        
        let recentImprovement = detectRecentImprovement(quizzes: attemptedQuizzes)
        
        print("✅ ANALYSIS COMPLETE:")
        print("   Average Score: \(String(format: "%.1f", averageScore))%")
        print("   Recommended: \(recommendedSubject) - \(recommendedTopic) (\(recommendedDifficulty))")
        print("   Trend: \(trend)")
        
        return ChildPerformanceAnalytics(
            childId: "",
            averageScore: averageScore,
            strongSubjects: strongSubjects,
            weakSubjects: weakSubjects,
            recommendedDifficulty: recommendedDifficulty,
            recommendedSubject: recommendedSubject,
            recommendedTopic: recommendedTopic,
            performanceTrend: trend,
            totalQuizzesTaken: quizzes.count,
            recentImprovement: recentImprovement
        )
    }
    
    // MARK: - Analyze Subjects
    private func analyzeSubjects(quizzes: [AIQuizResponse]) -> [SubjectPerformance] {
        var subjectData: [String: [(score: Double, topic: String)]] = [:]
        
        for quiz in quizzes {
            let percentage = quiz.questions.count > 0 ?
                Double(quiz.score) / Double(quiz.questions.count) * 100.0 : 0.0
            
            if subjectData[quiz.subject] == nil {
                subjectData[quiz.subject] = []
            }
            subjectData[quiz.subject]?.append((score: percentage, topic: quiz.topic))
        }
        
        return subjectData.map { subject, data in
            let averageScore = data.reduce(0.0) { $0 + $1.score } / Double(data.count)
            
            // Analyze topics within this subject
            var topicScores: [String: [Double]] = [:]
            for (score, topic) in data {
                if topicScores[topic] == nil {
                    topicScores[topic] = []
                }
                topicScores[topic]?.append(score)
            }
            
            let topics = topicScores.map { topic, scores in
                TopicPerformance(
                    topic: topic,
                    averageScore: scores.reduce(0.0, +) / Double(scores.count),
                    attemptsCount: scores.count
                )
            }.sorted { $0.averageScore < $1.averageScore } // Sort by weakest first
            
            let lastQuiz = quizzes.last(where: { $0.subject == subject })
            let lastScore = lastQuiz.map { quiz in
                quiz.questions.count > 0 ? Int((Double(quiz.score) / Double(quiz.questions.count)) * 100) : 0
            }
            
            return SubjectPerformance(
                subject: subject,
                averageScore: averageScore,
                quizzesTaken: data.count,
                lastScore: lastScore,
                topics: topics
            )
        }.sorted { $0.averageScore < $1.averageScore }
    }
    
    // MARK: - Determine Performance Trend
    private func determinePerformanceTrend(quizzes: [AIQuizResponse]) -> PerformanceTrend {
        guard quizzes.count >= 3 else { return .insufficient_data }
        
        let recent = Array(quizzes.suffix(3))
        let scores = recent.map { quiz in
            quiz.questions.count > 0 ? Double(quiz.score) / Double(quiz.questions.count) * 100.0 : 0.0
        }
        
        let firstScore = scores.first ?? 0
        let lastScore = scores.last ?? 0
        let difference = lastScore - firstScore
        
        if difference > 10 {
            return .improving
        } else if difference < -10 {
            return .declining
        } else {
            return .stable
        }
    }
    
    // MARK: - Detect Recent Improvement
    private func detectRecentImprovement(quizzes: [AIQuizResponse]) -> Bool {
        guard quizzes.count >= 2 else { return false }
        
        let recent = Array(quizzes.suffix(2))
        let scores = recent.map { quiz in
            quiz.questions.count > 0 ? Double(quiz.score) / Double(quiz.questions.count) * 100.0 : 0.0
        }
        
        guard let first = scores.first, let last = scores.last else { return false }
        return last > first + 5 // Improvement of 5% or more
    }
    
    // MARK: - Get Next Recommendation
    private func getNextRecommendation(
        weakSubjects: [SubjectPerformance],
        strongSubjects: [SubjectPerformance],
        allPerformances: [SubjectPerformance],
        trend: PerformanceTrend
    ) -> (subject: String, topic: String) {
        
        // Strategy 1: Focus on weakest subject 70% of the time
        if Double.random(in: 0...1) < 0.7, let weakest = weakSubjects.first {
            let weakestTopic = weakest.topics.first?.topic ?? "general"
            print("📌 STRATEGY: Focus on weak subject - \(weakest.subject) (\(weakestTopic))")
            return (weakest.subject, weakestTopic)
        }
        
        // Strategy 2: Reinforce strong subjects 20% of the time
        if Double.random(in: 0...1) < 0.67, let strong = strongSubjects.first {
            // Pick a more advanced topic in their strong subject
            let topics = strong.topics.sorted { $0.averageScore > $1.averageScore }
            let topic = topics.first?.topic ?? "general"
            print("📌 STRATEGY: Reinforce strength - \(strong.subject) (\(topic))")
            return (strong.subject, topic)
        }
        
        // Strategy 3: Introduce variety 10% of the time
        let allSubjects = ["math", "science", "english", "history", "geography"]
        let recentSubjects = allPerformances.map { $0.subject }
        let newSubjects = allSubjects.filter { !recentSubjects.contains($0) }
        
        if let newSubject = newSubjects.randomElement() {
            print("📌 STRATEGY: Introduce variety - \(newSubject)")
            return (newSubject, "introduction")
        }
        
        // Fallback
        return ("math", "general")
    }
    
    // MARK: - Determine Difficulty
    private func determineDifficulty(
        averageScore: Double,
        trend: PerformanceTrend,
        totalQuizzes: Int
    ) -> String {
        
        // Beginners (0-3 quizzes) start easy
        if totalQuizzes <= 3 {
            return "beginner"
        }
        
        // Based on performance
        switch averageScore {
        case 80...:
            // High performers get advanced
            return trend == .improving ? "advanced" : "intermediate"
            
        case 60..<80:
            // Medium performers stay intermediate or advance if improving
            return trend == .improving ? "intermediate" : "beginner"
            
        default:
            // Low performers stay at beginner or get easier
            return trend == .declining ? "beginner" : "beginner"
        }
    }
    
    // MARK: - Generate Adaptive Quiz
    func generateAdaptiveQuiz(
        parentId: String,
        child: Child,
        quizHistory: [AIQuizResponse]
    ) async throws -> AIQuizResponse {
        
        print("\n🎯 GENERATING ADAPTIVE QUIZ")
        print("   Child: \(child.name), Age: \(child.age)")
        print("   History: \(quizHistory.count) quizzes")
        
        // Analyze performance
        let analytics = analyzePerformance(quizzes: quizHistory)
        
        // Generate quiz based on recommendations
        let response = try await AIQuizService.shared.generateAIQuiz(
            parentId: parentId,
            kidId: child.id,
            subject: analytics.recommendedSubject,
            difficulty: analytics.recommendedDifficulty,
            nbrQuestions: determineQuestionCount(
                age: child.age,
                difficulty: analytics.recommendedDifficulty
            ),
            topic: analytics.recommendedTopic
        )
        
        print("✅ ADAPTIVE QUIZ GENERATED")
        print("   Subject: \(analytics.recommendedSubject)")
        print("   Topic: \(analytics.recommendedTopic)")
        print("   Difficulty: \(analytics.recommendedDifficulty)")
        
        return response
    }
    
    private func determineQuestionCount(age: Int, difficulty: String) -> Int {
        let baseCount = age <= 5 ? 5 : (age <= 8 ? 8 : (age <= 12 ? 10 : 12))
        
        switch difficulty {
        case "beginner":
            return baseCount
        case "intermediate":
            return baseCount + 2
        case "advanced":
            return baseCount + 4
        default:
            return baseCount
        }
    }
}
