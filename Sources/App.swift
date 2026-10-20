import SwiftUI

/// Entry point: a menu-bar-only app with a lock panel, an Accessibility explainer window and Settings.
@main
struct KeyWipeLockApp: App {
    @StateObject private var lock = LockController()

    var body: some Scene {
        MenuBarExtra {
            MenuPanel()
                .environmentObject(lock)
        } label: {
            Image(systemName: lock.isLocked ? "lock.fill" : "keyboard")
        }
        .menuBarExtraStyle(.window)

        Window("Welcome to KeyWipeLock", id: "explainer") {
            ExplainerView()
                .environmentObject(lock)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(lock)
        }
    }
}

/// Shared constants and helpers.
enum AppInfo {
    static let donateURL = URL(string: "https://ko-fi.com/leodavidai")!
    static let presets: [(label: String, seconds: Int)] = [("30 seconds", 30), ("1 minute", 60), ("2 minutes", 120), ("5 minutes", 300)]

    static func openDonate() { NSWorkspace.shared.open(URL(string: "https://ko-fi.com/leodavidai")!) }

    static func format(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
