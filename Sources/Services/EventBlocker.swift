import CoreGraphics
import ApplicationServices

/// Owns the session-level CGEventTap that swallows keyboard (and optionally pointer) input.
/// Only Escape is observed (never delivered) so a 3-second hold can end the lock early.
final class EventBlocker {
    /// Called on the main run loop with `true` on Escape down and `false` on Escape up.
    var onEscape: ((Bool) -> Void)?
    /// Called when the system disabled the tap and re-enabling failed.
    var onTapLost: (() -> Void)?

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    private static let systemDefined = CGEventType(rawValue: 14)!   // NX_SYSDEFINED: media & special keys
    private static let gesture = CGEventType(rawValue: 29)!         // NSEventTypeGesture

    private static let escapeKeyCode: Int64 = 53                   // kVK_Escape

    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system Accessibility prompt if the app is not trusted yet.
    @discardableResult
    static func requestTrust() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    var isRunning: Bool { tap != nil }

    /// Installs the tap. Returns false when permission is missing or the tap cannot be created.
    func start(blockPointer: Bool) -> Bool {
        guard Self.isTrusted else { return false }
        stop()
        var types: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, Self.systemDefined]
        if blockPointer {
            types += [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown,
                      .otherMouseUp, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
                      .scrollWheel, Self.gesture]
        }
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << CGEventMask($1.rawValue)) }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                           options: .defaultTap, eventsOfInterest: mask,
                                           callback: eventTapCallback, userInfo: refcon) else { return false }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        tap = port
        source = src
        return true
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
                if !CGEvent.tapIsEnabled(tap: tap) { DispatchQueue.main.async { self.onTapLost?() } }
            }
            return Unmanaged.passUnretained(event)
        case .keyDown, .keyUp:
            if event.getIntegerValueField(.keyboardEventKeycode) == Self.escapeKeyCode,
               event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                onEscape?(type == .keyDown)
            }
            return nil
        default:
            return nil
        }
    }
}

private func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                              refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    return Unmanaged<EventBlocker>.fromOpaque(refcon).takeUnretainedValue().handle(type: type, event: event)
}
