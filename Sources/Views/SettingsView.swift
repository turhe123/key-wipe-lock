import SwiftUI
import ServiceManagement

/// Preferences: default duration, pointer blocking, end chime and launch at login.
struct SettingsView: View {
    @EnvironmentObject private var lock: LockController
    @AppStorage("defaultDuration") private var defaultDuration = 60
    @AppStorage("blockPointer") private var blockPointer = true
    @AppStorage("playChime") private var playChime = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Picker("Default duration", selection: $defaultDuration) {
                ForEach(AppInfo.presets, id: \.seconds) { Text($0.label).tag($0.seconds) }
            }
            Toggle("Block trackpad & mouse clicks", isOn: $blockPointer)
            Toggle("Play a soft chime when unlocked", isOn: $playChime)
            Toggle("Start at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
            Section {
                HStack {
                    Image(systemName: lock.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(lock.isTrusted ? .green : .orange)
                    Text(lock.isTrusted ? "Accessibility access granted" : "Accessibility access required")
                    Spacer()
                    if !lock.isTrusted { Button("Grant…") { EventBlocker.requestTrust() } }
                }
                Text("Hold Escape for 3 seconds to unlock early. Touch ID and the power button can’t be blocked.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Lock now (\(AppInfo.format(defaultDuration)))") { lock.lock(for: defaultDuration) }
                        .disabled(!lock.isTrusted)
                    Spacer()
                    Button("Support / Donate ❤️") { AppInfo.openDonate() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .onAppear { lock.refreshTrust() }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn’t update login item: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
