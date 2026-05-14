import Foundation

class DayStore: ObservableObject {
    @Published var records: [DayRecord] = []
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Focus")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("dayrecords.json")
        load()
    }

    var todayRecord: DayRecord? {
        records.first { Calendar.current.isDateInToday($0.calendarDay) }
    }

    var isDayStarted: Bool {
        guard let r = todayRecord else { return false }
        return r.dayStart != nil && r.dayEnd == nil
    }

    var isDayEnded: Bool { todayRecord?.dayEnd != nil }

    func startDay() {
        if let i = records.firstIndex(where: { Calendar.current.isDateInToday($0.calendarDay) }) {
            records[i].dayStart = Date()
            records[i].dayEnd = nil
        } else {
            var r = DayRecord()
            r.dayStart = Date()
            records.append(r)
        }
        save()
    }

    func endDay() {
        if let i = records.firstIndex(where: { Calendar.current.isDateInToday($0.calendarDay) }) {
            records[i].dayEnd = Date()
            save()
        }
    }

    func record(for date: Date) -> DayRecord? {
        records.first { Calendar.current.isDate($0.calendarDay, inSameDayAs: date) }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(records) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([DayRecord].self, from: data) {
            records = decoded
        }
    }
}
