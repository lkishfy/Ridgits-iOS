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
        // Clearance for the floating glass tab bar (bar + bottom margin + tap target).
        padding(.bottom, 98)
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

    private var barHeight: CGFloat { 62 - (6 * compactProgress) }
    private var tabRowHeight: CGFloat { barHeight - 10 }
    private var horizontalInset: CGFloat { 18 + (14 * compactProgress) }
    private var iconSize: CGFloat { 18 - (1.5 * compactProgress) }
    private var profileSize: CGFloat { 20 - (1.25 * compactProgress) }
    private var selectionWidth: CGFloat { 54 - (3 * compactProgress) }
    private var selectionHeight: CGFloat { min(34, tabRowHeight - 2) - (2 * compactProgress) }
    private var barScale: CGFloat { 1 - (0.04 * compactProgress) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RidgitsTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(height: barHeight)
        .background { glassBackground }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(glassBorderGradient, lineWidth: 0.75)
        }
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
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
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
                    .ridgitsTabBadge(
                        badgeCount(for: tab),
                        style: tab == .messages ? .numbered : .dot
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: tabRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    private var selectionCapsule: some View {
        Capsule(style: .continuous)
            .fill(RidgitsColors.hoverSurface)
            .frame(width: selectionWidth, height: selectionHeight)
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

private enum RidgitsTabBadgeStyle {
    case dot
    case numbered
}

private extension View {
    func ridgitsTabBadge(_ count: Int, style: RidgitsTabBadgeStyle = .dot) -> some View {
        overlay(alignment: .topTrailing) {
            if count > 0 {
                switch style {
                case .dot:
                    Circle()
                        .fill(Color(hex: 0xFF3040))
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.25))
                        .offset(x: 6, y: -6)
                case .numbered:
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, count > 9 ? 3 : 0)
                        .frame(minWidth: 14, minHeight: 14)
                        .background(Color(hex: 0xFF3040))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                        .offset(x: 8, y: -7)
                }
            }
        }
    }
}
