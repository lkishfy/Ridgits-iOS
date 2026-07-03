import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var profile: RidgitsUserProfile
    @State private var interestDraft = ""
    @State private var isSaving = false

    var onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _profile = State(initialValue: RidgitsUserProfile(
            id: uid, name: "", location: "", age: nil, image: "",
            about: "", interests: [], aspirations: "", additionalImages: []
        ))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $profile.name)
                    TextField("City", text: $profile.location)
                    TextField("Age", value: $profile.age, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Photo URL", text: $profile.image)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section("About") {
                    TextField("About me", text: $profile.about, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Aspirations", text: $profile.aspirations, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Interests") {
                    HStack {
                        TextField("Add interest", text: $interestDraft)
                        Button("Add") {
                            let trimmed = interestDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            profile.interests.append(trimmed)
                            interestDraft = ""
                        }
                    }
                    ForEach(profile.interests, id: \.self) { interest in
                        Text(interest)
                    }
                }
            }
            .navigationTitle("Your profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!profile.isCompleteForMatching || isSaving)
                }
            }
            .task { await loadExisting() }
        }
    }

    private func loadExisting() async {
        guard let uid = authManager.currentUser?.uid else { return }
        profile = (try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)) ?? profile
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await RidgitsFirebaseClient.shared.saveUserProfile(profile)
            onComplete()
        } catch {}
    }
}
