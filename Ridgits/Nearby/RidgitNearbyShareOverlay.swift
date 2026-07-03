import SwiftUI

/// Full-screen sender/receiver overlay for nearby Ridgit sharing.
struct RidgitNearbyShareOverlay: View {
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @Environment(\.dismiss) private var dismiss

    let senderPayload: RidgitSharePayload?
    let onOpenRidgit: (String) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x111827), Color(hex: 0x1F2937), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        nearbyPresence.cancelShareFlow()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                content

                Spacer()

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
        .interactiveDismissDisabled(isBusy)
    }

    @ViewBuilder
    private var content: some View {
        switch nearbyPresence.sharePhase {
        case .idle:
            if senderPayload != nil {
                RidgitNearbyShareAnimationView(
                    mode: .searching,
                    title: "Bring phones together",
                    subtitle: "Looking for another Ridgits member nearby…"
                )
            }

        case .searching:
            RidgitNearbyShareAnimationView(
                mode: .searching,
                title: "Bring phones together",
                subtitle: subtitleForSearching
            )

        case .inviting(let peerName), .connecting(let peerName):
            RidgitNearbyShareAnimationView(
                mode: .connecting,
                title: "Connecting with \(peerName)",
                subtitle: "Hold your phones close to share your Ridgit."
            )

        case .sending:
            RidgitNearbyShareAnimationView(
                mode: .connecting,
                title: "Sending Ridgit…",
                subtitle: "Almost there."
            )

        case .sent(let peerName):
            RidgitNearbyShareAnimationView(
                mode: .success,
                title: "Shared with \(peerName)",
                subtitle: "They can accept and take your quiz in Ridgits."
            )

        case .incomingInvite(let preview), .received(let preview):
            incomingView(preview: preview)

        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                Text("Couldn’t share nearby")
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(.white)
                Text(message)
                    .font(RidgitsTypography.body(15))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch nearbyPresence.sharePhase {
        case .incomingInvite:
            HStack(spacing: 12) {
                Button("Not now") {
                    nearbyPresence.declinePendingShareInvitation()
                    dismiss()
                }
                .font(RidgitsTypography.label(15))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

                Button("Accept") {
                    nearbyPresence.acceptPendingShareInvitation()
                }
                .font(RidgitsTypography.label(15))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            }

        case .received(let preview):
            VStack(spacing: 12) {
                Button("Open Ridgit") {
                    onOpenRidgit(preview.ridgitId)
                    nearbyPresence.clearReceivedShare()
                    dismiss()
                }
                .font(RidgitsTypography.label(15))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

                Button("Dismiss") {
                    nearbyPresence.clearReceivedShare()
                    dismiss()
                }
                .font(RidgitsTypography.label(14))
                .foregroundStyle(.white.opacity(0.75))
            }

        case .sent:
            Button("Done") {
                nearbyPresence.cancelShareFlow()
                dismiss()
            }
            .font(RidgitsTypography.label(15))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

        case .failed:
            Button("Close") {
                nearbyPresence.cancelShareFlow()
                dismiss()
            }
            .font(RidgitsTypography.label(15))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

        case .searching:
            if nearbyPresence.nearbyPeers.isEmpty {
                Text("No one detected yet. Keep Ridgits open on both phones.")
                    .font(RidgitsTypography.caption(13))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            } else {
                peerPicker
            }

        default:
            EmptyView()
        }
    }

    private var peerPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nearby Ridgits members")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(Color.white.opacity(0.65))
            ForEach(nearbyPresence.nearbyPeers) { peer in
                Button {
                    nearbyPresence.invitePeer(id: peer.id)
                } label: {
                    HStack {
                        Text(peer.displayName)
                            .font(RidgitsTypography.label(15))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }
        }
    }

    private func incomingView(preview: RidgitSharePayload) -> some View {
        VStack(spacing: 24) {
            RidgitNearbyShareAnimationView(
                mode: .connecting,
                title: "\(preview.senderName) is nearby",
                subtitle: "Wants to share a Ridgit with you."
            )

            VStack(spacing: 8) {
                Text(preview.title)
                    .font(RidgitsTypography.headline(20))
                    .foregroundStyle(.white)
                if let question = preview.previewQuestion {
                    Text(question)
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private var subtitleForSearching: String {
        if nearbyPresence.nearbyPeers.isEmpty {
            return "Make sure the other person has Ridgits open nearby."
        }
        return "Tap someone below or hold your phones together."
    }

    private var isBusy: Bool {
        switch nearbyPresence.sharePhase {
        case .inviting, .connecting, .sending:
            return true
        default:
            return false
        }
    }
}

/// Sender sheet launched from a Ridgit card.
struct RidgitNearbyShareSenderSheet: View {
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @Environment(\.dismiss) private var dismiss

    let payload: RidgitSharePayload
    let onOpenRidgit: (String) -> Void

    var body: some View {
        RidgitNearbyShareOverlay(senderPayload: payload, onOpenRidgit: onOpenRidgit)
            .onAppear {
                nearbyPresence.beginSharingRidgit(payload)
            }
            .onDisappear {
                nearbyPresence.cancelShareFlow()
            }
    }
}

/// Global receiver overlay shown from the app shell.
struct RidgitNearbyShareReceiverOverlay: View {
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService

    let onOpenRidgit: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        RidgitNearbyShareOverlay(senderPayload: nil, onOpenRidgit: onOpenRidgit)
            .onDisappear(perform: onDismiss)
    }
}
