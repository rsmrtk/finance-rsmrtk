import SwiftUI

/// Mirrors finance-ui's web background (GradientBackdrop.tsx): a few
/// large, heavily blurred, slowly drifting circles tinted with the
/// accent color over the system background, instead of a flat fill —
/// the same "soft mesh gradient" look, ported from CSS blobs to SwiftUI.
struct MeshGradientBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var drift = false

    private struct Blob {
        let sizeFactor: CGFloat
        let xFactor: CGFloat
        let yFactor: CGFloat
        let duration: Double
    }

    private let blobs: [Blob] = [
        Blob(sizeFactor: 0.95, xFactor: 0.08, yFactor: 0.05, duration: 9),
        Blob(sizeFactor: 0.85, xFactor: 0.9, yFactor: 0.75, duration: 11),
        Blob(sizeFactor: 0.6, xFactor: 0.5, yFactor: 0.35, duration: 8),
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(.systemGroupedBackground)
                ForEach(Array(blobs.enumerated()), id: \.offset) { _, blob in
                    let size = proxy.size.width * blob.sizeFactor
                    Circle()
                        .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.35 : 0.22))
                        .frame(width: size, height: size)
                        .blur(radius: 70)
                        .position(
                            x: proxy.size.width * blob.xFactor + (drift ? 14 : -14),
                            y: proxy.size.height * blob.yFactor + (drift ? -10 : 10)
                        )
                        .animation(.easeInOut(duration: blob.duration).repeatForever(autoreverses: true), value: drift)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { drift = true }
    }
}
