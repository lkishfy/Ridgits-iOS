import SwiftUI
import FirebaseAuth

struct CompareProfilesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var compareCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var result: CompareProfilesResult?

    var body: some View {
        NavigationStack {
            Group {
                if let result {
                    comparisonResults(result)
                } else {
                    compareForm
                }
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle("Compare Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(result == nil ? "Cancel" : "Back") {
                        if result != nil {
                            result = nil
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
        }
    }

    private var compareForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter another user's profile code to see how compatible you are.")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)

            TextField("Profile code", text: $compareCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(RidgitsTypography.mono(18))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )

            if let errorMessage {
                Text(errorMessage)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.destructive)
            }

            RidgitsSquareButton(
                title: isLoading ? "Comparing…" : "Compare",
                style: .filled
            ) {
                Task { await compare() }
            }
            .disabled(isLoading || compareCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 7)

            Spacer()
        }
        .padding(20)
    }

    private func comparisonResults(_ result: CompareProfilesResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Text("OVERALL COMPATIBILITY")
                        .font(RidgitsTypography.sectionLabel(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .tracking(0.8)
                    Text("\(result.scores.overall)%")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text("with \(result.otherArchetypeName)")
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RidgitsColors.ctaBlack)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

                RidgitsDashboardCard {
                    VStack(alignment: .leading, spacing: 14) {
                        dimensionRow("Communication", result.scores.communication)
                        dimensionRow("Intimacy", result.scores.intimacy)
                        dimensionRow("Values", result.scores.values)
                        dimensionRow("Social", result.scores.social)
                        dimensionRow("Commitment", result.scores.commitment)
                    }
                    .padding(16)
                }
            }
            .padding(16)
        }
    }

    private func dimensionRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textHeadline)
            Spacer()
            Text("\(value)%")
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
    }

    @MainActor
    private func compare() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let code = compareCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count >= 7 else {
            errorMessage = "Enter a valid profile code."
            return
        }

        do {
            guard let otherUserId = await RidgitsFirebaseClient.shared.fetchUserId(forProfileCode: code) else {
                errorMessage = "Profile code not found."
                return
            }

            guard let myProgress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid),
                  myProgress.completed else {
                errorMessage = "Complete your quiz first."
                return
            }

            guard let otherProgress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: otherUserId),
                  otherProgress.completed else {
                errorMessage = "This user has not completed their quiz yet."
                return
            }

            let otherArchetype = await RidgitsFirebaseClient.shared.fetchQuizArchetype(uid: otherUserId)
            let scores = RidgitsQuizCompatibility.calculate(
                RidgitsQuizCompatibility.input(from: myProgress),
                RidgitsQuizCompatibility.input(from: otherProgress)
            )

            result = CompareProfilesResult(
                otherArchetypeName: otherArchetype?.name ?? "Another user",
                scores: scores
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CompareProfilesResult {
    let otherArchetypeName: String
    let scores: RidgitsCompatibilityScores
}
