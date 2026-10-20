import AppKit
import SwiftUI
import UserNotifications

/// Drives a lock session: the countdown, the event tap, the per-screen overlays and the Escape-hold exit.
final class LockController: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var remaining = 0
    @Published private(set) var total = 1
    @Published private(set) var escapeProgress: Double = 0
    @Published private(set) var isTrusted = EventBlocker.isTrusted
    @Published var errorMessage: String?

    @AppStorage("blockPointer") var blockPointer = true
    @AppStorage("playChime") var playChime = true

    static let escapeHold: TimeInterval = 3

    private let blocker = EventBlocker()
    private var endDate = Date()
    private var tick: Timer?
    private var escapeStart: Date?
    private var permissionPoll: Timer?
    private var windows: [NSWindow] = []
    private var observers: [NSObjectProtocol] = []

    init() {
        blocker.onEscape = { [weak self] down in self?.escapeChanged(down) }
        blocker.onTapLost = { [weak self] in self?.tapLost() }
        permissionPoll = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshTrust()
        }
        let center = NotificationCenter.default, ws = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                            object: nil, queue: .main) { [weak self] _ in self?.rebuildOverlays() })
        observers.append(ws.addObserver(forName: NSWorkspace.didWakeNotification,
                                        object: nil, queue: .main) { [weak self] _ in self?.rebuildOverlays() })
    }

    func refreshTrust() {
        let trusted = EventBlocker.isTrusted
        if trusted != isTrusted { isTrusted = trusted }
    }

    /// Starts a lock, or extends the running one by `seconds`.
    func lock(for seconds: Int) {
        guard seconds > 0 else { return }
        refreshTrust()
        guard isTrusted else { EventBlocker.requestTrust(); return }
        if isLocked {
            endDate = max(endDate, Date()).addingTimeInterval(TimeInterval(seconds))
            total += seconds
            update()
            return
        }
        guard blocker.start(blockPointer: blockPointer) else {
            errorMessage = "Could not install the input blocker. Check Accessibility access and try again."
            return
        }
        errorMessage = nil
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        total = seconds
        isLocked = true
        update()
        rebuildOverlays()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.update() }
        RunLoop.main.add(timer, forMode: .common)
        tick = timer
    }

    func unlock(chime: Bool = true) {
        guard isLocked else { return }
        blocker.stop()
        tick?.invalidate()
        tick = nil
        escapeStart = nil
        escapeProgress = 0
        isLocked = false
        remaining = 0
        closeOverlays()
        if chime && playChime { NSSound(named: "Glass")?.play() }
    }

    private func update() {
        let left = endDate.timeIntervalSinceNow
        remaining = max(0, Int(left.rounded(.up)))
        if let escapeStart {
            escapeProgress = min(1, Date().timeIntervalSince(escapeStart) / Self.escapeHold)
            if escapeProgress >= 1 { unlock(); return }
        }
        if left <= 0 { unlock() }
    }

    private func escapeChanged(_ down: Bool) {
        if down { if escapeStart == nil { escapeStart = Date() } } else { escapeStart = nil; escapeProgress = 0 }
    }

    private func tapLost() {
        unlock(chime: false)
        let content = UNMutableNotificationContent()
        content.title = "KeyWipeLock unlocked early"
        content.body = "macOS disabled the input blocker, so your keyboard was released."
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    // MARK: Overlays

    private func rebuildOverlays() {
        closeOverlays()
        guard isLocked else { return }
        for screen in NSScreen.screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = !blockPointer
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.contentView = NSHostingView(rootView: OverlayView().environmentObject(self))
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    private func closeOverlays() {
        windows.forEach { $0.orderOut(nil); $0.close() }
        windows.removeAll()
    }
}
