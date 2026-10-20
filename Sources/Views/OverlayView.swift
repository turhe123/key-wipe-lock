import SwiftUI

/// Full-screen dimmed overlay shown on every display while locked, with a countdown ring.
struct OverlayView: View {
    @EnvironmentObject private var lock: LockController

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Color.black.opacity(0.55)
            VStack(spacing: 28) {
                ZStack {
                    Circle().stroke(.white.opacity(0.15), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: CGFloat(lock.remaining) / CGFloat(max(lock.total, 1)))
                        .stroke(.cyan, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: lock.remaining)
                    VStack(spacing: 6) {
                        Text(AppInfo.format(lock.remaining))
                            .font(.system(size: 84, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Text("Keyboard locked — wipe away").font(.title3).foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(width: 320, height: 320)
                VStack(spacing: 10) {
                    Text("Hold Escape for 3 seconds to unlock early").font(.title2)
                    ProgressView(value: lock.escapeProgress)
                        .tint(.orange)
                        .frame(width: 260)
                        .opacity(lock.escapeProgress > 0 ? 1 : 0)
                    Text("Touch ID and the power button cannot be blocked.")
                        .font(.callout).foregroundStyle(.white.opacity(0.55))
                }
            }
            .foregroundStyle(.white)
        }
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea()
    }
}
