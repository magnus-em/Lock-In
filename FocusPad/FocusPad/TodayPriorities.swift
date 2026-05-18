import Foundation
import SwiftUI

/// "Today's Top 3" lives in UserDefaults rather than SwiftData. Keeps it
/// out of the way of CloudKit schema setup, and they're naturally per-device
/// (your priorities on iPad don't have to match your Mac).
///
/// Storage layout:
///   "padPriorities.dayKey"     → String, format "yyyy-MM-dd"
///   "padPriorities.items"      → [["text": String, "done": Bool]]
final class TodayPriorities: ObservableObject {
    struct Item: Identifiable, Hashable, Codable {
        let id: UUID
        var text: String
        var done: Bool
    }

    @Published private(set) var items: [Item] = []

    init() { load() }

    var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func load() {
        let d = UserDefaults.standard
        let storedKey = d.string(forKey: "padPriorities.dayKey")
        if storedKey != dayKey {
            // New day — clear (keeps the UI honest).
            items = []
            d.set(dayKey, forKey: "padPriorities.dayKey")
            d.set(Data(), forKey: "padPriorities.items")
            return
        }
        if let data = d.data(forKey: "padPriorities.items"),
           let decoded = try? JSONDecoder().decode([Item].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "padPriorities.items")
            UserDefaults.standard.set(dayKey, forKey: "padPriorities.dayKey")
        }
    }

    func add(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        items.append(Item(id: UUID(), text: t, done: false))
        if items.count > 5 { items.removeFirst(items.count - 5) }
        save()
    }

    func toggle(_ item: Item) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].done.toggle()
        save()
    }

    func remove(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }
}
