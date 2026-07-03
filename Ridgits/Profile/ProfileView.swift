import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @State private var profile = RidgitsUserProfile.empty(uid: "")
    @State private var isEditing = false
    @State private var interestDraft = ""
    @State private var isSaving = false
    @State private var isUpdatingVisibility = false
    @State private var isLoading = true
    @State private var statusMessage: String?
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if isEditing {
                    editContent
                } else {
                    displayContent
                }
            }
            .ridgitsTabBarScrollTracking()
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .ridgitsFloatingTabBarPadding()
        }
        .coordinateSpace(name: "ridgitsTabScroll")
        .background(RidgitsColors.feedBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                RidgitsLogoView.onLight(size: 22)
            }
        }
        .task { await loadProfile() }
        .onAppear {
            guard let uid = authManager.currentUser?.uid,
                  profile.id.isEmpty,
                  let cached = RidgitsProfileCache.shared.profile(for: uid) else { return }
            profile = cached
            isLoading = false
        }
    }

    private var profileCardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Profile")
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text(isEditing
                     ? "Complete your profile to get the most out of Ridgits"
                     : "View and manage your profile information")
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }

            Spacer(minLength: 8)

            if isEditing {
                Button("Cancel") {
                    isEditing = false
                    Task { await loadProfile() }
                }
                .font(RidgitsTypography.label(11))
                .foregroundStyle(RidgitsColors.textSecondary)
            } else if profile.hasBasicProfile {
                Button { isEditing = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(RidgitsColors.hoverSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReferralProfileSection()

            RidgitsDashboardCard {
                VStack(alignment: .leading, spacing: 16) {
                    profileCardHeader

                    RidgitsSectionDivider()

                    HStack(alignment: .top, spacing: 14) {
                        profileImage(size: 88, rounded: true)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(profile.name.isEmpty ? "Add your name" : profile.name)
                                    .font(RidgitsTypography.headline(20))
                                    .foregroundStyle(RidgitsColors.textHeadline)
                                RidgitsVerifiedBadge(
                                    tier: ridgitsStore.isMembershipActive
                                        ? ridgitsStore.membershipTier.rawValue
                                        : "free",
                                    size: 18
                                )
                            }
                            if let age = profile.age {
                                Text("\(age) years old")
                                    .font(RidgitsTypography.body(13))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                            }
                            if !profile.location.isEmpty {
                                Label(profile.location, systemImage: "mappin.and.ellipse")
                                    .font(RidgitsTypography.body(13))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                            }
                            if !profile.socialHandle.isEmpty {
                                Text(profile.socialHandle)
                                    .font(RidgitsTypography.body(13))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                            }
                        }
                    }

                    if !profile.about.isEmpty {
                        RidgitsSectionDivider()
                        profileSection(title: "About", body: profile.about)
                    }

                    if !profile.interests.isEmpty {
                        RidgitsSectionDivider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTERESTS")
                                .font(RidgitsTypography.sectionLabel(11))
                                .foregroundStyle(RidgitsColors.textSecondary)
                                .tracking(0.8)
                            FlowLayout(spacing: 8) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(RidgitsTypography.caption(12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RidgitsColors.hoverSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                                .stroke(RidgitsColors.border, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    if !profile.aspirations.isEmpty {
                        RidgitsSectionDivider()
                        profileSection(title: "Aspirations", body: profile.aspirations)
                    }
                }
                .padding(16)
            }

            NavigationLink {
                SubscriptionPaywallView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if ridgitsStore.isMembershipActive {
                            RidgitsVerifiedBadgeLabel(tier: ridgitsStore.membershipTier, badgeSize: 16)
                        } else {
                            Text("Manage Subscription")
                                .font(RidgitsTypography.label(14))
                                .foregroundStyle(RidgitsColors.textHeadline)
                        }
                        Text("Ridgits+, Premium, and Ultra plans")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
                .padding(16)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                        .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())

            RidgitsDashboardCard {
                Toggle(isOn: communityVisibilityBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Visible in Community")
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text(profile.visibleInCommunity
                             ? "Others can discover you and you can send pokes and messages."
                             : "You're browsing privately — hidden from discovery.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                }
                .tint(RidgitsColors.ctaBlack)
                .disabled(isUpdatingVisibility)
                .padding(16)
            }

            if let statusMessage, !isEditing {
                Text(statusMessage)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.destructive)
            }

            NavigationLink {
                NotificationPreferencesView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notification Settings")
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Pokes, messages, expiring chats, nearby pings")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
                .padding(16)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                        .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())

            if ridgitsStore.hasNearbyAccess || ridgitsStore.hasWebSubscription {
                RidgitsDashboardCard {
                    Toggle(isOn: $nearbyPresence.alertsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nearby Ridgits pings")
                                .font(RidgitsTypography.label(14))
                                .foregroundStyle(RidgitsColors.textHeadline)
                            Text("Bluetooth alert when another Ridgits member is close")
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                    }
                    .tint(RidgitsColors.ctaBlack)
                    .padding(16)
                    .ridgitsSelectionHaptic(trigger: nearbyPresence.alertsEnabled)
                }
            }

            NavigationLink {
                ProfileSettingsView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Terms, privacy, sign out, and delete account")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
                .padding(16)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                        .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
            .padding(.bottom, 8)
        }
    }

    private var editContent: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                profileCardHeader

                RidgitsSectionDivider()

                VStack(alignment: .leading, spacing: 8) {
                    RidgitsFormStyle.fieldLabel("Profile Photo", required: true)
                    RidgitsProfilePhotoPicker(imageURL: $profile.image)
                }

                fieldBlock("Username", required: true) {
                    RidgitsTextField(placeholder: "Enter your username", text: $profile.name)
                }

                fieldBlock("Age", required: true) {
                    RidgitsTextField(
                        placeholder: "Enter your age",
                        text: Binding(
                            get: { profile.age.map(String.init) ?? "" },
                            set: { profile.age = Int($0) }
                        ),
                        keyboard: .numberPad
                    )
                }

                fieldBlock("Location", required: true) {
                    RidgitsTextField(placeholder: "City, State", text: $profile.location)
                }

                fieldBlock("Social Handle") {
                    RidgitsTextField(placeholder: "@username", text: $profile.socialHandle)
                }

                fieldBlock("About Me", required: true) {
                    RidgitsTextField(
                        placeholder: "Tell us about yourself…",
                        text: $profile.about,
                        axis: .vertical,
                        lineLimit: 3...6
                    )
                }

                fieldBlock("Aspirations", required: true) {
                    RidgitsTextField(
                        placeholder: "What are you looking for?",
                        text: $profile.aspirations,
                        axis: .vertical,
                        lineLimit: 2...4
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Settings")
                        .font(RidgitsTypography.headline(16))
                        .foregroundStyle(RidgitsColors.textHeadline)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Visible in Community")
                                .font(RidgitsTypography.label(14))
                                .foregroundStyle(RidgitsColors.textHeadline)
                            Text("When enabled, other users can discover you and you can send pokes and messages. Turn this off to browse privately.")
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Toggle("", isOn: $profile.visibleInCommunity)
                            .labelsHidden()
                            .tint(RidgitsColors.ctaBlack)
                    }
                    .padding(14)
                    .background(RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                            .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    RidgitsFormStyle.fieldLabel("Interests", required: true)
                    HStack(spacing: 8) {
                        RidgitsTextField(placeholder: "Add interest", text: $interestDraft)
                        Button("Add") {
                            let trimmed = interestDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            profile.interests.append(trimmed)
                            interestDraft = ""
                        }
                        .font(RidgitsTypography.label(12))
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(profile.interests, id: \.self) { interest in
                            HStack(spacing: 4) {
                                Text(interest)
                                    .font(RidgitsTypography.caption(12))
                                Button {
                                    profile.interests.removeAll { $0 == interest }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(RidgitsColors.hoverSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                    .stroke(RidgitsColors.border, lineWidth: 1)
                            )
                        }
                    }
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)
                }

                HStack(spacing: 10) {
                    RidgitsSquareButton(title: isSaving ? "Saving…" : "Save Profile", style: .filled) {
                        Task { await saveProfile() }
                    }
                    .disabled(isSaving || !profile.isCompleteForMatching)

                    if profile.hasBasicProfile {
                        RidgitsSquareButton(title: "Cancel", style: .ghost) {
                            isEditing = false
                            Task { await loadProfile() }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func profileImage(size: CGFloat, rounded: Bool) -> some View {
        RidgitsCachedProfileImage(remoteURL: profile.image.isEmpty ? nil : profile.image) {
            placeholderImage(size: size)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: rounded ? size / 2 : RidgitsRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: rounded ? size / 2 : RidgitsRadius.md)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
    }

    private func placeholderImage(size: CGFloat) -> some View {
        RidgitsColors.hoverSurface
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(RidgitsColors.textMuted)
            )
    }

    private func profileSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(RidgitsTypography.sectionLabel(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(0.8)
            Text(body)
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
                .lineSpacing(3)
        }
    }

    private func fieldBlock<Content: View>(_ title: String, required: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RidgitsFormStyle.fieldLabel(title, required: required)
            content()
        }
    }

    private var communityVisibilityBinding: Binding<Bool> {
        Binding(
            get: { profile.visibleInCommunity },
            set: { newValue in
                guard newValue != profile.visibleInCommunity else { return }
                RidgitsHaptics.play(.selection)
                profile.visibleInCommunity = newValue
                Task { await saveCommunityVisibility() }
            }
        )
    }

    @MainActor
    private func saveCommunityVisibility() async {
        let savedValue = profile.visibleInCommunity
        isUpdatingVisibility = true
        defer { isUpdatingVisibility = false }
        do {
            try await RidgitsFirebaseClient.shared.saveUserProfile(profile)
            statusMessage = nil
            nearbyPresence.updateEligibility(
                isSignedIn: authManager.userIsLoggedIn,
                profileComplete: profile.isCompleteForMatching && profile.visibleInCommunity,
                hasNearbyAccess: ridgitsStore.hasExtendedNearbyRadius || ridgitsStore.hasWebSubscription,
                displayName: profile.name,
                profileCode: nil
            )
        } catch {
            profile.visibleInCommunity = !savedValue
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadProfile() async {
        guard let uid = authManager.currentUser?.uid else { return }

        if profile.id.isEmpty, let cached = RidgitsProfileCache.shared.profile(for: uid) {
            profile = cached
            isLoading = false
        } else if profile.id.isEmpty {
            isLoading = true
        }

        defer { isLoading = false }

        if let loaded = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid) {
            profile = loaded
            if !loaded.hasBasicProfile {
                isEditing = true
            }
        }
    }

    @MainActor
    private func saveProfile() async {
        isSaving = true
        statusMessage = nil
        defer { isSaving = false }
        do {
            try await RidgitsFirebaseClient.shared.saveUserProfile(profile)
            isEditing = false
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
