// FLEXR - User Feedback Request Model
// For collecting feature requests, bug reports, and general feedback

import Foundation

enum UserFeedbackCategory: String, Codable, CaseIterable {
    case featureRequest = "feature_request"
    case bugReport = "bug_report"
    case general = "general"
    case pulseCheck = "pulse_check"

    var displayName: String {
        switch self {
        case .featureRequest: return "Feature Request"
        case .bugReport: return "Bug Report"
        case .general: return "General Feedback"
        case .pulseCheck: return "Quick Thought"
        }
    }

    var icon: String {
        switch self {
        case .featureRequest: return "lightbulb.fill"
        case .bugReport: return "ladybug.fill"
        case .general: return "bubble.left.fill"
        case .pulseCheck: return "heart.fill"
        }
    }

    var placeholder: String {
        switch self {
        case .featureRequest: return "What feature would make FLEXR better for you?"
        case .bugReport: return "What went wrong? Please describe what happened..."
        case .general: return "What's on your mind?"
        case .pulseCheck: return "One thing you'd improve about FLEXR..."
        }
    }
}

struct UserFeedbackRequest: Codable, Identifiable {
    let id: UUID?
    let userId: UUID
    let category: String
    let message: String
    let appContext: String?
    let trainingWeek: Int?
    let daysSinceSignup: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case message
        case appContext = "app_context"
        case trainingWeek = "training_week"
        case daysSinceSignup = "days_since_signup"
        case createdAt = "created_at"
    }

    init(
        userId: UUID,
        category: UserFeedbackCategory,
        message: String,
        appContext: String? = nil,
        trainingWeek: Int? = nil,
        daysSinceSignup: Int? = nil
    ) {
        self.id = nil
        self.userId = userId
        self.category = category.rawValue
        self.message = message
        self.appContext = appContext
        self.trainingWeek = trainingWeek
        self.daysSinceSignup = daysSinceSignup
        self.createdAt = nil
    }
}
