import SwiftUI

struct StatsView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var settings: AppSettings
    @State private var newTagText = ""

    private let red = Color(red: 0.96, green: 0.36, blue: 0.36)

    private var weekTotal: Double {
        store.dailySummaries(last: 7).reduce(0) { $0 + $1.totalWorkMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Summary cards
                HStack(spacing: 0) {
                    StatCard(value: formatMinutes(store.todayWorkMinutes), label: "Today")
                    StatCard(value: formatMinutes(weekTotal), label: "This Week")
                    StatCard(
                        value: "\(store.currentStreak)",
                        label: "Streak",
                        icon: store.currentStreak > 0 ? "flame.fill" : "lock.fill",
                        iconColor: store.currentStreak > 0 ? .orange : red
                    )
                }

                // Heatmap
                VStack(alignment: .leading, spacing: 6) {
                    Text("LAST 18 WEEKS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    HeatmapView(data: store.heatmapData(weeks: 18))
                }

                Divider().padding(.horizontal, 8)

                // Categories
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORIES")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)

                    let byTag = store.minutesByTag()
                    let maxMins = byTag.first?.minutes ?? 1

                    if !byTag.isEmpty {
                        VStack(spacing: 7) {
                            ForEach(byTag, id: \.tag) { entry in
                                HStack(spacing: 8) {
                                    Text(entry.tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                        .frame(width: 72, alignment: .leading)

                                    // Proportional bar
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.secondary.opacity(0.08))
                                        Capsule()
                                            .fill(red.opacity(0.75))
                                            .frame(width: 72 * CGFloat(entry.minutes / maxMins))
                                    }
                                    .frame(width: 72, height: 5)

                                    Text(formatMinutes(entry.minutes))
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)

                                    // Remove from quick-select list
                                    if settings.tags.contains(entry.tag) {
                                        Button {
                                            settings.tags.removeAll { $0 == entry.tag }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(.tertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // Add new category
                    HStack(spacing: 6) {
                        TextField("New category...", text: $newTagText)
                            .font(.system(size: 11))
                            .textFieldStyle(.plain)
                            .onSubmit { addTag() }
                        if !newTagText.isEmpty {
                            Button("Add") { addTag() }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(red)
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1), lineWidth: 0.5))
                }

                Divider().padding(.horizontal, 8)

                // Lifetime stats
                HStack(spacing: 0) {
                    MiniStat(value: "\(store.totalWorkSessions)", label: "Total Sessions")
                    MiniStat(value: formatHours(store.totalWorkHours), label: "Total Hours")
                    MiniStat(
                        value: "\(store.bestStreak)",
                        label: "Best Streak",
                        icon: "trophy.fill",
                        iconColor: Color(red: 1.0, green: 0.75, blue: 0.2)
                    )
                    MiniStat(value: formatMinutes(store.bestDayMinutes), label: "Best Day")
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
        }
    }

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !settings.tags.contains(trimmed) else { newTagText = ""; return }
        settings.tags.append(trimmed)
        newTagText = ""
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let h = Int(minutes) / 60, m = Int(minutes) % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func formatHours(_ hours: Double) -> String {
        hours >= 1 ? String(format: "%.1fh", hours) : "\(Int(hours * 60))m"
    }
}

// MARK: - Heatmap

struct HeatmapView: View {
    let data: [(date: Date, minutes: Double)]
    private let cellSize: CGFloat = 11
    private let gap: CGFloat = 2
    private let weeks = 18

    private func heatColor(for minutes: Double) -> Color {
        guard minutes >= 0 else { return .clear }
        guard minutes > 0   else { return Color.secondary.opacity(0.12) }
        let t = min(1.0, minutes / 120.0)
        return Color(red: 0.96, green: 0.36, blue: 0.36).opacity(0.2 + t * 0.8)
    }

    private func monthLabel(weekIndex: Int) -> String? {
        let idx = weekIndex * 7
        guard idx < data.count else { return nil }
        let date = data[idx].date
        let day = Calendar.current.component(.day, from: date)
        guard weekIndex == 0 || day <= 7 else { return nil }
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: gap) {
                ForEach(0..<weeks, id: \.self) { wi in
                    Text(monthLabel(weekIndex: wi) ?? "")
                        .font(.system(size: 7, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize)
                }
            }
            HStack(alignment: .top, spacing: gap) {
                ForEach(0..<weeks, id: \.self) { wi in
                    VStack(spacing: gap) {
                        ForEach(0..<7, id: \.self) { di in
                            let idx = wi * 7 + di
                            if idx < data.count {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(heatColor(for: data[idx].minutes))
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stat cards

struct StatCard: View {
    let value: String; let label: String
    var icon: String? = nil; var iconColor: Color = .primary
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                if let icon { Image(systemName: icon).font(.system(size: 12)).foregroundStyle(iconColor) }
                Text(value).font(.system(size: 16, weight: .bold, design: .rounded))
            }
            Text(label).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MiniStat: View {
    let value: String; let label: String
    var icon: String? = nil; var iconColor: Color = .primary
    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 2) {
                if let icon { Image(systemName: icon).font(.system(size: 9)).foregroundStyle(iconColor) }
                Text(value).font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
