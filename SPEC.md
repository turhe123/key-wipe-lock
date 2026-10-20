# KeyWipeLock — specification

**Tagline:** Lock your keyboard and trackpad for a countdown so you can wipe them clean without typing nonsense.

**Category:** Text & Input

**Inspired by (paid):** Real Keyboard Cleaner ($5.99 one-time)

**Frameworks:** SwiftUI, AppKit, CoreGraphics, ApplicationServices, ServiceManagement

**Donation URL (Support button):** https://ko-fi.com/leodavidai

## Spec

What the paid app does: Real Keyboard Cleaner sells for 5.99 dollars on the Mac App Store and blocks every key press for a set time so you can wipe the keyboard, and newer versions also block the trackpad and mouse. Similar small apps such as Cats Lock, KeyBlock and KeySweep are also sold, which shows steady demand from people with pets, kids and dusty keyboards. Our clean-room version does the same job for free.

Feature set: A menu bar item starts a lock with a chosen duration of 30 seconds, 1, 2 or 5 minutes. While locked, all keyboard events, including media keys and the power-adjacent function keys that can be intercepted, are swallowed. Optionally the trackpad and mouse clicks are blocked too. A large dimmed overlay window with a countdown ring shows time remaining. An emergency exit is built in: hold the Escape key for three seconds, or just wait for the timer. Settings let the user pick the default duration, whether to block pointing devices, whether to play a soft chime at the end, and whether to start at login.

UI spec: The app is a MenuBarExtra with a keyboard symbol. The menu lists the four durations, a custom duration stepper, a toggle for blocking pointer input, and a Settings item. The overlay is a borderless full screen window on every display at screen saver level, with a dark translucent material, the big countdown, and the hint text saying hold Escape for three seconds to unlock early. Before the first lock the app shows a short explainer sheet asking for Accessibility permission with a button that opens the right System Settings pane. Empty and error states: if permission is missing, the menu shows a single Grant Accessibility Access item and the lock buttons are disabled.

Technical approach: Create a CGEventTap at the session level with the head insert placement, listening to key down, key up, flags changed, system defined events and, optionally, mouse and scroll events. The callback returns nil for everything except an Escape key down and up pair, which it uses to track the three second hold with a timer. The tap is created only after AXIsProcessTrusted returns true, and the app requests it with the prompt option of AXIsProcessTrustedWithOptions. A Timer drives the countdown. The overlay uses one NSWindow per NSScreen hosting a SwiftUI view. Preferences are stored with AppStorage. Launch at login uses SMAppService main app register and unregister.

Edge cases and error handling: If the system disables the event tap because of a timeout or user input, the app listens for the tap disabled events and re-enables the tap immediately, and if it cannot, it ends the lock and shows a notification. If the app quits or crashes, the tap disappears with the process, so the keyboard can never stay locked. Sleep or display changes during a lock rebuild the overlay windows and keep the same end time. Starting a new lock while one is active just extends it. Secure input fields in other apps do not receive events anyway, which is fine. Show a clear message that Touch ID and the power button cannot be blocked. Keep total code near 300 lines.
