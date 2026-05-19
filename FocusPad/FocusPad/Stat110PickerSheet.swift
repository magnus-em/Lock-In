import SwiftUI
import FocusCore

/// Sheet for picking a Stat 110 problem to log as homework. Shows each
/// problem set, splits into Strategic Practice (grouped by topic) and
/// Homework, and dims problems the user has already logged. Tapping a row
/// returns the picked `Stat110Problem` via `onPick`.
struct Stat110PickerSheet: View {
    let completedIDs: Set<String>
    let onPick: (Stat110Problem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var expandedSets: Set<Int> = [
        Stat110Catalog.all.last?.setNumber ?? 0
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Stat110Catalog.all) { set in
                    Section {
                        if expandedSets.contains(set.setNumber) {
                            setContent(set)
                        }
                    } header: {
                        setHeader(set)
                    }
                }
                Section {
                    Text("More problem sets coming. The catalog lives in code so adding HW3+ is a one-file change.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Stat 110")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func setHeader(_ set: Stat110ProblemSet) -> some View {
        let done = set.problems.filter { completedIDs.contains($0.id) }.count
        let total = set.problems.count
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if expandedSets.contains(set.setNumber) {
                    expandedSets.remove(set.setNumber)
                } else {
                    expandedSets.insert(set.setNumber)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: expandedSets.contains(set.setNumber) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                Text(set.title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(done)/\(total)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(done == total ? .green : .secondary)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func setContent(_ set: Stat110ProblemSet) -> some View {
        // Strategic Practice — grouped by topic with topic chip on each row.
        if !set.strategicPractice.isEmpty {
            DisclosureGroup("Strategic Practice") {
                ForEach(set.spByTopic, id: \.topic) { group in
                    Section {
                        ForEach(group.items) { p in problemRow(p) }
                    } header: {
                        Text(group.topic)
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            .font(.system(size: 14, weight: .semibold))
        }
        if !set.homework.isEmpty {
            DisclosureGroup("Homework") {
                ForEach(set.homework) { p in problemRow(p) }
            }
            .font(.system(size: 14, weight: .semibold))
        }
        if let url = URL(string: set.pdfURL) {
            Link(destination: url) {
                Label("Open PDF", systemImage: "doc.text")
                    .font(.system(size: 13))
            }
        }
    }

    private func problemRow(_ p: Stat110Problem) -> some View {
        let isDone = completedIDs.contains(p.id)
        return Button {
            onPick(p)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .font(.system(size: 16))
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("#\(p.number)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        if let topic = p.topic {
                            Text(topic)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color(red: 0.62, green: 0.45, blue: 0.92).opacity(0.15))
                                )
                                .foregroundStyle(Color(red: 0.50, green: 0.30, blue: 0.85))
                        }
                    }
                    Text(p.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
            .opacity(isDone ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
