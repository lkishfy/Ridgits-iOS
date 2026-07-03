import SwiftUI
import AuthenticationServices

struct LoginView: View {
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, Error>) -> Void
    let onGoogleSignIn: () -> Void

    @State private var bannerOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            RidgitsColors.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 112)

                    heroSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    authSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)

                    featuresPreview
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }

            VStack(spacing: 0) {
                landingNavBar
                marqueeBanner
            }
        }
    }

    private var landingNavBar: some View {
        HStack {
            RidgitsLogoView.onLight(size: 28)

            Spacer()

            Text("LOG IN")
                .font(RidgitsTypography.navLabel())
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(1.2)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(RidgitsColors.border.opacity(0.5)),
            alignment: .bottom
        )
    }

    private var marqueeBanner: some View {
        RidgitsMarqueeBanner()
            .frame(height: 36)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            RidgitsHeroStack()

            Text("Stop Wasting Time")
                .font(RidgitsTypography.heroTitle())
                .foregroundStyle(RidgitsColors.textHeadline)
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text("Discover your relationship patterns, vet smarter, and get meetup plans that actually work for how you connect.")
                .font(RidgitsTypography.body(17))
                .foregroundStyle(RidgitsColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var authSection: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signIn, onRequest: onAppleRequest, onCompletion: onAppleCompletion)
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))

            GoogleSignInButton(action: onGoogleSignIn)

            Text("By continuing you agree to our Privacy Policy and Terms and Conditions.")
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    private var featuresPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make more meaningful connections")
                .font(RidgitsTypography.headline(22))
                .foregroundStyle(RidgitsColors.textHeadline)

            Text("Tools that make it easier to show up authentically—and find people who match that.")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)

            VStack(spacing: 10) {
                RidgitsFeatureRow(title: "Deep compatibility matching", icon: "heart.text.square")
                RidgitsFeatureRow(title: "Five dimensions of fit", icon: "chart.radar")
                RidgitsFeatureRow(title: "24-hour real conversations", icon: "clock")
            }
        }
        .padding(20)
        .background(RidgitsColors.feedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }
}

private struct RidgitsMarqueeBanner: View {
    private let items = [
        "INDEPENDENT & COMMUNITY-FUNDED",
        "MEMBERS SET THE DIRECTION",
        "OPEN-SOURCE APPROACH",
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let shift = CGFloat(elapsed.truncatingRemainder(dividingBy: 24)) * -40

            HStack(spacing: 12) {
                marqueeContent
                marqueeContent
            }
            .offset(x: shift)
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .background(RidgitsColors.feedBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(RidgitsColors.border.opacity(0.6)),
            alignment: .bottom
        )
    }

    private var marqueeContent: some View {
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
    }
}

private struct RidgitsHeroStack: View {
    var body: some View {
        ZStack {
            heroCard(color: RidgitsColors.border, offset: CGSize(width: 72, height: 54), rotation: -10, opacity: 0.55)
            heroCard(color: RidgitsColors.hoverSurface, offset: CGSize(width: 48, height: 36), rotation: -6, opacity: 0.75)
            heroCard(color: RidgitsColors.contextBar, offset: CGSize(width: 24, height: 18), rotation: -3, opacity: 0.9)
            heroCard(color: RidgitsColors.surface, offset: .zero, rotation: 0, opacity: 1)
                .overlay(
                    Circle()
                        .fill(RidgitsColors.charcoal)
                        .frame(width: 56, height: 56)
                        .overlay(RidgitsLogoView.onDark(size: 32))
                )
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .padding(.trailing, 40)
    }

    private func heroCard(
        color: Color,
        offset: CGSize,
        rotation: Double,
        opacity: Double
    ) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(color)
            .frame(width: 180, height: 180)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 12)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .offset(offset)
            .opacity(opacity)
    }
}

private struct RidgitsFeatureRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                .fill(RidgitsColors.ctaBlack)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                )
            Text(title)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textHeadline)
            Spacer()
        }
        .padding(12)
        .background(RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
    }
}
