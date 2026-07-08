import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @State private var profile: RidgitsUserProfile
    @State private var interestDraft = ""
    @State private var isSaving = false
    @State private var profilePhotoMatchMessage: String?
    @State private var saveErrorMessage: String?
    @State private var nameValidationMessage: String?
    @State private var attemptedLastNameEntry = false
    @State private var showLastNameHeadsUp = false
    @State private var pendingSaveAfterHeadsUp = false

    var onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _profile = State(initialValue: RidgitsUserProfile.empty(uid: uid))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RidgitsSectionHeader(
                        title: "Your Profile",
                        subtitle: "Complete your profile to start matching"
                    )

                    RidgitsDashboardCard {
                        VStack(alignment: .leading, spacing: 14) {
                            field("First name", required: true) {
                                RidgitsTextField(
                                    placeholder: "First name only",
                                    text: firstNameBinding,
                                    textContentType: .givenName,
                                    textInputAutocapitalization: .words,
                                    autocorrectionDisabled: true
                                )

                                Text("Others only see your first name.")
                                    .font(RidgitsTypography.caption(12))
                                    .foregroundStyle(RidgitsColors.textMuted)

                                if let nameValidationMessage {
                                    Text(nameValidationMessage)
                                        .font(RidgitsTypography.caption(12))
                                        .foregroundStyle(RidgitsColors.destructive)
                                }
                            }
                            field("City & state", required: true) {
                                RidgitsLocationPicker(
                                    city: $profile.locationCity,
                                    stateCode: $profile.locationStateCode,
                                    legacyLocation: profile.location
                                )
                            }
                            field("Age", required: true) {
                                RidgitsTextField(
                                    placeholder: "Age",
                                    text: Binding(
                                        get: { profile.age.map(String.init) ?? "" },
                                        set: { profile.age = Int($0) }
                                    ),
                                    keyboard: .numberPad
                                )
                            }
                            field("Profile Photo", required: true) {
                                RidgitsProfilePhotoPicker(imageURL: $profile.image)
                            }
                            field("About", required: true) {
                                RidgitsTextField(placeholder: "About me", text: $profile.about, axis: .vertical, lineLimit: 3...5)
                            }
                            field("Aspirations", required: true) {
                                RidgitsTextField(placeholder: "What you're looking for", text: $profile.aspirations, axis: .vertical, lineLimit: 2...4)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                RidgitsFormStyle.fieldLabel("Interests", required: true)
                                HStack(spacing: 8) {
                                    RidgitsTextField(placeholder: "Add interest", text: $interestDraft)
                                    Button("Add") {
                                        addInterest()
                                    }
                                    .font(RidgitsTypography.label(12))
                                    .foregroundStyle(RidgitsColors.textHeadline)
                                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                                    .disabled(interestDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }

                                if profile.interests.isEmpty {
                                    Text("Add at least one interest to continue.")
                                        .font(RidgitsTypography.caption(12))
                                        .foregroundStyle(RidgitsColors.textMuted)
                                } else {
                                    ProfileSetupFlowLayout(spacing: 8) {
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
                                                .buttonStyle(RidgitsHapticPlainButtonStyle())
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
                            }

                            RidgitsSquareButton(title: isSaving ? "Saving…" : "Save & Continue", style: .filled) {
                                Task { await save() }
                            }
                            .disabled(!canCompleteSetup || isSaving)

                            if let saveErrorMessage {
                                Text(saveErrorMessage)
                                    .font(RidgitsTypography.caption(12))
                                    .foregroundStyle(RidgitsColors.destructive)
                            }

                            if let profilePhotoMatchMessage {
                                Text(profilePhotoMatchMessage)
                                    .font(RidgitsTypography.caption(12))
                                    .foregroundStyle(RidgitsColors.destructive)
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    RidgitsNavLogoView(
                        membershipTier: ridgitsStore.membershipTier,
                        isMembershipActive: ridgitsStore.isMembershipActive
                    )
                }
            }
            .task { await loadExisting() }
            .sheet(isPresented: $showLastNameHeadsUp, onDismiss: {
                guard pendingSaveAfterHeadsUp else { return }
                pendingSaveAfterHeadsUp = false
                attemptedLastNameEntry = false
                Task { await performSave() }
            }) {
                ProfileFirstNameHeadsUpSheet()
            }
        }
    }

    private var canCompleteSetup: Bool {
        profile.isCompleteForMatching && RidgitsDisplaySanitize.isValidProfileFirstName(profile.name)
    }

    private var firstNameBinding: Binding<String> {
        Binding(
            get: { profile.name },
            set: { newValue in
                let result = RidgitsDisplaySanitize.profileFirstNameInputFeedback(for: newValue)
                profile.name = result.sanitized
                nameValidationMessage = result.validationMessage
                if result.attemptedLastName {
                    attemptedLastNameEntry = true
                }
            }
        )
    }

    private func field<Content: View>(_ title: String, required: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RidgitsFormStyle.fieldLabel(title, required: required)
            content()
        }
    }

    private func loadExisting() async {
        guard let uid = authManager.currentUser?.uid else { return }
        let loaded = (try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)) ?? profile
        if loaded.name.contains(where: \.isWhitespace) {
            attemptedLastNameEntry = true
        }
        profile = loaded
        if !profile.name.isEmpty {
            profile.name = RidgitsDisplaySanitize.sanitizeProfileFirstNameInput(profile.name)
        }
    }

    private func save() async {
        profile.name = RidgitsDisplaySanitize.sanitizeProfileFirstNameInput(profile.name)
        guard RidgitsDisplaySanitize.isValidProfileFirstName(profile.name) else {
            nameValidationMessage = "Enter a valid first name to continue."
            return
        }
        if attemptedLastNameEntry {
            pendingSaveAfterHeadsUp = true
            showLastNameHeadsUp = true
            return
        }
        await performSave()
    }

    private func performSave() async {
        isSaving = true
        saveErrorMessage = nil
        profilePhotoMatchMessage = nil
        nameValidationMessage = nil
        defer { isSaving = false }
        do {
            let registerResult = try await RidgitsFirebaseClient.shared.saveUserProfile(profile)
            profilePhotoMatchMessage = await RidgitsProfilePhotoIdentityMatch.matchAfterProfileSaveIfNeeded(
                registerResult: registerResult
            )
            if profilePhotoMatchMessage == nil {
                onComplete()
            }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func addInterest() {
        let trimmed = interestDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let alreadyAdded = profile.interests.contains {
            $0.compare(trimmed, options: .caseInsensitive) == .orderedSame
        }
        guard !alreadyAdded else {
            interestDraft = ""
            return
        }
        profile.interests.append(trimmed)
        interestDraft = ""
        RidgitsHaptics.play(.light)
    }
}

private struct ProfileSetupFlowLayout: Layout {
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
