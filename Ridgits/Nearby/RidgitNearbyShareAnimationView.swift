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
    var profileName: String? = nil
    var profileImageURL: String? = nil

    @State private var pulse = false
    @State private var glow = false
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                if mode != .success {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .stroke(Color.white.opacity(0.12 - Double(index) * 0.04), lineWidth: 1.5)
                            .frame(width: ringSize(for: index), height: ringSize(for: index))
                            .scaleEffect(pulse ? 1.05 + Double(index) * 0.03 : 0.94)
                            .opacity(pulse ? 0.08 : 0.22)
                            .animation(
                                .easeInOut(duration: 1.8 + Double(index) * 0.25)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: pulse
                            )
                    }
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
                    .shadow(color: Color.white.opacity(glow ? 0.22 : 0.08), radius: glow ? 24 : 10, y: 8)
                    .scaleEffect(mode == .success ? 1.04 : 1)
                    .overlay(cardContent)

                if mode == .connecting {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(x: pulse ? -78 : -62)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .scaleEffect(x: -1, y: 1)
                        .offset(x: pulse ? 78 : 62)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                }
            }
            .frame(height: 260)

            VStack(spacing: 8) {
                Text(title)
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x64D2FF),
                                Color(hex: 0xBF5AF2),
                                Color(hex: 0xFF6482),
                            ],
                            startPoint: shimmer ? .leading : .trailing,
                            endPoint: shimmer ? .trailing : .leading
                        )
                    )
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
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 10) {
            if let profileImageURL, !profileImageURL.isEmpty {
                RidgitsCachedProfileImage(remoteURL: profileImageURL) {
                    Circle()
                        .fill(Color(hex: 0xF0F0F2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(RidgitsColors.textMuted)
                        )
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
            } else {
                RidgitsLogoView.onLight(size: 34)
            }

            Text(cardLabel)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textHeadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 10)

            if mode == .success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: 0x16A34A))
            } else {
                RidgitsLogoView.onLight(size: 20)
            }
        }
    }

    private var cardLabel: String {
        if mode == .success { return "Sent" }
        if let profileName {
            let firstName = RidgitsDisplaySanitize.displayFirstName(profileName)
            if !firstName.isEmpty {
                let possessive = firstName.lowercased().hasSuffix("s") ? "’" : "’s"
                return "\(firstName)\(possessive) Ridgit"
            }
        }
        return "Ridgit"
    }

    private func ringSize(for index: Int) -> CGFloat {
        160 + CGFloat(index) * 44
    }
}
