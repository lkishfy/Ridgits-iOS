import SwiftUI
import PhotosUI
import FirebaseAuth

struct CompatibilityReadoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    @State private var partnerName = ""
    @State private var contextText = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var profile = RidgitsUserProfile.empty(uid: "")
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var result: RidgitsCompatibilityReadout?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RidgitsQuickToolHeader(
                        title: "Compatibility Readout",
                        subtitle: "Add context and photos to see how compatible you might be before you meet."
                    )

                    privacyDisclaimer

                    if let result {
                        resultsSection(result)
                    } else {
                        inputSection
                    }
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(RidgitsTypography.label(12))
                }
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(preferredBilling: .yearly)
            }
            .task { await loadProfile() }
            .onChange(of: selectedItems) { _, items in
                Task {
                    selectedImageData = await RidgitsQuickToolsImageLoader.jpegData(from: items, limit: 4)
                    if items.count > 4 {
                        errorMessage = "Maximum 4 images allowed."
                    } else if errorMessage == "Maximum 4 images allowed." {
                        errorMessage = nil
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldBlock("Their Name (optional)") {
                RidgitsTextField(placeholder: "e.g., Taylor", text: $partnerName)
            }

            fieldBlock("Context", required: true) {
                RidgitsTextField(
                    placeholder: "Describe what you know from messages, bio, dates, lifestyle, communication style…",
                    text: $contextText,
                    axis: .vertical,
                    lineLimit: 4...8
                )
                Text("The more context you add, the more accurate your compatibility breakdown will be.")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
            }

            VStack(alignment: .leading, spacing: 8) {
                RidgitsFormStyle.fieldLabel("Supporting Images", required: selectedImageData.isEmpty && !hasProfileFallbackImages)
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 4, matching: .images) {
                    uploadDropZone(
                        count: selectedImageData.count,
                        emptyLabel: "Add up to 4 images",
                        detail: "Screenshots of profile, messages, texts, etc."
                    )
                }
                .disabled(isLoading)

                if hasProfileFallbackImages && selectedImageData.isEmpty {
                    Text("No uploads yet — we'll use \(profileImageURLs.count) photo\(profileImageURLs.count == 1 ? "" : "s") from your Ridgits profile.")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }

            RidgitsPrimaryButton(
                title: isLoading ? "Generating…" : "Generate Readout",
                isLoading: isLoading,
                isDisabled: contextText.trimmingCharacters(in: .whitespacesAndNewlines).count < 20
            ) {
                Task { await generateReadout() }
            }

            if let errorMessage {
                errorBanner(errorMessage)
            }
        }
    }

    private var privacyDisclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 14))
                .foregroundStyle(RidgitsColors.textMuted)
            Text("Your images are deleted after analysis is complete for privacy purposes.")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
        .padding(12)
        .background(RidgitsColors.hoverSurface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }

    private var hasProfileFallbackImages: Bool {
        !profileImageURLs.isEmpty
    }

    private var profileImageURLs: [String] {
        var urls: [String] = []
        if !profile.image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            urls.append(profile.image)
        }
        urls.append(contentsOf: profile.additionalImages.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })
        return Array(urls.prefix(4))
    }

    private func resultsSection(_ result: RidgitsCompatibilityReadout) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(result.matchName)
                    .font(RidgitsTypography.headline(20))
                    .foregroundStyle(RidgitsColors.textHeadline)
                if !result.archetypeName.isEmpty {
                    Text(result.archetypeName)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                if !result.about.isEmpty {
                    Text(result.about)
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .lineSpacing(3)
                }
            }

            HStack(spacing: 12) {
                RidgitsCompatibilityBadge(percent: result.compatibility.overall)
                Text("Overall compatibility")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }

            compatibilityBars(result.compatibility)

            if !result.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INTERESTS")
                        .font(RidgitsTypography.sectionLabel(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    Text(result.interests.joined(separator: " · "))
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }

            if let summary = result.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUMMARY")
                        .font(RidgitsTypography.sectionLabel(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    Text(summary)
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .lineSpacing(4)
                }
            }

            if result.isLocked {
                lockedExtras(result)
                lockedCTA
            } else if !result.dealbreakerQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUESTIONS TO ASK")
                        .font(RidgitsTypography.sectionLabel(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    ForEach(Array(result.dealbreakerQuestions.enumerated()), id: \.offset) { index, question in
                        Text("\(index + 1). \(question)")
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .lineSpacing(3)
                    }
                }

                RidgitsSquareButton(title: "Generate Again", style: .filled) {
                    reset()
                }
            }
        }
        .padding(16)
        .background(RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
        )
    }

    private func compatibilityBars(_ compatibility: RidgitsCompatibility) -> some View {
        VStack(spacing: 10) {
            compatibilityRow("Communication", compatibility.communication)
            compatibilityRow("Intimacy", compatibility.intimacy)
            compatibilityRow("Values", compatibility.values)
            compatibilityRow("Social", compatibility.social)
            compatibilityRow("Commitment", compatibility.commitment)
        }
    }

    private func compatibilityRow(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(width: 96, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(RidgitsColors.hoverSurface)
                    Capsule()
                        .fill(RidgitsColors.ctaBlack)
                        .frame(width: geo.size.width * CGFloat(max(0, min(100, value))) / 100)
                }
            }
            .frame(height: 8)
            Text("\(value)%")
                .font(RidgitsTypography.label(12))
                .foregroundStyle(RidgitsColors.textHeadline)
                .frame(width: 36, alignment: .trailing)
        }
        .frame(height: 16)
    }

    private func lockedExtras(_ result: RidgitsCompatibilityReadout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let topics = result.lockedConversationTopicsCount, topics > 0 {
                Text("\(topics) conversation topic\(topics == 1 ? "" : "s") available with Ridgits+")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
            if let questions = result.lockedDealbreakerQuestionsCount, questions > 0 {
                Text("\(questions) follow-up question\(questions == 1 ? "" : "s") available with Ridgits+")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
        }
    }

    private var lockedCTA: some View {
        VStack(spacing: 12) {
            Text("Unlock full readout")
                .font(RidgitsTypography.label(15))
                .foregroundStyle(RidgitsColors.textHeadline)
            RidgitsSquareButton(title: "Unlock with Ridgits+", style: .filled) {
                showPaywall = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func fieldBlock<Content: View>(_ title: String, required: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RidgitsFormStyle.fieldLabel(title, required: required)
            content()
        }
    }

    @MainActor
    private func loadProfile() async {
        guard let uid = authManager.currentUser?.uid else { return }
        profile = (try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid))
            ?? RidgitsUserProfile.empty(uid: uid)
    }

    @MainActor
    private func generateReadout() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedContext = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedContext.count >= 20 else {
            errorMessage = "Please provide at least a few sentences of context."
            return
        }

        let imageURLs: [String]
        if selectedImageData.isEmpty {
            imageURLs = profileImageURLs
        } else {
            guard selectedImageData.count <= 4 else {
                errorMessage = "Maximum 4 images allowed."
                return
            }
            do {
                imageURLs = try await RidgitsQuickToolsService.shared.uploadImages(
                    selectedImageData,
                    folder: "vibe_context"
                )
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        guard !imageURLs.isEmpty else {
            errorMessage = "Please upload at least one photo or add photos to your profile."
            return
        }
        guard ridgitsStore.hasPlusMembership else {
            showPaywall = true
            return
        }

        do {
            result = try await RidgitsQuickToolsService.shared.analyzeCompatibilityContext(
                contextText: trimmedContext,
                partnerName: partnerName.isEmpty ? nil : partnerName,
                imageURLs: imageURLs
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reset() {
        result = nil
        selectedItems = []
        selectedImageData = []
        errorMessage = nil
    }
}

private func uploadDropZone(count: Int, emptyLabel: String, detail: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 28))
            .foregroundStyle(RidgitsColors.textMuted)
        Text(count > 0 ? "\(count) image\(count == 1 ? "" : "s") selected" : emptyLabel)
            .font(RidgitsTypography.label(14))
            .foregroundStyle(RidgitsColors.textHeadline)
        Text(detail)
            .font(RidgitsTypography.caption(11))
            .foregroundStyle(RidgitsColors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 28)
    .background(RidgitsColors.surface)
    .overlay(
        RoundedRectangle(cornerRadius: RidgitsRadius.lg)
            .stroke(RidgitsColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
    )
}

private func errorBanner(_ message: String) -> some View {
    Text(message)
        .font(RidgitsTypography.caption(12))
        .foregroundStyle(RidgitsColors.destructive)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RidgitsColors.destructive.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
}
