import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var profile: RidgitsUserProfile
    @State private var interestDraft = ""
    @State private var isSaving = false
    @State private var profilePhotoMatchMessage: String?

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
                            field("Name", required: true) {
                                RidgitsTextField(placeholder: "Username", text: $profile.name)
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
                                HStack {
                                    RidgitsTextField(placeholder: "Add interest", text: $interestDraft)
                                    Button("Add") {
                                        let trimmed = interestDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !trimmed.isEmpty else { return }
                                        profile.interests.append(trimmed)
                                        interestDraft = ""
                                    }
                                    .font(RidgitsTypography.label(12))
                                }
                            }

                            RidgitsSquareButton(title: isSaving ? "Saving…" : "Save & Continue", style: .filled) {
                                Task { await save() }
                            }
                            .disabled(!profile.isCompleteForMatching || isSaving)

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
                    RidgitsLogoView.onLight(size: 22)
                }
            }
            .task { await loadExisting() }
        }
    }

    private func field<Content: View>(_ title: String, required: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RidgitsFormStyle.fieldLabel(title, required: required)
            content()
        }
    }

    private func loadExisting() async {
        guard let uid = authManager.currentUser?.uid else { return }
        profile = (try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)) ?? profile
    }

    private func save() async {
        isSaving = true
        profilePhotoMatchMessage = nil
        defer { isSaving = false }
        do {
            try await RidgitsFirebaseClient.shared.saveUserProfile(profile)
            profilePhotoMatchMessage = await RidgitsProfilePhotoIdentityMatch.matchAfterProfileSaveIfNeeded()
            if profilePhotoMatchMessage == nil {
                onComplete()
            }
        } catch {}
    }
}
