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
            .foregroundStyle(isDisabled ? RidgitsColors.textSecondary : .white)
            .background(isDisabled ? RidgitsColors.hoverSurface : RidgitsColors.ctaBlack)
            .overlay {
                if isDisabled {
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        }
        .disabled(isDisabled || isLoading)
    }
}

struct RidgitsSquareButton: View {
    enum Style {
        case filled
        case outlined
        case ghost
        case destructive
    }

    let title: String
    var style: Style = .filled
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RidgitsTypography.label(12))
                .tracking(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(foreground)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(border, lineWidth: style == .filled ? 0 : (style == .outlined ? 2 : 1))
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .filled: return .white
        case .outlined: return RidgitsColors.textHeadline
        case .ghost: return RidgitsColors.textSecondary
        case .destructive: return .white
        }
    }

    private var background: Color {
        switch style {
        case .filled: return RidgitsColors.ctaBlack
        case .outlined, .ghost: return RidgitsColors.surface
        case .destructive: return RidgitsColors.destructive
        }
    }

    private var border: Color {
        switch style {
        case .filled: return .clear
        case .outlined: return RidgitsColors.ctaBlack
        case .ghost: return RidgitsColors.dashboardBorder
        case .destructive: return RidgitsColors.destructive
        }
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
                    .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }
}

struct RidgitsDashboardCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
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

enum RidgitsFormStyle {
    static func fieldLabel(_ title: String, required: Bool = false) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textHeadline)
            if required {
                Text("*")
                    .foregroundStyle(RidgitsColors.destructive)
            }
        }
    }
}

struct RidgitsTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        Group {
            if let lineLimit, axis == .vertical {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(lineLimit)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(RidgitsTypography.body(13))
        .keyboardType(keyboard)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
    }
}

struct RidgitsSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(RidgitsColors.border)
            .frame(height: 1)
    }
}

struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image("Glogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct RidgitsBlockingLoaderOverlay: View {
    let title: String
    var subtitle: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: RidgitsColors.ctaBlack))
                    .scaleEffect(1.15)

                Text(title.uppercased())
                    .font(RidgitsTypography.sectionLabel(11))
                    .tracking(1.2)
                    .foregroundStyle(RidgitsColors.textHeadline)

                if let subtitle {
                    Text(subtitle)
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
        }
    }
}

private struct RidgitsBlockingLoaderModifier: ViewModifier {
    let isPresented: Bool
    let title: String
    let subtitle: String?

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                RidgitsBlockingLoaderOverlay(title: title, subtitle: subtitle)
            }
        }
    }
}

extension View {
    func ridgitsBlockingLoader(
        isPresented: Bool,
        title: String,
        subtitle: String? = nil
    ) -> some View {
        modifier(RidgitsBlockingLoaderModifier(
            isPresented: isPresented,
            title: title,
            subtitle: subtitle
        ))
    }
}
