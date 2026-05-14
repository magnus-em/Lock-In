import Foundation

// MARK: - Problem tracking

enum ProblemDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

enum Confidence: String, Codable, CaseIterable {
    case solid = "Got it"
    case shaky = "Shaky"
    case struggled = "Struggled"
}

enum ProblemDomain: String, Codable, CaseIterable {
    case quant = "Quant"
    case swe   = "SWE"
    case ai    = "AI/ML"

    var categories: [String] {
        switch self {
        case .quant: return [
            "Probability", "Combinatorics", "Expected Value", "Distributions",
            "Random Walks", "Martingales", "Stochastic Calculus", "Game Theory",
            "Markov Chains", "Linear Algebra", "Statistics", "Options Math", "Brainteasers"
        ]
        case .swe: return [
            "Arrays & Hashing", "Two Pointers", "Sliding Window", "Stack",
            "Binary Search", "Linked List", "Trees", "Tries", "Heap",
            "Backtracking", "Graphs", "Dynamic Programming", "Greedy",
            "Intervals", "Bit Manipulation", "Math & Geometry"
        ]
        case .ai: return [
            "Machine Learning", "Deep Learning", "Transformers & LLMs",
            "RAG & Embeddings", "Reinforcement Learning", "Computer Vision",
            "NLP", "Probability & Stats", "System Design (AI)",
            "Coding for ML", "MLOps", "AI Safety"
        ]
        }
    }
}

struct ProblemEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let domain: ProblemDomain
    let categories: [String]
    let difficulty: ProblemDifficulty
    var needsReview: Bool
    var confidence: Confidence
    var source: String
    var notes: String
    var url: String
    var solveMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id, date, title, domain, categories, difficulty
        case needsReview, confidence, source, notes, url, solveMinutes
    }

    init(title: String, domain: ProblemDomain, categories: [String],
         difficulty: ProblemDifficulty, source: String = "",
         needsReview: Bool = false, confidence: Confidence = .solid,
         notes: String = "", url: String = "", solveMinutes: Int? = nil) {
        self.id = UUID()
        self.date = Date()
        self.title = title
        self.domain = domain
        self.categories = categories
        self.difficulty = difficulty
        self.source = source
        self.needsReview = needsReview
        self.confidence = confidence
        self.notes = notes
        self.url = url
        self.solveMinutes = solveMinutes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,              forKey: .id)
        date         = try c.decode(Date.self,              forKey: .date)
        title        = try c.decode(String.self,            forKey: .title)
        domain       = try c.decode(ProblemDomain.self,     forKey: .domain)
        categories   = try c.decode([String].self,          forKey: .categories)
        difficulty   = try c.decode(ProblemDifficulty.self, forKey: .difficulty)
        needsReview  = try c.decodeIfPresent(Bool.self,        forKey: .needsReview)  ?? false
        confidence   = try c.decodeIfPresent(Confidence.self,  forKey: .confidence)   ?? .solid
        source       = try c.decodeIfPresent(String.self,      forKey: .source)       ?? ""
        notes        = try c.decodeIfPresent(String.self,      forKey: .notes)        ?? ""
        url          = try c.decodeIfPresent(String.self,      forKey: .url)          ?? ""
        solveMinutes = try c.decodeIfPresent(Int.self,         forKey: .solveMinutes)
    }

    /// Days until this problem is due for review based on confidence.
    /// Returns nil if the problem doesn't need a scheduled review.
    var reviewDueDate: Date? {
        guard confidence != .solid || needsReview else { return nil }
        let interval: TimeInterval
        if needsReview       { interval = 1 * 86400 }
        else if confidence == .struggled { interval = 1 * 86400 }
        else                 { interval = 3 * 86400 } // shaky
        return date.addingTimeInterval(interval)
    }

    var isDueForReview: Bool {
        guard let due = reviewDueDate else { return false }
        return due <= Date()
    }
}

// MARK: - Timer sessions

struct WorkSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let durationMinutes: Double
    let type: SessionType
    var label: String?

    init(startTime: Date, durationMinutes: Double, type: SessionType, label: String? = nil) {
        self.id = UUID()
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.type = type
        self.label = label
    }

    enum SessionType: String, Codable {
        case work
        case shortBreak
        case longBreak
    }
}

struct DailySummary: Identifiable {
    let id: String
    let date: Date
    let totalWorkMinutes: Double
    let sessionCount: Int
}

// MARK: - Scratchpad

struct ScratchItem: Codable, Identifiable {
    let id: UUID
    var text: String
    var isChecked: Bool

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.isChecked = false
    }
}
