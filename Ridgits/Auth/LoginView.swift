import SwiftUI
import AuthenticationServices
import FirebaseFirestore

private enum RidgitsLegalURL {
    static let privacy = URL(string: "https://ridgits.com/privacy-policy")!
    static let terms = URL(string: "https://ridgits.com/terms-conditions")!
}

@MainActor
private final class LoginMonthlyQuizStatsViewModel: ObservableObject {
    @Published private(set) var stats = CommunityQuizStats()

    private var listener: ListenerRegistration?

    var displayedCount: Int {
        stats.displayedCompletedThisMonth
    }

    var showsBadge: Bool {
        true
    }

    var badgeText: String {
        stats.monthlyActivityLabel
    }

    func startListening() {
        guard listener == nil else { return }
        listener = RidgitsFirebaseClient.shared.listenCommunityQuizStats { [weak self] stats in
            Task { @MainActor in
                self?.stats = stats
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

struct LoginView: View {
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, Error>) -> Void
    let onGoogleSignIn: () -> Void
    let onEmailSignIn: () -> Void

    @StateObject private var monthlyStats = LoginMonthlyQuizStatsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                landingNavBar
                marqueeBanner
            }
            .background {
                RidgitsColors.surface
                    .ignoresSafeArea(edges: .top)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.horizontal, 32)
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    authSection
                        .padding(.horizontal, 40)
                        .padding(.top, 60)
                        .padding(.bottom, 32)
                }
            }
            .background(RidgitsColors.surface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RidgitsColors.surface.ignoresSafeArea())
        .onAppear { monthlyStats.startListening() }
        .onDisappear { monthlyStats.stopListening() }
    }

    private var landingNavBar: some View {
        RidgitsLogoView.onLight(size: 32)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
    }

    private var marqueeBanner: some View {
        RidgitsMarqueeBanner()
            .frame(height: 36)
    }

    private var heroSection: some View {
        VStack(alignment: .center, spacing: 4) {
            RidgitsHeroImageStack()

            VStack(spacing: 8) {
                if monthlyStats.showsBadge {
                    LoginMonthlyQuizBadge(text: monthlyStats.badgeText, count: monthlyStats.displayedCount)
                        .padding(.bottom, 4)
                }

                Text("Stop Wasting Time")
                    .font(RidgitsTypography.heroTitle(36))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Community quiz-based matching and dating tools")
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var authSection: some View {
        VStack(spacing: 16) {
            SignInWithAppleButton(.signIn, onRequest: onAppleRequest, onCompletion: onAppleCompletion)
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            GoogleSignInButton(action: onGoogleSignIn)

            Button(action: onEmailSignIn) {
                Text("Sign in with email")
                    .font(RidgitsTypography.caption(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .underline()
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
            .padding(.top, 4)

            RidgitsLegalConsentView()
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
    }
}

private struct LoginMonthlyQuizBadge: View {
    let text: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            RidgitsLivePulseDot()

            Text(text)
                .font(RidgitsTypography.label(11))
                .foregroundStyle(Color(hex: 0x065F46))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: 0xD1FAE5))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.25), value: count)
        .accessibilityLabel(text)
    }
}

private struct RidgitsLivePulseDot: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x059669))
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 2.2 : 1)
                .opacity(isPulsing ? 0 : 0.75)

            Circle()
                .fill(Color(hex: 0x059669))
                .frame(width: 8, height: 8)
        }
        .frame(width: 8, height: 8)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

private struct RidgitsLegalConsentView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to our")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textMuted)

            HStack(spacing: 4) {
                Link("Privacy Policy", destination: RidgitsLegalURL.privacy)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .underline()

                Text("and")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)

                Link("Terms and Conditions", destination: RidgitsLegalURL.terms)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .underline()
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, 4)
    }
}

private struct RidgitsMarqueeBanner: View {
    private let items = [
        "INDEPENDENT & COMMUNITY-FUNDED",
        "MEMBERS SET THE DIRECTION",
        "OPEN-SOURCE APPROACH",
    ]

    private let scrollDuration: TimeInterval = 40
    private let leadingPadding: CGFloat = 12

    @State private var segmentWidth: CGFloat = 0

    var body: some View {
        GeometryReader { container in
            let containerWidth = container.size.width
            let copies = segmentCopies(for: containerWidth)

            TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let progress = elapsed.truncatingRemainder(dividingBy: scrollDuration) / scrollDuration
                let shift = segmentWidth > 0 ? -segmentWidth * CGFloat(progress) : 0

                HStack(spacing: 0) {
                    ForEach(0..<copies, id: \.self) { index in
                        marqueeSegment(measure: index == 0)
                    }
                }
                .offset(x: shift)
            }
            .frame(width: containerWidth, height: container.size.height, alignment: .leading)
            .clipped()
        }
        .frame(height: 36)
        .background(RidgitsColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RidgitsColors.border)
                .frame(height: 1)
        }
        .onPreferenceChange(MarqueeSegmentWidthKey.self) { width in
            if width > 0 {
                segmentWidth = width
            }
        }
    }

    private func segmentCopies(for containerWidth: CGFloat) -> Int {
        guard segmentWidth > 0, containerWidth > 0 else { return 3 }
        return max(3, Int(ceil((containerWidth * 2) / segmentWidth)) + 1)
    }

    private func marqueeSegment(measure: Bool) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .font(RidgitsTypography.banner())
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .tracking(1.4)
                    .padding(.leading, index == 0 ? leadingPadding : 0)
                Text("•")
                    .font(RidgitsTypography.banner())
                    .foregroundStyle(RidgitsColors.border)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .background {
            if measure {
                GeometryReader { proxy in
                    Color.clear.preference(key: MarqueeSegmentWidthKey.self, value: proxy.size.width)
                }
            }
        }
    }
}

private struct MarqueeSegmentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
