import SwiftUI
import UIKit

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
        .buttonStyle(RidgitsHapticPrimaryButtonStyle())
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
        .buttonStyle(RidgitsHapticPlainButtonStyle())
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
        .buttonStyle(RidgitsHapticPlainButtonStyle())
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

struct RidgitsFullWidthDivider: View {
    var body: some View {
        Rectangle()
            .fill(RidgitsColors.border)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

struct RidgitsDashboardCard<Content: View>: View {
    var edgeToEdge: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        Group {
            if edgeToEdge {
                content
                    .background(RidgitsColors.surface)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(RidgitsColors.dashboardBorder)
                            .frame(height: 1)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(RidgitsColors.dashboardBorder)
                            .frame(height: 1)
                    }
            } else {
                content
                    .background(RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                            .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            }
        }
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
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            RidgitsColors.surface.ignoresSafeArea()
            VStack(spacing: 16) {
                RidgitsLogoView.onLight(size: 48)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(
                        .linear(duration: 1.1).repeatForever(autoreverses: false),
                        value: isSpinning
                    )

                Text("Signing you in to Ridgits…")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
        .onAppear { isSpinning = true }
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
        .foregroundStyle(RidgitsColors.textHeadline)
        .tint(RidgitsColors.ctaBlack)
        .colorScheme(.light)
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
        Button(action: action) {
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
        .buttonStyle(RidgitsHapticPlainButtonStyle(feedback: .medium))
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

// MARK: - Multiline text editor (visible typed text in light & dark mode)

struct RidgitsMultilineTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 132

    var body: some View {
        ZStack(alignment: .topLeading) {
            RidgitsTextEditorRepresentable(text: $text)
                .frame(minHeight: minHeight)

            if !placeholder.isEmpty && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(RidgitsTypography.body(16))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
        .background(RidgitsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
    }
}

private struct RidgitsTextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = UIColor(red: 10 / 255, green: 10 / 255, blue: 10 / 255, alpha: 1)
        textView.tintColor = UIColor(red: 10 / 255, green: 10 / 255, blue: 10 / 255, alpha: 1)
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = true
        textView.text = text
        textView.overrideUserInterfaceStyle = .light
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

// MARK: - AI markdown rendering (Quick Tools)

enum RidgitsAIMarkdown {
    /// Normalizes common AI markdown shapes before Swift's markdown parser runs.
    static func normalize(_ raw: String) -> String {
        var text = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Lines like "**Header:** body" → bullet with bold header
        text = text.replacingOccurrences(
            of: "(?m)^\\s*\\*\\*(.+?)\\*\\*\\s*:",
            with: "- **$1:**",
            options: .regularExpression
        )

        return text
    }

    static func attributedString(from raw: String) -> AttributedString {
        let normalized = normalize(raw)
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        if let attributed = try? AttributedString(markdown: normalized, options: options) {
            return attributed
        }
        return AttributedString(raw)
    }
}

struct RidgitsFormattedAIText: View {
    let content: String
    var font: Font = RidgitsTypography.body(14)
    var foreground: Color = RidgitsColors.textSecondary
    var lineSpacing: CGFloat = 4

    var body: some View {
        Text(RidgitsAIMarkdown.attributedString(from: content))
            .font(font)
            .foregroundStyle(foreground)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
