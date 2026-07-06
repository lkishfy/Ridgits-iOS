import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @State private var profile = RidgitsUserProfile.empty(uid: "")
    @State private var quizBadges: [RidgitsQuizBadge] = []
    @State private var isEditing = false
    @State private var interestDraft = ""
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var statusMessage: String?
    @State private var matchGender: [Int] = []
    @State private var matchInterestedIn: [Int] = []
    @State private var matchLookingFor: [Int] = []
    @State private var showIdentityVerification = false
    @State private var showSubscriptionPaywall = false
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
        .sheet(isPresented: $showIdentityVerification) {
            IdentityVerificationView(autoStart: true) { success in
                showIdentityVerification = false
                if success {
                    Task { await ridgitsStore.refreshAccessInBackground() }
                }
            }
            .environmentObject(ridgitsStore)
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(
                highlightTier: .plus,
                headline: "Subscribe to verify",
                subheadline: "Identity Verification is included after you subscribe."
            )
            .environmentObject(ridgitsStore)
        }
        .task {
            await ridgitsStore.refreshAccessInBackground()
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

            IdentityVerificationStatusCard(
                access: ridgitsStore.access,
                canStartVerification: ridgitsStore.hasPlusMembership || ridgitsStore.hasNearbyAccess,
                onVerify: { showIdentityVerification = true },
                onSubscribe: { showSubscriptionPaywall = true }
            )

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
                                if ridgitsStore.isMembershipActive {
                                    RidgitsVerifiedBadge(
                                        tier: ridgitsStore.membershipTier,
                                        size: 18
                                    )
                                }
                                if ridgitsStore.access.isProfilePhotoVerified {
                                    RidgitsPhotoVerifiedBadge(size: 18)
                                }
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

                    if hasMatchPreferences {
                        RidgitsSectionDivider()
                        ProfileMatchPreferencesSummary(
                            gender: matchGender,
                            interestedIn: matchInterestedIn,
                            lookingFor: matchLookingFor,
                            ageRangeMin: profile.ageRangeMin,
                            ageRangeMax: profile.ageRangeMax
                        )
                    }

                    if !quizBadges.isEmpty {
                        RidgitsSectionDivider()
                        ProfileQuizBadgesSection(badges: quizBadges)
                    }
                }
                .padding(16)
            }

            NavigationLink {
                SubscriptionPaywallView(showsDragIndicator: false)
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
                        Text("Ridgits+, Premium, and Ultra")
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

            NavigationLink {
                ProfileSettingsView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Legal and account management")
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
                    RidgitsLocationPicker(
                        city: $profile.locationCity,
                        stateCode: $profile.locationStateCode,
                        legacyLocation: profile.location
                    )
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

                RidgitsSectionDivider()

                ProfileMatchPreferencesEditor(
                    gender: $matchGender,
                    interestedIn: $matchInterestedIn,
                    lookingFor: $matchLookingFor,
                    ageRangeMin: $profile.ageRangeMin,
                    ageRangeMax: $profile.ageRangeMax,
                    userAge: profile.age
                )

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
        .ridgitsProfilePhotoVerifiedOverlay(show: ridgitsStore.access.isProfilePhotoVerified, size: max(18, size * 0.24))
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

    private var hasMatchPreferences: Bool {
        !matchGender.isEmpty
            || !matchInterestedIn.isEmpty
            || !matchLookingFor.isEmpty
            || profile.ageRangeMin != nil
            || profile.ageRangeMax != nil
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
            RidgitsMatchAgeRange.normalize(on: &profile)
            if !loaded.hasBasicProfile {
                isEditing = true
            }
        }

        async let packProfile = RidgitsFirebaseClient.shared.fetchPackProfile(uid: uid)
        let progress = try? await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid)
        if let progress {
            applyMatchPreferences(from: progress)
        }
        let personalityCompleted = progress.map {
            $0.completed || QuizCatalog.hasEnoughPersonalityAnswers(in: $0.answers)
        } ?? false
        quizBadges = RidgitsQuizBadgeBuilder.badges(
            packProfile: await packProfile,
            personalityQuizCompleted: personalityCompleted
        )
        if quizBadges != profile.completedQuizBadges {
            await RidgitsFirebaseClient.shared.syncCompletedQuizBadges(uid: uid)
            profile.completedQuizBadges = quizBadges
        }
    }

    private func applyMatchPreferences(from progress: LoadedQuizProgress) {
        matchGender = QuizCatalog.selectedOptionValues(from: progress.answers["demo_000"])
        matchInterestedIn = QuizCatalog.selectedOptionValues(from: progress.answers["demo_001"])
        matchLookingFor = QuizCatalog.selectedOptionValues(from: progress.answers["demo_002"])
    }

    @MainActor
    private func saveProfile() async {
        isSaving = true
        statusMessage = nil
        defer { isSaving = false }
        RidgitsMatchAgeRange.normalize(on: &profile)
        do {
            try await RidgitsFirebaseClient.shared.saveUserProfile(profile)
            if let uid = authManager.currentUser?.uid {
                try await RidgitsFirebaseClient.shared.saveDemographicAnswers(
                    uid: uid,
                    gender: matchGender,
                    interestedIn: matchInterestedIn,
                    lookingFor: matchLookingFor
                )
                if let progress = try? await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid, source: .server) {
                    applyMatchPreferences(from: progress)
                }
            }
            if let matchMessage = await RidgitsProfilePhotoIdentityMatch.matchAfterProfileSaveIfNeeded() {
                statusMessage = matchMessage
            } else {
                isEditing = false
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

private enum RidgitsMatchAgeRange {
    static let minimumAge = 18
    static let maximumAge = 45

    static func suggestedMin(userAge: Int?) -> Int {
        let age = userAge ?? 30
        return min(maximumAge, max(minimumAge, age - 5))
    }

    static func suggestedMax(userAge: Int?) -> Int {
        maximumAge
    }

    static func normalize(on profile: inout RidgitsUserProfile) {
        var ageMin = profile.ageRangeMin ?? suggestedMin(userAge: profile.age)
        var ageMax = profile.ageRangeMax ?? suggestedMax(userAge: profile.age)
        ageMin = max(minimumAge, min(maximumAge, ageMin))
        ageMax = max(minimumAge, min(maximumAge, ageMax))
        if ageMin > ageMax { ageMin = ageMax }
        profile.ageRangeMin = ageMin
        profile.ageRangeMax = ageMax
    }
}

private struct ProfileMatchPreferencesEditor: View {
    @Binding var gender: [Int]
    @Binding var interestedIn: [Int]
    @Binding var lookingFor: [Int]
    @Binding var ageRangeMin: Int?
    @Binding var ageRangeMax: Int?
    let userAge: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MATCH PREFERENCES")
                    .font(RidgitsTypography.sectionLabel(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .tracking(0.8)
                Text("Used for matching. Update these here instead of in Modify Quiz.")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }

            ForEach(QuizCatalog.demographicQuestions, id: \.id) { question in
                ProfileDemographicQuestionEditor(
                    question: question,
                    selection: binding(for: question.id)
                )
            }

            ProfileAgeRangeEditor(
                rangeMin: minBinding,
                rangeMax: maxBinding
            )
        }
    }

    private var minBinding: Binding<Int> {
        Binding(
            get: { ageRangeMin ?? RidgitsMatchAgeRange.suggestedMin(userAge: userAge) },
            set: { newValue in
                ageRangeMin = newValue
                let currentMax = ageRangeMax ?? RidgitsMatchAgeRange.suggestedMax(userAge: userAge)
                if newValue > currentMax {
                    ageRangeMax = newValue
                }
            }
        )
    }

    private var maxBinding: Binding<Int> {
        Binding(
            get: { ageRangeMax ?? RidgitsMatchAgeRange.suggestedMax(userAge: userAge) },
            set: { newValue in
                ageRangeMax = newValue
                let currentMin = ageRangeMin ?? RidgitsMatchAgeRange.suggestedMin(userAge: userAge)
                if newValue < currentMin {
                    ageRangeMin = newValue
                }
            }
        )
    }

    private func binding(for questionID: String) -> Binding<[Int]> {
        switch questionID {
        case "demo_000":
            return $gender
        case "demo_001":
            return $interestedIn
        case "demo_002":
            return $lookingFor
        default:
            return .constant([])
        }
    }
}

private struct ProfileMatchPreferencesSummary: View {
    let gender: [Int]
    let interestedIn: [Int]
    let lookingFor: [Int]
    let ageRangeMin: Int?
    let ageRangeMax: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MATCH PREFERENCES")
                .font(RidgitsTypography.sectionLabel(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(0.8)

            ForEach(QuizCatalog.demographicQuestions, id: \.id) { question in
                let values = values(for: question.id)
                if !values.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(question.text)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                        FlowLayout(spacing: 8) {
                            ForEach(QuizCatalog.labels(for: values, in: question), id: \.self) { label in
                                Text(label)
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
            }

            if let ageRangeMin, let ageRangeMax {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Age range you want to connect with")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    Text("\(ageRangeMin)–\(ageRangeMax)")
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

    private func values(for questionID: String) -> [Int] {
        switch questionID {
        case "demo_000": return gender
        case "demo_001": return interestedIn
        case "demo_002": return lookingFor
        default: return []
        }
    }
}

private struct ProfileAgeRangeEditor: View {
    @Binding var rangeMin: Int
    @Binding var rangeMax: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age range you want to connect with")
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textHeadline)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                agePicker(title: "Min", selection: $rangeMin)
                Text("to")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                agePicker(title: "Max", selection: $rangeMax)
            }

            Text("Shows matches ages \(rangeMin)–\(rangeMax)")
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textMuted)
        }
    }

    private func agePicker(title: String, selection: Binding<Int>) -> some View {
        Menu {
            ForEach(RidgitsMatchAgeRange.minimumAge...RidgitsMatchAgeRange.maximumAge, id: \.self) { age in
                Button("\(age)") {
                    selection.wrappedValue = age
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
                Text("\(selection.wrappedValue)")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
        }
    }
}

private struct ProfileDemographicQuestionEditor: View {
    let question: QuizQuestion
    @Binding var selection: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.text)
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textHeadline)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8) {
                ForEach(question.options) { option in
                    let selected = selection.contains(option.value)
                    Button {
                        toggle(option.value)
                    } label: {
                        Text(option.label)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(selected ? RidgitsColors.textHeadline : RidgitsColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selected ? RidgitsColors.hoverSurface : RidgitsColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                    .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: selected ? 1.5 : 1)
                            )
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                }
            }
        }
    }

    private func toggle(_ value: Int) {
        if question.id == "demo_000" || question.id == "demo_001" {
            selection = [value]
            return
        }

        if selection.contains(value) {
            selection.removeAll { $0 == value }
        } else {
            selection.append(value)
            selection.sort()
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
