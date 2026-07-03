import SwiftUI
import AuthenticationServices

private enum RidgitsLegalURL {
    static let privacy = URL(string: "https://ridgits.com/privacy-policy")!
    static let terms = URL(string: "https://ridgits.com/terms-conditions")!
}

struct LoginView: View {
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, Error>) -> Void
    let onGoogleSignIn: () -> Void
    let onEmailSignIn: () -> Void

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
                        .padding(.bottom, 32)

                    authSection
                        .padding(.horizontal, 40)
                        .padding(.bottom, 32)
                }
            }
            .background(RidgitsColors.surface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RidgitsColors.surface.ignoresSafeArea())
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
        VStack(alignment: .leading, spacing: 20) {
            RidgitsHeroImageStack()
                .padding(.bottom, 8)

            Text("Stop Wasting Time")
                .font(RidgitsTypography.heroTitle(36))
                .foregroundStyle(RidgitsColors.textHeadline)
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var authSection: some View {
        VStack(spacing: 16) {
            Text("Community quiz-based matching and dating tools.")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 320)
                .padding(.bottom, 8)

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

    @State private var segmentWidth: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let progress = elapsed.truncatingRemainder(dividingBy: scrollDuration) / scrollDuration
            let shift = segmentWidth > 0 ? -segmentWidth * CGFloat(progress) : 0

            HStack(spacing: 0) {
                marqueeSegment
                marqueeSegment
            }
            .offset(x: shift)
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .background(RidgitsColors.surface)
        .onPreferenceChange(MarqueeSegmentWidthKey.self) { width in
            if width > 0 {
                segmentWidth = width
            }
        }
    }

    private var marqueeSegment: some View {
        HStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(RidgitsTypography.banner())
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .tracking(1.4)
                Text("•")
                    .font(RidgitsTypography.banner())
                    .foregroundStyle(RidgitsColors.border)
            }
        }
        .fixedSize()
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: MarqueeSegmentWidthKey.self, value: proxy.size.width)
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
