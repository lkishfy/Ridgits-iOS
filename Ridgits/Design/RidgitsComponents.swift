import SwiftUI

struct RidgitsPrimaryButton: View {
    let title: String
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(RidgitsTypography.label(15))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(.white)
            .background(isDisabled ? RidgitsColors.border : RidgitsColors.ctaBlack)
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        }
        .disabled(isDisabled || isLoading)
    }
}

struct RidgitsSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RidgitsTypography.label(15))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(RidgitsColors.textHeadline)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
        }
    }
}

struct RidgitsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }
}

struct RidgitsSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(RidgitsTypography.headline(20))
                .foregroundStyle(RidgitsColors.textHeadline)
            if let subtitle {
                Text(subtitle)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RidgitsCompatibilityBadge: View {
    let percent: Int

    var body: some View {
        Text("\(percent)%")
            .font(RidgitsTypography.label(13))
            .foregroundStyle(RidgitsColors.textHeadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RidgitsColors.contextBar)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(RidgitsColors.border, lineWidth: 1))
    }
}

struct RidgitsLoadingView: View {
    var body: some View {
        ZStack {
            RidgitsColors.surface.ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(RidgitsColors.border, lineWidth: 1)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(RidgitsColors.textHeadline, lineWidth: 2)
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .fill(RidgitsColors.charcoal)
                        .frame(width: 40, height: 40)
                        .overlay(RidgitsLogoView.onDark(size: 24))
                }
                Text("Signing you in to Ridgits…")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }
}

struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("Continue with Google")
                    .font(RidgitsTypography.cta())
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
        }
    }
}
