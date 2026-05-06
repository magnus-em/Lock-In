import SwiftUI

struct TimerView: View {
    @ObservedObject var timer: TimerManager
    @ObservedObject var store: SessionStore
    @ObservedObject var settings: AppSettings
    @ObservedObject var commitment: CommitmentManager

    @State private var showCommitmentModal = false
    @State private var showCommitmentBreak = false
    @State private var commitmentName = ""

    private var phaseColor: Color {
        switch timer.currentPhase {
        case .work:       return Color(red: 0.96, green: 0.36, blue: 0.36)
        case .shortBreak: return Color(red: 0.30, green: 0.78, blue: 0.74)
        case .longBreak:  return Color(red: 0.27, green: 0.62, blue: 0.83)
        }
    }

    private var goalProgress: Double {
        guard settings.dailyGoal > 0 else { return 0 }
        return min(1.0, Double(store.todaySessionCount) / Double(settings.dailyGoal))
    }

    // MARK: - Button handlers

    private func handlePlayButton() {
        guard !timer.isAwaitingFlowDecision else { return }
        // Show commitment modal when starting a fresh work session
        if !timer.isActive && timer.currentPhase == .work && settings.commitmentModeEnabled {
            commitmentName = ""
            showCommitmentModal = true
        } else {
            timer.isRunning ? timer.pause() : timer.start()
        }
    }

    private func handleStopButton() {
        // If a committed work session is active, intercept and show break confirmation
        if timer.isActive && timer.currentPhase == .work && settings.commitmentModeEnabled && timer.isCommitted {
            if timer.isRunning { timer.pause() }
            if settings.commitmentVoiceEnabled { commitment.playback() }
            showCommitmentBreak = true
        } else {
            timer.reset()
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            mainContent

            if showCommitmentModal {
                CommitmentPreSessionView(
                    timer: timer,
                    settings: settings,
                    commitment: commitment,
                    name: $commitmentName,
                    phaseColor: phaseColor,
                    onBegin: {
                        showCommitmentModal = false
                        timer.startCommitted()
                    },
                    onCancel: {
                        showCommitmentModal = false
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            }

            if showCommitmentBreak {
                CommitmentBreakView(
                    timer: timer,
                    commitment: commitment,
                    settings: settings,
                    phaseColor: phaseColor,
                    onStayFocused: {
                        commitment.stopPlayback()
                        showCommitmentBreak = false
                        timer.start()
                    },
                    onBreakIt: {
                        commitment.stopPlayback()
                        showCommitmentBreak = false
                        timer.reset()
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            }
        }
    }

    // MARK: - Main timer content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 12) {
            // Phase label
            Text(timer.currentPhase.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(phaseColor)

            // Category selector
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
                            Button(tag) {
                                timer.currentLabel = selected ? "" : tag
                            }
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

            // Blocking badge
            if timer.isBlockingActive {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill").font(.system(size: 9))
                    Text("Sites Blocked").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(phaseColor.opacity(0.7))
            }

            // Commitment active badge
            if timer.isCommitted {
                HStack(spacing: 4) {
                    Image(systemName: "pencil.line").font(.system(size: 9))
                    Text("Committed").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(phaseColor.opacity(0.7))
            }

            // Quick presets — only when idle on a work phase
            if !timer.isActive && timer.currentPhase == .work {
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

            // Circular timer ring
            ZStack {
                // Outer ring — daily goal progress (hidden when goal is off)
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

                // Inner ring — session progress
                Circle()
                    .stroke(phaseColor.opacity(0.12), lineWidth: 8)
                    .frame(width: 136, height: 136)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 136, height: 136)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timer.progress)

                // Center display
                VStack(spacing: 4) {
                    Text(timer.timeString)
                        .font(.system(size: 34, weight: .medium, design: .monospaced))
                        .contentTransition(.numericText())
                        .animation(.linear(duration: 0.3), value: timer.timeString)

                    // Cycle position dots
                    if timer.currentPhase == .work {
                        let done = timer.workSessionsCompleted % settings.sessionsBeforeLongBreak
                        HStack(spacing: 5) {
                            ForEach(0..<settings.sessionsBeforeLongBreak, id: \.self) { i in
                                Circle()
                                    .fill(
                                        i < done          ? phaseColor :
                                        i == done         ? phaseColor.opacity(0.5) :
                                                            phaseColor.opacity(0.15)
                                    )
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }

            // Controls
            HStack(spacing: 12) {
                Button(action: handleStopButton) {
                    Image(systemName: timer.isActive ? "stop.fill" : "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(timer.isActive ? "End session (saves progress)" : "Reset timer")

                Button(action: handlePlayButton) {
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

            // Duration adjustment — active work session only, not during flow decision
            if timer.isActive && timer.currentPhase == .work && !timer.isAwaitingFlowDecision {
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

            Divider().padding(.horizontal, 8)

            // Today's stats
            HStack {
                VStack(spacing: 2) {
                    Text("\(store.todaySessionCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Sessions")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text(formatMinutes(store.todayWorkMinutes))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Focus Time")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                if settings.dailyGoal > 0 {
                    VStack(spacing: 2) {
                        Text("\(store.todaySessionCount)/\(settings.dailyGoal)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(store.todaySessionCount >= settings.dailyGoal ? .green : .primary)
                        Text("Goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let h = Int(minutes) / 60, m = Int(minutes) % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Pre-session commitment modal

private struct CommitmentPreSessionView: View {
    @ObservedObject var timer: TimerManager
    @ObservedObject var settings: AppSettings
    @ObservedObject var commitment: CommitmentManager
    @Binding var name: String
    let phaseColor: Color
    let onBegin: () -> Void
    let onCancel: () -> Void

    private var oathText: String {
        let mins = Int(timer.totalTime / 60)
        let labelPart = timer.currentLabel.isEmpty ? "" : " on \(timer.currentLabel)"
        let nameDisplay = name.trimmingCharacters(in: .whitespaces).isEmpty ? "____" : name.trimmingCharacters(in: .whitespaces)
        return "I, \(nameDisplay), commit to \(mins) minutes of focused work\(labelPart) without distraction."
    }

    private var canBegin: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            // Background fill
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack {
                        Image(systemName: "signature")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(phaseColor)
                        Text("Commit to this session")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }

                    // Oath text box
                    Text(oathText)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(phaseColor.opacity(0.07))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(phaseColor.opacity(0.2), lineWidth: 1))

                    // Name field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Sign your name")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(.secondary)

                        TextField("Your name...", text: $name)
                            .font(.system(size: 13, weight: .medium))
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.secondary.opacity(0.07))
                            .cornerRadius(7)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(
                                canBegin ? phaseColor.opacity(0.4) : Color.secondary.opacity(0.1),
                                lineWidth: 1
                            ))
                            .onSubmit { if canBegin { onBegin() } }
                    }

                    // Voice oath section (only if voice enabled)
                    if settings.commitmentVoiceEnabled {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Voice oath")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(.secondary)

                            Text("Record yourself saying the oath. It'll play back if you try to stop early.")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 8) {
                                // Record / Stop button
                                Button {
                                    if commitment.isRecording {
                                        commitment.stopRecording()
                                    } else {
                                        commitment.startRecording()
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: commitment.isRecording ? "stop.circle.fill" : "mic.fill")
                                            .font(.system(size: 11))
                                        Text(commitment.isRecording ? "Stop" : (commitment.hasRecording ? "Re-record" : "Record"))
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundStyle(commitment.isRecording ? Color.red : phaseColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background((commitment.isRecording ? Color.red : phaseColor).opacity(0.1))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                // Play / stop playback button (shown when recording exists)
                                if commitment.hasRecording && !commitment.isRecording {
                                    Button {
                                        if commitment.isPlayingBack {
                                            commitment.stopPlayback()
                                        } else {
                                            commitment.playback()
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: commitment.isPlayingBack ? "stop.fill" : "play.fill")
                                                .font(.system(size: 10))
                                            Text(commitment.isPlayingBack ? "Stop" : "Preview")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.08))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if !commitment.micPermissionGranted {
                                    Text("Mic access required")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.orange)
                                }
                            }

                            // Recording indicator
                            if commitment.isRecording {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                    Text("Recording...")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.red)
                                }
                            } else if commitment.hasRecording {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.green)
                                    Text("Oath recorded")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Action buttons
                    HStack(spacing: 10) {
                        Button("Cancel") { onCancel() }
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.secondary.opacity(0.08))
                            .cornerRadius(7)
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)

                        Button {
                            if canBegin { onBegin() }
                        } label: {
                            Text("Begin Session")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(canBegin ? .white : Color.secondary.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(canBegin ? phaseColor : Color.secondary.opacity(0.1))
                                .cornerRadius(7)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canBegin)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Mid-session break confirmation modal

private struct CommitmentBreakView: View {
    @ObservedObject var timer: TimerManager
    @ObservedObject var commitment: CommitmentManager
    @ObservedObject var settings: AppSettings
    let phaseColor: Color
    let onStayFocused: () -> Void
    let onBreakIt: () -> Void

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)

                Text("Breaking your commitment")
                    .font(.system(size: 13, weight: .semibold))

                // Playback indicator
                if settings.commitmentVoiceEnabled && commitment.hasRecording {
                    HStack(spacing: 6) {
                        if commitment.isPlayingBack {
                            HStack(spacing: 5) {
                                ForEach(0..<3, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(phaseColor)
                                        .frame(width: 3, height: CGFloat(6 + i * 4))
                                }
                            }
                            Text("Playing your oath...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(phaseColor)
                        } else {
                            Image(systemName: "waveform")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("Oath played")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 24)
                } else {
                    Text("You committed to staying focused.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Time remaining
                Text("\(timer.timeString) remaining")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Buttons
                VStack(spacing: 8) {
                    Button {
                        onStayFocused()
                    } label: {
                        Text("Stay Focused")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(phaseColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onBreakIt()
                    } label: {
                        Text("Break Commitment")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 28)
        }
    }
}
