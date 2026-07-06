import SwiftUI

/// Sheet to send the first message in a new conversation (from Matches or after accepting a poke).
struct StartConversationSheet: View {
    let match: RidgitsMatch
    @Binding var messageText: String
    var onSend: () async -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(RidgitsColors.textMuted.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button("Cancel", action: onCancel)
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    VStack(spacing: 12) {
                        RidgitsCachedProfileImage(remoteURL: match.image.isEmpty ? nil : match.image) {
                            RidgitsColors.border
                        }
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(RidgitsColors.border, lineWidth: 1))

                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Text("Message \(match.displayFirstName)")
                                    .font(RidgitsTypography.headline(22))
                                    .foregroundStyle(RidgitsColors.textHeadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                RidgitsProfileTrustBadges(
                                    subscriptionTier: match.subscriptionTier,
                                    profilePhotoVerified: match.isProfilePhotoVerified,
                                    badgeSize: 16
                                )
                            }

                            Text("Once they accept, you have 24 hours and 16 messages total.")
                                .font(RidgitsTypography.body(14))
                                .foregroundStyle(RidgitsColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    RidgitsMultilineTextEditor(
                        text: $messageText,
                        placeholder: "Say something to start the conversation…"
                    )

                    RidgitsPrimaryButton(
                        title: "Send request",
                        isDisabled: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        Task { await onSend() }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(RidgitsColors.feedBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}
