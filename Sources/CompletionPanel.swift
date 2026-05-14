import SwiftUI
import AppKit

class CompletionPanel {
    private var panel: NSPanel?

    func show(label: String?) {
        dismiss()
        let hosting = NSHostingView(rootView: CompletionToast(label: label, onDismiss: { [weak self] in
            self?.dismiss()
        }))
        hosting.autoresizingMask = [.width, .height]
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 64),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        p.contentView = hosting
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.level = .floating
        p.isReleasedWhenClosed = false
        p.isMovableByWindowBackground = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.center()
        if let screen = NSScreen.main {
            p.setFrameOrigin(NSPoint(x: p.frame.origin.x, y: screen.frame.height * 0.82))
        }
        p.makeKeyAndOrderFront(nil)
        panel = p
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.dismiss() }
    }

    func dismiss() {
        panel?.close()
        panel = nil
    }
}

private struct CompletionToast: View {
    let label: String?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.25, green: 0.72, blue: 0.53))
            VStack(alignment: .leading, spacing: 1) {
                Text("Session complete")
                    .font(.system(size: 13, weight: .semibold))
                if let label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 6)
        .onTapGesture { onDismiss() }
    }
}
