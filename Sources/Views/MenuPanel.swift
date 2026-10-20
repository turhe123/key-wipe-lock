import SwiftUI

/// The menu bar panel: lock presets, a custom duration stepper, pointer toggle, Settings and Donate.
struct MenuPanel: View {
    @EnvironmentObject private var lock: LockController
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @AppStorage("defaultDuration") private var defaultDuration = 60
    @AppStorage("customDuration") private var customDuration = 90
    @AppStorage("blockPointer") private var blockPointer = true
    @AppStorage("hasSeenExplainer") private var hasSeenExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KeyWipeLock").font(.headline)
            if !lock.isTrusted {
                Button { showExplainer() } label: {
                    Label("Grant Accessibility Access", systemImage: "hand.raised.fill").frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            } else if lock.isLocked {
                Text("Locked — \(AppInfo.format(lock.remaining)) left").foregroundStyle(.secondary)
            }

            Group {
                Text(lock.isLocked ? "Extend lock by" : "Lock keyboard for").font(.subheadline).foregroundStyle(.secondary)
                ForEach(AppInfo.presets, id: \.seconds) { preset in
                    Button { start(preset.seconds) } label: {
                        HStack {
                            Text(preset.label)
                            Spacer()
                            if preset.seconds == defaultDuration { Image(systemName: "star.fill").font(.caption) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                HStack {
                    Stepper("Custom: \(AppInfo.format(customDuration))", value: $customDuration, in: 10...1800, step: 10)
                    Button("Lock") { start(customDuration) }
                }
                Toggle("Block trackpad & mouse clicks", isOn: $blockPointer)
            }
            .disabled(!lock.isTrusted)

            if let error = lock.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            Text("Touch ID and the power button can’t be blocked.").font(.caption2).foregroundStyle(.secondary)
            Divider()
            HStack {
                Button("Settings…") { NSApp.activate(ignoringOtherApps: true); openSettings() }
                Spacer()
                Button("Support / Donate ❤️") { AppInfo.openDonate() }
            }
            HStack {
                Button("About") { NSApp.activate(ignoringOtherApps: true); NSApp.orderFrontStandardAboutPanel(nil) }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 290)
        .onAppear { lock.refreshTrust() }
    }

    private func start(_ seconds: Int) {
        guard hasSeenExplainer else { showExplainer(); return }
        lock.lock(for: seconds)
    }

    private func showExplainer() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "explainer")
    }
}
