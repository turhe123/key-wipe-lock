import SwiftUI

/// First-run explainer asking for Accessibility permission, which the event tap requires.
struct ExplainerView: View {
    @EnvironmentObject private var lock: LockController
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenExplainer") private var hasSeenExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Before your first clean", systemImage: "keyboard.badge.ellipsis").font(.title2.bold())
            Text("KeyWipeLock swallows every key press (and optionally clicks and scrolling) for a short countdown so you can wipe your keyboard and trackpad without typing nonsense.")
            Text("To intercept input, macOS requires **Accessibility** access. Nothing is recorded or sent anywhere — the app is fully offline.")
            VStack(alignment: .leading, spacing: 6) {
                Label("Emergency exit: hold Escape for 3 seconds.", systemImage: "escape")
                Label("Quitting the app always releases the keyboard.", systemImage: "power")
                Label("Touch ID and the power button can’t be blocked.", systemImage: "touchid")
            }
            .foregroundStyle(.secondary)
            HStack {
                Image(systemName: lock.isTrusted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(lock.isTrusted ? .green : .orange)
                Text(lock.isTrusted ? "Accessibility access granted" : "Accessibility access not granted yet")
            }
            HStack {
                Button("Open Accessibility Settings") { openAccessibilityPane() }
                    .disabled(lock.isTrusted)
                Spacer()
                Button("Done") { hasSeenExplainer = true; dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear { lock.refreshTrust() }
    }

    private func openAccessibilityPane() {
        EventBlocker.requestTrust()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
