import SwiftUI
import AppKit

// MARK: - Panel manager

class CompletionPanel {
    private var panel: NSPanel?

    func show(timer: TimerManager) {
        dismiss()

        let hosting = NSHostingView(rootView: CompletionView(timer: timer, onDismiss: { [weak self] in
            self?.dismiss()
        }))
        hosting.autoresizingMask = [.width, .height]

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 176),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.center()
        panel.setFrameOrigin(NSPoint(
            x: panel.frame.origin.x,
            y: NSScreen.main.map { $0.frame.height * 0.72 } ?? panel.frame.origin.y
        ))
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func dismiss() {
        panel?.close()
        panel = nil
    }
}

// MARK: - SwiftUI view inside the panel

private struct CompletionView: View {
    @ObservedObject var timer: TimerManager
    let onDismiss: () -> Void

    private let red = Color(red: 0.96, green: 0.36, blue: 0.36)

    var body: some View {
        VStack(spacing: 14) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(red)

                Text("Session complete!")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                if let label = timer.lastCompletedLabel, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Buttons
            HStack(spacing: 10) {
                Button {
                    timer.takeBreak()
                    onDismiss()
                } label: {
                    Text("Take a Break")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundStyle(.secondary)
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)

                Button {
                    timer.keepGoing()
                    onDismiss()
                } label: {
                    Text("Keep Going")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(red)
                        .foregroundStyle(.white)
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }

            Text("Auto-break in \(timer.flowDecisionCountdown)s")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
    }
}
