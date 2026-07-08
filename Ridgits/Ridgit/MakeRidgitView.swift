import SwiftUI
import FirebaseAuth

struct MakeRidgitView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @State private var profile = RidgitsUserProfile.empty(uid: "")
    @State private var ridgits: [RidgitChallenge] = []
    @State private var activeRidgitIds: [String] = []
    @State private var showEditor = false
    @State private var editingRidgit: RidgitChallenge?
    @State private var deleteConfirmId: String?
    @State private var errorMessage: String?
    @State private var nearbySharePayload: RidgitSharePayload?
    @State private var showRidgitLimitPaywall = false
    @State private var showRidgitLimitAlert = false
    @State private var showRidgitSelection = false

    private var ridgitLimit: Int {
        RidgitsSubscriptionCatalog.maxRidgits(
            tier: ridgitsStore.membershipTier,
            isMembershipActive: ridgitsStore.isMembershipActive
        )
    }

    private var activeRidgitCount: Int {
        activeRidgitIds.filter { id in ridgits.contains(where: { $0.id == id }) }.count
    }

    private var canCreateMoreRidgits: Bool {
        activeRidgitCount < ridgitLimit
    }

    private var inactiveRidgitCount: Int {
        ridgits.count - activeRidgitCount
    }

    private var ridgitLimitPaywallTier: RidgitsSubscriptionTier {
        RidgitsSubscriptionCatalog.ridgitLimitPaywallTier(
            current: ridgitsStore.membershipTier,
            isMembershipActive: ridgitsStore.isMembershipActive
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Make Ridgit")
                        .font(RidgitsTypography.headline(24))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text("Create quizzes that reveal your social media info only to those who pass")
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    Text("\(activeRidgitCount) of \(ridgitLimit) active Ridgits")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textMuted)
                    if inactiveRidgitCount > 0 {
                        Text("\(inactiveRidgitCount) inactive — upgrade to use again, or delete to remove")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                }

                if !showEditor {
                    createCard
                }

                if showEditor {
                    RidgitEditorView(
                        profile: profile,
                        existing: editingRidgit,
                        ridgitLimit: ridgitLimit,
                        canCreateNew: canCreateMoreRidgits,
                        onLimitReached: handleRidgitLimitReached,
                        onCancel: cancelEditor,
                        onSaved: { await reload(forceRefresh: true) }
                    )
                }

                if !showEditor, !ridgits.isEmpty {
                    Text("Your Ridgits (\(ridgits.count))")
                        .font(RidgitsTypography.label(15))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .padding(.top, 8)

                    ForEach(ridgits) { ridgit in
                        ridgitRow(ridgit, isActive: RidgitSlotManager.isActive(ridgitId: ridgit.id, activeIds: activeRidgitIds))
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)
                }
            }
            .ridgitsTabBarScrollTracking()
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .ridgitsFloatingTabBarPadding()
        }
        .coordinateSpace(name: "ridgitsTabScroll")
        .background(RidgitsColors.feedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            applyCachedIfAvailable()
            await reload(forceRefresh: false)
        }
        .onChange(of: ridgitsStore.membershipTier) { _, _ in
            Task { await reload(forceRefresh: false) }
        }
        .onChange(of: ridgitsStore.isMembershipActive) { _, _ in
            Task { await reload(forceRefresh: false) }
        }
        .fullScreenCover(item: $nearbySharePayload) { payload in
            RidgitNearbyShareSenderSheet(payload: payload) { _ in
                nearbySharePayload = nil
            }
            .environmentObject(nearbyPresence)
        }
        .sheet(isPresented: $showRidgitLimitPaywall) {
            SubscriptionPaywallView(
                preferredBilling: .yearly,
                highlightTier: ridgitLimitPaywallTier,
                headline: "Create more Ridgits",
                subheadline: ridgitLimitPaywallSubheadline
            )
        }
        .fullScreenCover(isPresented: $showRidgitSelection) {
            RidgitSlotSelectionSheet(
                ridgits: ridgits,
                slotLimit: ridgitLimit,
                tierName: ridgitsStore.isMembershipActive ? ridgitsStore.membershipTier.displayName : "Free"
            ) { selected in
                await confirmActiveSelection(selected)
            }
        }
        .alert("Ridgit limit reached", isPresented: $showRidgitLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Ultra members can create up to 5 active Ridgits. Delete one to make room for a new quiz.")
        }
    }

    private var ridgitLimitPaywallSubheadline: String {
        switch ridgitLimitPaywallTier {
        case .plus:
            return "Ridgits+ includes 2 Ridgits — \(ridgitsStore.priceLine(tier: .plus, billing: .yearly))/year."
        case .premium:
            return "Ridgits+ includes 2 Ridgits. Premium includes 3 — \(ridgitsStore.priceLine(tier: .premium, billing: .yearly))/year."
        case .ultra:
            return "Upgrade to Ultra for up to 5 Ridgits — \(ridgitsStore.priceLine(tier: .ultra, billing: .yearly))/year."
        default:
            return "Upgrade for more Ridgits."
        }
    }

    private func handleRidgitLimitReached() {
        if ridgitsStore.membershipTier == .ultra && ridgitsStore.isMembershipActive {
            showRidgitLimitAlert = true
        } else {
            showRidgitLimitPaywall = true
        }
    }

    private var createCard: some View {
        Button {
            guard canCreateMoreRidgits else {
                handleRidgitLimitReached()
                return
            }
            editingRidgit = nil
            showEditor = true
        } label: {
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                    .fill(RidgitsColors.ctaBlack)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                    )
                VStack(spacing: 4) {
                    Text("Create New Ridgit")
                        .font(RidgitsTypography.label(15))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text("Create a custom quiz that reveals your social media only to those who pass")
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.border, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    private func ridgitRow(_ ridgit: RidgitChallenge, isActive: Bool) -> some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(ridgit.title)
                        .font(RidgitsTypography.label(16))
                        .foregroundStyle(isActive ? RidgitsColors.textHeadline : RidgitsColors.textMuted)
                    Spacer()
                    if isActive {
                        Button("Edit") {
                            editingRidgit = ridgit
                            showEditor = true
                        }
                        .font(RidgitsTypography.label(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    if deleteConfirmId == ridgit.id {
                        Button("Confirm") {
                            Task { await deleteRidgit(ridgit.id) }
                        }
                        .font(RidgitsTypography.label(12))
                        .foregroundStyle(RidgitsColors.destructive)
                        Button("Cancel") { deleteConfirmId = nil }
                            .font(RidgitsTypography.label(12))
                    } else {
                        Button("Delete") { deleteConfirmId = ridgit.id }
                            .font(RidgitsTypography.label(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }
                }

                if !isActive {
                    Text("Inactive — upgrade your plan to edit, share, or preview this Ridgit.")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(ridgit.questions.prefix(3).enumerated()), id: \.offset) { index, question in
                        Text("\(index + 1). \(question.question)")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(isActive ? RidgitsColors.textSecondary : RidgitsColors.textMuted)
                            .lineLimit(1)
                    }
                    if ridgit.questions.count > 3 {
                        Text("\(ridgit.questions.count - 3) more question(s)…")
                            .font(RidgitsTypography.caption(11))
                            .foregroundStyle(RidgitsColors.textMuted)
                    }
                }

                if isActive {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SHARE NEARBY")
                            .font(RidgitsTypography.caption(10))
                            .foregroundStyle(RidgitsColors.textMuted)
                            .tracking(0.8)
                        Text("Ridgits can only be shared by bumping phones with another Ridgits member nearby.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    RidgitsSquareButton(title: "Share Nearby", style: .filled) {
                        nearbySharePayload = RidgitSharePayload(
                            ridgitId: ridgit.id,
                            title: ridgit.title,
                            senderName: senderDisplayName,
                            previewQuestion: ridgit.questions.first?.question
                        )
                    }

                    NavigationLink {
                        RidgitQuizView(ridgitId: ridgit.id)
                    } label: {
                        Text("Preview")
                            .font(RidgitsTypography.label(12))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .underline()
                    }
                }
            }
            .padding(16)
        }
        .opacity(isActive ? 1 : 0.55)
    }

    private var senderDisplayName: String {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        return authManager.currentUser?.displayName ?? "Someone nearby"
    }

    private func cancelEditor() {
        showEditor = false
        editingRidgit = nil
    }

    private func applyCachedIfAvailable() {
        guard let uid = authManager.currentUser?.uid else { return }
        if let cachedProfile = RidgitsProfileCache.shared.profile(for: uid) {
            profile = cachedProfile
        }
        guard let cached = RidgitsRidgitListCache.shared.record(for: uid) else { return }
        ridgits = cached.ridgits
        activeRidgitIds = cached.activeRidgitIds
    }

    @MainActor
    private func reload(forceRefresh: Bool) async {
        guard let uid = authManager.currentUser?.uid else { return }
        let policy: RidgitsFirebaseClient.ProfileFetchPolicy = forceRefresh ? .networkOnly : .cacheFirst
        profile = (try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid, policy: policy)) ?? .empty(uid: uid)
        ridgits = await RidgitsFirebaseClient.shared.fetchRidgits(userId: uid, policy: policy)
        var ids = await RidgitsFirebaseClient.shared.fetchActiveRidgitIds(uid: uid, policy: policy)
        showEditor = false
        editingRidgit = nil

        if RidgitSlotManager.needsSelection(ridgits: ridgits, activeIds: ids, limit: ridgitLimit) {
            activeRidgitIds = ids
            showRidgitSelection = true
            return
        }

        if ids.isEmpty, !ridgits.isEmpty {
            ids = RidgitSlotManager.defaultActiveIds(from: ridgits, limit: ridgitLimit)
            try? await RidgitsFirebaseClient.shared.saveActiveRidgitIds(uid: uid, ids: ids)
        } else {
            let sanitized = RidgitSlotManager.sanitizedActiveIds(ids, ridgits: ridgits, limit: ridgitLimit)
            if sanitized != ids {
                ids = sanitized
                try? await RidgitsFirebaseClient.shared.saveActiveRidgitIds(uid: uid, ids: ids)
            }
        }

        let inactive = RidgitSlotManager.inactiveRidgits(from: ridgits, activeIds: ids)
        if ids.count < ridgitLimit, !inactive.isEmpty {
            let slots = ridgitLimit - ids.count
            let reactivated = inactive.prefix(slots).map(\.id)
            ids.append(contentsOf: reactivated)
            try? await RidgitsFirebaseClient.shared.saveActiveRidgitIds(uid: uid, ids: ids)
        }

        activeRidgitIds = ids
    }

    @MainActor
    private func confirmActiveSelection(_ selected: [String]) async {
        guard let uid = authManager.currentUser?.uid else { return }
        do {
            try await RidgitsFirebaseClient.shared.saveActiveRidgitIds(uid: uid, ids: selected)
            activeRidgitIds = selected
            showRidgitSelection = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteRidgit(_ id: String) async {
        guard let uid = authManager.currentUser?.uid else { return }
        do {
            try await RidgitsFirebaseClient.shared.deleteRidgit(id: id, userId: uid)
            deleteConfirmId = nil
            await reload(forceRefresh: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct RidgitEditorView: View {
    let profile: RidgitsUserProfile
    let existing: RidgitChallenge?
    let ridgitLimit: Int
    let canCreateNew: Bool
    let onLimitReached: () -> Void
    let onCancel: () -> Void
    let onSaved: () async -> Void

    @State private var title = ""
    @State private var questions: [RidgitQuestion] = [RidgitQuestion(question: "", options: ["", "", "", ""], correctAnswer: 0, numOptions: 4)]
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RidgitsDashboardCard {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RidgitsFormStyle.fieldLabel("Ridgit Title", required: true)
                        RidgitsTextField(placeholder: "My NYC Food Quiz", text: $title)
                    }

                    ForEach(Array(questions.enumerated()), id: \.offset) { index, _ in
                        questionEditor(index: index)
                    }

                    if questions.count < 10 {
                        RidgitsSquareButton(title: "Add Question (up to 10)", style: .ghost) {
                            questions.append(RidgitQuestion(question: "", options: ["", "", "", ""], correctAnswer: 0, numOptions: 4))
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    HStack(spacing: 10) {
                        RidgitsSquareButton(
                            title: isSaving ? "Saving…" : (existing == nil ? "Create Ridgit" : "Update Ridgit"),
                            style: .filled
                        ) {
                            Task { await save() }
                        }
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)

                        RidgitsSquareButton(title: "Cancel", style: .ghost, action: onCancel)
                    }
                }
                .padding(16)
            }

            RidgitPreviewCard(
                profile: profile,
                title: title.isEmpty ? "Your Ridgit Title" : title,
                questions: questions
            )
        }
        .onAppear {
            if let existing {
                title = existing.title
                questions = existing.questions
            }
        }
    }

    @ViewBuilder
    private func questionEditor(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Question \(index + 1)")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Spacer()
                if questions.count > 1 {
                    Button("Remove") { questions.remove(at: index) }
                        .font(RidgitsTypography.label(11))
                        .foregroundStyle(RidgitsColors.destructive)
                }
            }

            RidgitsTextField(
                placeholder: "What would I want to do on the weekend?",
                text: Binding(
                    get: { questions[index].question },
                    set: { questions[index].question = $0 }
                )
            )

            Picker("Options", selection: Binding(
                get: { questions[index].numOptions },
                set: { newValue in
                    var q = questions[index]
                    q.numOptions = newValue
                    while q.options.count < newValue { q.options.append("") }
                    questions[index] = q
                }
            )) {
                ForEach(2...5, id: \.self) { Text("\($0) options").tag($0) }
            }
            .pickerStyle(.menu)
            .font(RidgitsTypography.caption(12))

            ForEach(0..<questions[index].numOptions, id: \.self) { optionIndex in
                HStack(spacing: 8) {
                    Button {
                        questions[index].correctAnswer = optionIndex
                    } label: {
                        Image(systemName: questions[index].correctAnswer == optionIndex ? "star.fill" : "star")
                            .foregroundStyle(questions[index].correctAnswer == optionIndex ? RidgitsColors.textHeadline : RidgitsColors.textMuted)
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())

                    RidgitsTextField(
                        placeholder: "Option \(optionIndex + 1)",
                        text: Binding(
                            get: { questions[index].options.indices.contains(optionIndex) ? questions[index].options[optionIndex] : "" },
                            set: { newValue in
                                while questions[index].options.count <= optionIndex {
                                    questions[index].options.append("")
                                }
                                questions[index].options[optionIndex] = newValue
                            }
                        )
                    )
                }
            }
        }
        .padding(12)
        .background(RidgitsColors.feedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
    }

    @MainActor
    private func save() async {
        if existing == nil && !canCreateNew {
            onLimitReached()
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await RidgitsFirebaseClient.shared.saveRidgit(
                id: existing?.id,
                userId: uid,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                questions: questions,
                profile: profile,
                activeSlotLimit: existing == nil ? ridgitLimit : nil
            )
            await onSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RidgitPreviewCard: View {
    let profile: RidgitsUserProfile
    let title: String
    let questions: [RidgitQuestion]

    var body: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    previewImage
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name.isEmpty ? "Your Name" : profile.name)
                            .font(RidgitsTypography.label(15))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text(profile.location.isEmpty ? "Your City" : profile.location)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                }

                Text(title)
                    .font(RidgitsTypography.headline(16))
                    .foregroundStyle(RidgitsColors.textHeadline)

                if let first = questions.first(where: { !$0.question.isEmpty }) {
                    Text(first.question)
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    ForEach(Array(first.activeOptions.enumerated()), id: \.offset) { _, option in
                        Text(option.isEmpty ? "Option" : option)
                            .font(RidgitsTypography.caption(12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(RidgitsColors.feedBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                    .stroke(RidgitsColors.border, lineWidth: 1)
                            )
                    }
                }

                Text("Preview")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        Group {
            if let url = URL(string: profile.image), !profile.image.isEmpty {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Color(hex: 0xF5F5F5)
                    }
                }
            } else {
                Color(hex: 0xF5F5F5)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(RidgitsColors.textMuted))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.md).stroke(RidgitsColors.border, lineWidth: 1))
    }
}
