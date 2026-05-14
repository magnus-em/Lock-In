import SwiftUI

struct TimerView: View {
    @ObservedObject var timer: TimerManager
    @ObservedObject var store: SessionStore
    @ObservedObject var settings: AppSettings
    @ObservedObject var dayStore: DayStore
    @Binding var showCommitment: Bool

    @State private var showBreakPicker = false

    private var phaseColor: Color {
        switch timer.currentPhase {
        case .work:       return Color(red: 0.96, green: 0.36, blue: 0.36)
        case .shortBreak, .longBreak: return Color(red: 0.27, green: 0.62, blue: 0.83)
        }
    }

    private var goalProgress: Double {
        guard settings.dailyGoal > 0 else { return 0 }
        return min(1.0, store.todayWorkMinutes / 60.0 / Double(settings.dailyGoal))
    }

    var body: some View {
        VStack(spacing: 10) {
            dayStatusRow

            Text(timer.currentPhase.displayName.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(phaseColor)

            if !timer.isOnBreak {
                if settings.tags.isEmpty {
                    Text("Add categories in the Stats tab")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(settings.tags, id: \.self) { tag in
                                let selected = timer.currentLabel == tag
                                Button(tag) { timer.currentLabel = selected ? "" : tag }
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(selected ? phaseColor.opacity(0.18) : Color.secondary.opacity(0.08))
                                    .foregroundStyle(selected ? phaseColor : Color.secondary)
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }

            if timer.isBlockingActive {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill").font(.system(size: 9))
                    Text("Sites Blocked").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(phaseColor.opacity(0.7))
            }

            if !timer.isActive && !timer.isOnBreak {
                HStack(spacing: 6) {
                    ForEach([15, 25, 45, 60], id: \.self) { mins in
                        let selected = Int(timer.totalTime / 60) == mins
                        Button("\(mins)m") { timer.setSessionDuration(Double(mins)) }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(selected ? phaseColor.opacity(0.18) : Color.secondary.opacity(0.07))
                            .foregroundStyle(selected ? phaseColor : Color.secondary)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                    }
                }
            }

            ZStack {
                if settings.dailyGoal > 0 {
                    Circle()
                        .stroke(Color.secondary.opacity(0.08), lineWidth: 3)
                        .frame(width: 156, height: 156)
                    Circle()
                        .trim(from: 0, to: goalProgress)
                        .stroke(phaseColor.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 156, height: 156)
                        .rotationEffect(.degrees(-90))
                }

                Circle()
                    .stroke(phaseColor.opacity(0.12), lineWidth: 8)
                    .frame(width: 136, height: 136)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 136, height: 136)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timer.progress)

                VStack(spacing: 4) {
                    Text(timer.timeString)
                        .font(.system(size: 34, weight: .medium, design: .monospaced))
                        .contentTransition(.numericText())
                        .animation(.linear(duration: 0.3), value: timer.timeString)

                    if !timer.isOnBreak && store.todaySessionCount > 0 {
                        Text("Session \(store.todaySessionCount + (timer.isActive ? 1 : 0))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(phaseColor.opacity(0.5))
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    timer.reset()
                } label: {
                    Image(systemName: timer.isActive ? "stop.fill" : "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(timer.isActive ? "End session (saves progress)" : "Reset timer")

                Button {
                    timer.isRunning ? timer.pause() : timer.start()
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(phaseColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: timer.skip) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if timer.isActive && !timer.isOnBreak {
                HStack(spacing: 6) {
                    ForEach([-10, -5, 5, 10], id: \.self) { delta in
                        Button(delta > 0 ? "+\(delta)m" : "\(delta)m") {
                            timer.adjustDuration(by: Double(delta))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.07))
                        .foregroundStyle(delta > 0 ? phaseColor : Color.secondary)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
            }

            if !timer.isActive && !timer.isOnBreak {
                Button {
                    showBreakPicker = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 10))
                        Text("Take a Break")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.07))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Divider().padding(.horizontal, 8)

            HStack {
                VStack(spacing: 2) {
                    Text(formatMinutes(store.todayWorkMinutes))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("Focus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text(formatMinutes(store.todayBreakMinutes))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                    Text("Break")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                if settings.dailyGoal > 0 {
                    let hoursToday = store.todayWorkMinutes / 60.0
                    let goalMet = hoursToday >= Double(settings.dailyGoal)
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f/\(settings.dailyGoal)h", hoursToday))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(goalMet ? Color.green : Color.primary)
                            .contentTransition(.numericText())
                        Text("Goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(goalMet ? Color.green : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 2) {
                        Text("\(store.currentStreak)d")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(store.currentStreak > 0 ? .orange : .secondary)
                        Text("Streak")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showBreakPicker) {
            BreakPickerSheet { minutes in
                timer.startManualBreak(minutes: minutes)
            }
        }
    }

    @ViewBuilder
    private var dayStatusRow: some View {
        if dayStore.isDayEnded {
            HStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Text("Day ended")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        } else if dayStore.isDayStarted {
            HStack {
                if let start = dayStore.todayRecord?.dayStart {
                    Text("Since \(clockStr(start))")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("End Day") { dayStore.endDay() }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
        } else {
            HStack {
                Spacer()
                Button {
                    dayStore.startDay()
                    if settings.commitmentEnabled && settings.needsCommitmentToday {
                        showCommitment = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 10))
                        Text("Start Day")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(phaseColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(phaseColor.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let h = Int(minutes) / 60, m = Int(minutes) % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func clockStr(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mma"; return f.string(from: d)
    }
}

private struct BreakPickerSheet: View {
    let onSelect: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCustom = false
    @State private var customMinutes: Double = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Take a Break")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                ForEach([(30.0, "30 minutes"), (60.0, "1 hour"), (120.0, "2 hours")], id: \.0) { mins, label in
                    Button {
                        onSelect(mins)
                        dismiss()
                    } label: {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.08))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                if showCustom {
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(Int(customMinutes)) min")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .frame(width: 70)
                            Stepper("", value: $customMinutes, in: 5...480, step: 5)
                                .labelsHidden()
                        }
                        Button {
                            onSelect(customMinutes)
                            dismiss()
                        } label: {
                            Text("Start \(Int(customMinutes)) min break")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.27, green: 0.62, blue: 0.83).opacity(0.12))
                                .foregroundStyle(Color(red: 0.27, green: 0.62, blue: 0.83))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button("Custom…") { showCustom = true }
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 240)
    }
}
