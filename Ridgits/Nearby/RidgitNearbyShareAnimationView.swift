import SwiftUI

/// Contact Poster-style pulsing rings for nearby Ridgit handoff.
struct RidgitNearbyShareAnimationView: View {
    enum Mode {
        case searching
        case connecting
        case success
    }

    let mode: Mode
    let title: String
    let subtitle: String

    @State private var pulse = false
    @State private var glow = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(ringColor.opacity(0.35 - Double(index) * 0.08), lineWidth: 2)
                        .frame(width: ringSize(for: index), height: ringSize(for: index))
                        .scaleEffect(pulse ? 1.08 + Double(index) * 0.04 : 0.92)
                        .opacity(pulse ? 0.15 : 0.55)
                        .animation(
                            .easeInOut(duration: 1.6 + Double(index) * 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: pulse
                        )
                }

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(hex: 0xF4F4F5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 132, height: 168)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(glow ? 0.18 : 0.08), radius: glow ? 28 : 12, y: 10)
                    .scaleEffect(mode == .success ? 1.04 : 1)
                    .overlay(cardContent)

                if mode == .connecting {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(RidgitsColors.textHeadline.opacity(0.85))
                        .offset(x: pulse ? -78 : -62)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(RidgitsColors.textHeadline.opacity(0.85))
                        .scaleEffect(x: -1, y: 1)
                        .offset(x: pulse ? 78 : 62)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                }
            }
            .frame(height: 260)

            VStack(spacing: 8) {
                Text(title)
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(RidgitsTypography.body(15))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .onAppear {
            pulse = true
            glow = true
        }
    }

    private var ringColor: Color {
        switch mode {
        case .searching: return Color(hex: 0x60A5FA)
        case .connecting: return Color(hex: 0x34D399)
        case .success: return Color(hex: 0xA3E635)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 10) {
            RidgitsLogoView.onLight(size: 34)
            Text(mode == .success ? "Sent" : "Ridgit")
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textHeadline)
            if mode == .success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: 0x16A34A))
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }

    private func ringSize(for index: Int) -> CGFloat {
        160 + CGFloat(index) * 44
    }
}
