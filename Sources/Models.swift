import Foundation

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
