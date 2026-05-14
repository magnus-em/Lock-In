import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timer: TimerManager
    @ObservedObject var store: SessionStore
    @State private var showResetConfirm = false
    @State private var newSourceText = ""

    // Manual session logging
    @State private var manualMinutes: Int = 60
    @State private var manualDate: Date = Date()
    @State private var manualLabel: String = ""
    @State private var manualLogged = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                SectionLabel("INTERVALS")
                IntervalRow(label: "Focus", value: $settings.workMinutes, range: 5...90, step: 5, unit: "min")
                IntervalRow(label: "Break", value: $settings.shortBreakMinutes, range: 1...60, step: 1, unit: "min")

                Divider()

                SectionLabel("DAILY GOAL")
                IntRow(label: "Daily Target", value: $settings.dailyGoal, range: 0...12, suffix: "h", zeroLabel: "Off")

                Divider()

                SectionLabel("COMMITMENT")
                ToggleRow(label: "Daily commitment + voice oath", isOn: $settings.commitmentEnabled)
                if settings.commitmentEnabled {
                    Text("You'll be prompted each morning to write your commitment for the day and optionally record a voice oath.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                SectionLabel("BEHAVIOR")
                ToggleRow(label: "Auto-break after session", isOn: $settings.autoBreakEnabled)
                ToggleRow(label: "Auto-start focus", isOn: $settings.autoStartWork)
                ToggleRow(label: "Sound effects", isOn: $settings.soundEnabled)
                IntRow(label: "Auto-end pause after", value: $settings.pauseGraceMinutes, range: 2...60, suffix: "min")

                HStack {
                    Text("Pause / resume hotkey")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("⌃⌥Space")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }

                Divider()

                SectionLabel("SITE BLOCKING")
                ToggleRow(label: "Block distracting sites", isOn: $settings.siteBlockingEnabled)

                if settings.siteBlockingEnabled {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(SiteBlocker.isSetUp ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(SiteBlocker.isSetUp ? "Helper installed" : "Helper not installed — tap to set up")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !SiteBlocker.isSetUp {
                            Button("Set Up") {
                                DispatchQueue.global(qos: .userInitiated).async { SiteBlocker.setUp() }
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(red: 0.96, green: 0.36, blue: 0.36))
                            .buttonStyle(.plain)
                        } else {
                            Button("Re-install") {
                                DispatchQueue.global(qos: .userInitiated).async { SiteBlocker.setUp() }
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .buttonStyle(.plain)
                        }
                    }
                    ToggleRow(label: "Block during breaks too", isOn: $settings.blockDuringBreaks)
                    BlockedSitesView(settings: settings)
                        .padding(.top, 2)
                }

                Divider()

                SectionLabel("INTERVIEW")

                if let date = settings.interviewDate {
                    HStack {
                        Text("Target date")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(get: { date }, set: { settings.interviewDate = $0 }),
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .controlSize(.small)

                        Button {
                            settings.interviewDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        // Default to 4 months from now
                        settings.interviewDate = Calendar.current.date(byAdding: .month, value: 4, to: Date())
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Set interview date")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                SectionLabel("PROBLEM GOALS")
                IntRow(label: "Quant target", value: $settings.quantGoal, range: 0...2000, suffix: "problems", zeroLabel: "Off")
                IntRow(label: "SWE target", value: $settings.sweGoal, range: 0...2000, suffix: "problems", zeroLabel: "Off")

                Divider()

                SectionLabel("PROBLEM SOURCES")

                VStack(spacing: 5) {
                    ForEach(settings.problemSources, id: \.self) { source in
                        HStack {
                            Text(source)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Button {
                                settings.problemSources.removeAll { $0 == source }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 6) {
                        TextField("New source…", text: $newSourceText)
                            .font(.system(size: 12))
                            .textFieldStyle(.plain)
                            .onSubmit { addSource() }
                        if !newSourceText.isEmpty {
                            Button("Add") { addSource() }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(red: 0.96, green: 0.36, blue: 0.36))
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(7)
                }

                Divider()

                SectionLabel("LOG MANUAL SESSION")

                VStack(spacing: 10) {
                    HStack {
                        Text("Duration")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(manualMinutes) min")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .trailing)
                        Stepper("", value: $manualMinutes, in: 1...480, step: 5)
                            .labelsHidden()
                            .controlSize(.small)
                    }

                    HStack {
                        Text("Date")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        DatePicker("", selection: $manualDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .controlSize(.small)
                    }

                    if !settings.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Label (optional)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    let noneSelected = manualLabel.isEmpty
                                    Button("None") { manualLabel = "" }
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(noneSelected ? Color.secondary.opacity(0.18) : Color.secondary.opacity(0.07))
                                        .foregroundStyle(noneSelected ? .primary : .secondary)
                                        .cornerRadius(6)
                                        .buttonStyle(.plain)
                                    ForEach(settings.tags, id: \.self) { tag in
                                        let sel = manualLabel == tag
                                        Button(tag) { manualLabel = sel ? "" : tag }
                                            .font(.system(size: 10, weight: .medium))
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 5)
                                            .background(sel ? Color(red: 0.96, green: 0.36, blue: 0.36).opacity(0.15) : Color.secondary.opacity(0.07))
                                            .foregroundStyle(sel ? Color(red: 0.96, green: 0.36, blue: 0.36) : Color.secondary)
                                            .cornerRadius(6)
                                            .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        let startTime = Calendar.current.startOfDay(for: manualDate)
                        let session = WorkSession(
                            startTime: startTime,
                            durationMinutes: Double(manualMinutes),
                            type: .work,
                            label: manualLabel.isEmpty ? nil : manualLabel
                        )
                        store.addSession(session)
                        manualLogged = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { manualLogged = false }
                    } label: {
                        HStack(spacing: 6) {
                            if manualLogged {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Logged!")
                                    .font(.system(size: 12, weight: .semibold))
                            } else {
                                Text("Log \(manualMinutes) min session")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(manualLogged ? Color.green.opacity(0.15) : Color(red: 0.96, green: 0.36, blue: 0.36).opacity(0.12))
                        .foregroundStyle(manualLogged ? Color.green : Color(red: 0.96, green: 0.36, blue: 0.36))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(manualLogged ? Color.green.opacity(0.3) : Color(red: 0.96, green: 0.36, blue: 0.36).opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: manualLogged)
                }

                Divider()

                if showResetConfirm {
                    VStack(spacing: 8) {
                        Text("Delete all session history?")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                        Text("This cannot be undone.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Button {
                                showResetConfirm = false
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 12, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(.secondary.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.clearAllData()
                                showResetConfirm = false
                            } label: {
                                Text("Reset")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.85))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(.secondary.opacity(0.05))
                    .cornerRadius(8)
                } else {
                    HStack {
                        Spacer()
                        Button { showResetConfirm = true } label: {
                            Text("Reset All Data")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red.opacity(0.8))
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
        }
        .onChange(of: settings.workMinutes)       { _, _ in timer.applySettings() }
        .onChange(of: settings.shortBreakMinutes) { _, _ in timer.applySettings() }
    }

    private func addSource() {
        let t = newSourceText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !settings.problemSources.contains(t) else { newSourceText = ""; return }
        settings.problemSources.append(t)
        newSourceText = ""
    }
}

// MARK: - Subviews

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(.secondary)
    }
}

private struct IntervalRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium))
            Spacer()
            Text("\(Int(value)) \(unit)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .trailing)
            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
                .controlSize(.small)
        }
    }
}

private struct IntRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = ""
    var zeroLabel: String? = nil

    private var display: String {
        if value == 0, let z = zeroLabel { return z }
        return suffix.isEmpty ? "\(value)" : "\(value) \(suffix)"
    }

    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium))
            Spacer()
            Text(display)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(value == 0 && zeroLabel != nil ? .tertiary : .secondary)
                .frame(minWidth: 56, alignment: .trailing)
            Stepper("", value: $value, in: range)
                .labelsHidden()
                .controlSize(.small)
        }
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}
