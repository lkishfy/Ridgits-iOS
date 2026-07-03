import SwiftUI
import UIKit

enum RidgitsTab: Int, CaseIterable, Identifiable {
    case home = 0
    case matches = 1
    case ridgit = 2
    case messages = 3
    case profile = 4

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .matches: return "heart"
        case .ridgit: return ""
        case .messages: return "paperplane"
        case .profile: return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .matches: return "heart.fill"
        case .ridgit: return ""
        case .messages: return "paperplane.fill"
        case .profile: return "person.circle.fill"
        }
    }

    var usesLogo: Bool { self == .ridgit }
}

@MainActor
final class RidgitsTabBarScrollState: ObservableObject {
    @Published private(set) var compactProgress: CGFloat = 0

    func update(contentOffset: CGFloat) {
        let progress = min(max(contentOffset / 100, 0), 1)
        guard abs(progress - compactProgress) > 0.01 else { return }
        withAnimation(RidgitsGlassTabBar.compactAnimation) {
            compactProgress = progress
        }
    }

    func reset() {
        guard compactProgress > 0 else { return }
        withAnimation(RidgitsGlassTabBar.compactAnimation) {
            compactProgress = 0
        }
    }
}

private struct RidgitsScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct RidgitsTabBarScrollTracker: ViewModifier {
    @EnvironmentObject private var tabBarScroll: RidgitsTabBarScrollState

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: RidgitsScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("ridgitsTabScroll")).minY
                    )
                }
            )
            .onPreferenceChange(RidgitsScrollOffsetPreferenceKey.self) { offset in
                tabBarScroll.update(contentOffset: max(0, -offset))
            }
    }
}

extension View {
    func ridgitsTabBarScrollTracking() -> some View {
        modifier(RidgitsTabBarScrollTracker())
    }

    func ridgitsFloatingTabBarPadding() -> some View {
        // Tab bar space is reserved via `safeAreaInset` on `DashboardView`.
        // Keep a little trailing breathing room at the end of scroll content.
        padding(.bottom, 12)
    }
}

struct RidgitsGlassTabBar: View {
    static let tabSwitchAnimation: Animation = .interactiveSpring(
        response: 0.52,
        dampingFraction: 0.78,
        blendDuration: 0.28
    )

    static let compactAnimation: Animation = .interactiveSpring(
        response: 0.42,
        dampingFraction: 0.84,
        blendDuration: 0.2
    )

    let selectedTab: RidgitsTab
    let onSelect: (RidgitsTab) -> Void
    let compactProgress: CGFloat
    let profileImageURL: String?
    let matchesBadge: Int
    let messagesBadge: Int

    @Namespace private var selectionNamespace

    private var barHeight: CGFloat { 56 - (6 * compactProgress) }
    private var tabRowHeight: CGFloat { barHeight - 8 }
    private var horizontalInset: CGFloat { 18 + (14 * compactProgress) }
    private var iconSize: CGFloat { 18 - (1.5 * compactProgress) }
    private var profileSize: CGFloat { 20 - (1.25 * compactProgress) }
    private var selectionWidth: CGFloat { 52 - (3 * compactProgress) }
    private var selectionHeight: CGFloat { min(28, tabRowHeight - 4) - (2 * compactProgress) }
    private var barScale: CGFloat { 1 - (0.04 * compactProgress) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RidgitsTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: barHeight)
        .background { glassBackground.clipShape(Capsule(style: .continuous)) }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(glassBorderGradient, lineWidth: 0.75)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.14), radius: 18, y: 10)
        .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
        .scaleEffect(barScale, anchor: .bottom)
        .padding(.horizontal, horizontalInset)
        .animation(Self.compactAnimation, value: compactProgress)
        .animation(Self.tabSwitchAnimation, value: selectedTab)
    }

    private var glassBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.65),
                Color.white.opacity(0.18),
                Color.black.opacity(0.08),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glassBackground: some View {
        ZStack {
            RidgitsVisualEffectBlur(style: .systemChromeMaterialLight)
            // Very light tint so content behind still reads through the blur.
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        }
    }

    @ViewBuilder
    private func tabButton(_ tab: RidgitsTab) -> some View {
        let isSelected = tab == selectedTab
        Button {
            if !isSelected {
                RidgitsHaptics.play(.selection)
            }
            withAnimation(Self.tabSwitchAnimation) {
                onSelect(tab)
            }
        } label: {
            ZStack {
                if isSelected {
                    selectionCapsule
                        .matchedGeometryEffect(id: "tabSelection", in: selectionNamespace)
                }

                tabIcon(tab, isSelected: isSelected)
                    .ridgitsTabBadge(badgeCount(for: tab))
            }
            .frame(maxWidth: .infinity)
            .frame(height: tabRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    private var selectionCapsule: some View {
        ZStack {
            RidgitsVisualEffectBlur(style: .systemThinMaterialLight)
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.12))
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.5)
        }
        .frame(width: selectionWidth, height: selectionHeight)
        .clipShape(Capsule(style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
    }

    private func badgeCount(for tab: RidgitsTab) -> Int {
        switch tab {
        case .matches: return matchesBadge
        case .messages: return messagesBadge
        default: return 0
        }
    }

    @ViewBuilder
    private func tabIcon(_ tab: RidgitsTab, isSelected: Bool) -> some View {
        if tab.usesLogo {
            RidgitsLogoView.onLight(size: iconSize + 2)
                .opacity(isSelected ? 1 : 0.72)
                .scaleEffect(isSelected ? 1.06 : 1)
                .animation(Self.tabSwitchAnimation, value: isSelected)
        } else if tab == .profile, let profileImageURL, !profileImageURL.isEmpty {
            RidgitsCachedProfileImage(remoteURL: profileImageURL) {
                Circle().fill(RidgitsColors.border)
                    .overlay(
                        systemTabIcon(tab, isSelected: isSelected)
                    )
            }
            .frame(width: profileSize, height: profileSize)
            .clipShape(Circle())
            .scaleEffect(isSelected ? 1.06 : 1)
            .animation(Self.tabSwitchAnimation, value: isSelected)
        } else {
            systemTabIcon(tab, isSelected: isSelected)
        }
    }

    private func systemTabIcon(_ tab: RidgitsTab, isSelected: Bool) -> some View {
        Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
            .font(.system(size: iconSize, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(RidgitsColors.textHeadline.opacity(isSelected ? 1 : 0.72))
            .scaleEffect(isSelected ? 1.06 : 1)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: isSelected)
            .animation(Self.tabSwitchAnimation, value: isSelected)
    }
}

private struct RidgitsVisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

private extension View {
    func ridgitsTabBadge(_ count: Int) -> some View {
        overlay(alignment: .topTrailing) {
            if count > 0 {
                Circle()
                    .fill(Color(hex: 0xFF3040))
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.25))
                    .offset(x: 6, y: -6)
            }
        }
    }
}
