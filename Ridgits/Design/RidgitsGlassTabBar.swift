import SwiftUI

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
        padding(.bottom, 96)
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

    private var barHeight: CGFloat { 54 - (6 * compactProgress) }
    private var horizontalInset: CGFloat { 18 + (14 * compactProgress) }
    private var iconSize: CGFloat { 18 - (1.5 * compactProgress) }
    private var profileSize: CGFloat { 20 - (1.25 * compactProgress) }
    private var selectionWidth: CGFloat { 52 - (3 * compactProgress) }
    private var selectionHeight: CGFloat { 34 - (2 * compactProgress) }
    private var barScale: CGFloat { 1 - (0.04 * compactProgress) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RidgitsTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: barHeight)
        .background { glassBackground }
        .clipShape(Capsule(style: .continuous))
        .shadow(color: Color.white.opacity(0.65), radius: 1, y: -0.5)
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        .scaleEffect(barScale, anchor: .bottom)
        .padding(.horizontal, horizontalInset)
        .animation(Self.compactAnimation, value: compactProgress)
        .animation(Self.tabSwitchAnimation, value: selectedTab)
    }

    private var glassBackground: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.78),
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.28),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blendMode(.plusLighter)

            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.35),
                            Color.black.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                .blur(radius: 0.5)
                .padding(0.5)
        }
        .compositingGroup()
    }

    @ViewBuilder
    private func tabButton(_ tab: RidgitsTab) -> some View {
        let isSelected = tab == selectedTab
        Button {
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
            .frame(height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var selectionCapsule: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.thinMaterial)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.38),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 0.75)

            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.04))
                .blendMode(.multiply)
        }
        .frame(width: selectionWidth, height: selectionHeight)
        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
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
