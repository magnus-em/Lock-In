import Foundation
import Combine
import UserNotifications
import AppKit

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var totalTime: TimeInterval
    @Published var isRunning = false
    @Published var currentPhase: Phase = .work
    @Published var workSessionsCompleted: Int = 0
    @Published var isBlockingActive = false

    // Label for the current / upcoming session
    @Published var currentLabel: String = ""
    // Label of the session that just finished (shown in the completion panel)
    @Published var lastCompletedLabel: String? = nil

    // Flow-decision state
    @Published var isAwaitingFlowDecision = false
    @Published var flowDecisionCountdown = 10

    // Commitment — set when session was started via the commitment modal
    @Published var isCommitted = false

    enum Phase: String {
        case work = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"
    }

    private var timer: AnyCancellable?
    private var flowCountdownSubscription: AnyCancellable?
    private var sessionStartTime: Date?
    private var elapsedBeforePause: TimeInterval = 0
    private var lastResumeTime: Date?
    private var settingsSubscriptions = Set<AnyCancellable>()
    private let completionPanel = CompletionPanel()

    var sessionStore: SessionStore?
    var settings: AppSettings? {
        didSet { observeSettingsChanges() }
    }

    // MARK: - Computed durations

    private var workDuration: TimeInterval { (settings?.workMinutes ?? 25) * 60 }
    private var shortBreakDuration: TimeInterval { (settings?.shortBreakMinutes ?? 5) * 60 }
    private var longBreakDuration: TimeInterval { (settings?.longBreakMinutes ?? 15) * 60 }
    private var sessionsBeforeLongBreak: Int { settings?.sessionsBeforeLongBreak ?? 4 }

    init() {
        self.totalTime = 25 * 60
        self.timeRemaining = 25 * 60
        requestNotificationPermission()
    }

    func applySettings() {
        guard !isRunning && elapsedBeforePause == 0 else { return }
        setTimeForCurrentPhase()
    }

    // MARK: - Display

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalTime)
    }

    var timeString: String {
        let total = Int(timeRemaining)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var isActive: Bool { isRunning || timeRemaining < totalTime }

    var menuBarTimeText: String {
        isRunning ? timeString : "⏸ \(timeString)"
    }

    var currentCyclePosition: Int {
        (workSessionsCompleted % sessionsBeforeLongBreak) + 1
    }

    // MARK: - Controls

    func start() {
        if sessionStartTime == nil { sessionStartTime = Date() }
        lastResumeTime = Date()
        isRunning = true
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
        updateBlocking()
    }

    /// Start a session that was confirmed via the commitment modal.
    func startCommitted() {
        isCommitted = true
        start()
    }

    func pause() {
        if let resumeTime = lastResumeTime {
            elapsedBeforePause += Date().timeIntervalSince(resumeTime)
        }
        lastResumeTime = nil
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func reset() {
        if isAwaitingFlowDecision {
            cancelFlowDecision()
            setTimeForCurrentPhase()
            unblockIfNeeded()
            return
        }

        var elapsed = elapsedBeforePause
        if let resumeTime = lastResumeTime { elapsed += Date().timeIntervalSince(resumeTime) }

        timer?.cancel()
        timer = nil
        isRunning = false

        if elapsed >= 60, currentPhase == .work, let start = sessionStartTime {
            sessionStore?.addSession(WorkSession(
                startTime: start,
                durationMinutes: elapsed / 60.0,
                type: .work,
                label: currentLabel.isEmpty ? nil : currentLabel
            ))
        }

        currentLabel = ""
        isCommitted = false
        elapsedBeforePause = 0
        lastResumeTime = nil
        sessionStartTime = nil
        setTimeForCurrentPhase()
        unblockIfNeeded()
    }

    func skip() {
        if isAwaitingFlowDecision {
            takeBreak()
            return
        }
        timer?.cancel()
        timer = nil
        isRunning = false
        elapsedBeforePause = 0
        lastResumeTime = nil
        sessionStartTime = nil
        advancePhase()
        updateBlocking()
    }

    func adjustDuration(by minutes: Double) {
        let newRemaining = timeRemaining + minutes * 60
        guard newRemaining > 5 else { completePhase(); return }
        totalTime = max(60, totalTime + minutes * 60)
        timeRemaining = newRemaining
    }

    func setSessionDuration(_ minutes: Double) {
        guard !isActive else { return }
        totalTime = minutes * 60
        timeRemaining = minutes * 60
    }

    // MARK: - Flow decision

    func keepGoing() {
        cancelFlowDecision()
        workSessionsCompleted += 1
        currentLabel = ""
        isCommitted = false
        setTimeForCurrentPhase()
        start()
    }

    func takeBreak() {
        cancelFlowDecision()
        currentLabel = ""
        advancePhase()
        updateBlocking()
        handleAutoStart()
    }

    private func cancelFlowDecision() {
        isAwaitingFlowDecision = false
        flowCountdownSubscription?.cancel()
        flowCountdownSubscription = nil
        completionPanel.dismiss()
    }

    private func startFlowCountdown() {
        flowDecisionCountdown = 10
        flowCountdownSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.flowDecisionCountdown -= 1
                if self.flowDecisionCountdown <= 0 { self.takeBreak() }
            }
    }

    // MARK: - Private timer logic

    private func tick() {
        guard let resumeTime = lastResumeTime else { return }
        let elapsed = elapsedBeforePause + Date().timeIntervalSince(resumeTime)
        timeRemaining = max(0, totalTime - elapsed)
        if timeRemaining <= 0 { completePhase() }
    }

    private func completePhase() {
        timer?.cancel()
        timer = nil
        isRunning = false

        if let start = sessionStartTime {
            let sessionType: WorkSession.SessionType = switch currentPhase {
            case .work: .work
            case .shortBreak: .shortBreak
            case .longBreak: .longBreak
            }
            sessionStore?.addSession(WorkSession(
                startTime: start,
                durationMinutes: totalTime / 60.0,
                type: sessionType,
                label: currentLabel.isEmpty ? nil : currentLabel
            ))
        }

        elapsedBeforePause = 0
        lastResumeTime = nil
        sessionStartTime = nil

        sendNotification()
        if settings?.soundEnabled ?? true { NSSound(named: "Glass")?.play() }

        if currentPhase == .work {
            lastCompletedLabel = currentLabel.isEmpty ? nil : currentLabel
            isCommitted = false
            isAwaitingFlowDecision = true
            startFlowCountdown()
            completionPanel.show(timer: self)
        } else {
            advancePhase()
            updateBlocking()
            handleAutoStart()
        }
    }

    private func advancePhase() {
        switch currentPhase {
        case .work:
            workSessionsCompleted += 1
            currentPhase = workSessionsCompleted % sessionsBeforeLongBreak == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            currentPhase = .work
        }
        setTimeForCurrentPhase()
    }

    private func setTimeForCurrentPhase() {
        switch currentPhase {
        case .work:      totalTime = workDuration
        case .shortBreak: totalTime = shortBreakDuration
        case .longBreak:  totalTime = longBreakDuration
        }
        timeRemaining = totalTime
    }

    private func handleAutoStart() {
        guard let settings else { return }
        let should: Bool = switch currentPhase {
        case .work: settings.autoStartWork
        case .shortBreak, .longBreak: settings.autoStartBreaks
        }
        if should {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.start() }
        }
    }

    private func unblockIfNeeded() {
        guard isBlockingActive else { return }
        isBlockingActive = false
        DispatchQueue.global(qos: .userInitiated).async { SiteBlocker.unblockAll() }
    }

    // MARK: - Site blocking

    private func observeSettingsChanges() {
        settingsSubscriptions.removeAll()
        guard let settings else { return }

        settings.$blockedSites
            .dropFirst().removeDuplicates()
            .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reapplyBlockingIfNeeded() }
            .store(in: &settingsSubscriptions)

        settings.$siteBlockingEnabled
            .dropFirst().removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reapplyBlockingIfNeeded() }
            .store(in: &settingsSubscriptions)

        settings.$blockDuringBreaks
            .dropFirst().removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reapplyBlockingIfNeeded() }
            .store(in: &settingsSubscriptions)
    }

    private func reapplyBlockingIfNeeded() {
        guard isActive else { return }
        if isBlockingActive { isBlockingActive = false }
        updateBlocking()
    }

    func updateBlocking() {
        guard let settings, settings.siteBlockingEnabled, !settings.blockedSites.isEmpty else {
            unblockIfNeeded()
            return
        }
        let shouldBlock: Bool = switch currentPhase {
        case .work: isActive
        case .shortBreak, .longBreak: settings.blockDuringBreaks && isActive
        }
        if shouldBlock && !isBlockingActive {
            isBlockingActive = true
            let domains = settings.blockedSites
            DispatchQueue.global(qos: .userInitiated).async { SiteBlocker.block(domains: domains) }
        } else if !shouldBlock && isBlockingActive {
            unblockIfNeeded()
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus"
        content.body = switch currentPhase {
        case .work: "Great session! Keep going or take a break?"
        case .shortBreak, .longBreak: "Break's over — ready to focus?"
        }
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}
