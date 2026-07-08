import SwiftUI

/// Heartbeat haptic loop for nearby sharing. The pulse tightens as the
/// handoff progresses (peer found → connecting → sending), approximating the
/// phones getting closer, then fires a success thud when the share lands.
@MainActor
private final class RidgitNearbyShareHaptics: ObservableObject {
    private var timer: Timer?
    private var currentInterval: TimeInterval = 0
    private var currentFeedback: RidgitsHaptics.Feedback = .soft
    private var didPlayTerminalFeedback = false

    func update(phase: RidgitSharePhase, peerCount: Int, isSender: Bool) {
        switch phase {
        case .idle:
            if isSender {
                startLoop(interval: 1.5, feedback: .soft)
            } else {
                stop()
            }

        case .searching:
            if peerCount > 0 {
                startLoop(interval: 0.9, feedback: .soft)
            } else {
                startLoop(interval: 1.5, feedback: .soft)
            }

        case .incomingInvite:
            startLoop(interval: 0.6, feedback: .light)

        case .inviting, .connecting:
            startLoop(interval: 0.45, feedback: .light)

        case .sending:
            startLoop(interval: 0.2, feedback: .medium)

        case .sent, .received:
            stop()
            playTerminalOnce(.success)

        case .failed:
            stop()
            playTerminalOnce(.error)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        currentInterval = 0
    }

    private func startLoop(interval: TimeInterval, feedback: RidgitsHaptics.Feedback) {
        didPlayTerminalFeedback = false
        guard timer == nil || currentInterval != interval || currentFeedback != feedback else { return }

        currentInterval = interval
        currentFeedback = feedback
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                RidgitsHaptics.play(feedback)
            }
        }
        RidgitsHaptics.play(feedback)
    }

    private func playTerminalOnce(_ feedback: RidgitsHaptics.Feedback) {
        guard !didPlayTerminalFeedback else { return }
        didPlayTerminalFeedback = true
        RidgitsHaptics.play(feedback)
    }

    deinit {
        timer?.invalidate()
    }
}

/// Full-screen sender/receiver overlay for nearby Ridgit sharing.
struct RidgitNearbyShareOverlay: View {
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var haptics = RidgitNearbyShareHaptics()

    let senderPayload: RidgitSharePayload?
    let onOpenRidgit: (String) -> Void
    var availablePayloads: [RidgitSharePayload] = []
    var onSelectPayload: ((RidgitSharePayload) -> Void)? = nil

    var body: some View {
        ZStack {
            RidgitsIntelligenceEdgeGlow()

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
        .onAppear { syncHaptics() }
        .onChange(of: nearbyPresence.sharePhase) { _, _ in syncHaptics() }
        .onChange(of: nearbyPresence.nearbyPeerCount) { _, _ in syncHaptics() }
        .onDisappear { haptics.stop() }
    }

    private func syncHaptics() {
        haptics.update(
            phase: nearbyPresence.sharePhase,
            peerCount: nearbyPresence.nearbyPeerCount,
            isSender: senderPayload != nil
        )
    }

    @ViewBuilder
    private var content: some View {
        switch nearbyPresence.sharePhase {
        case .idle:
            if senderPayload != nil {
                RidgitNearbyShareAnimationView(
                    mode: .searching,
                    title: "Bring phones together",
                    subtitle: "Looking for another Ridgits member nearby…",
                    profileName: senderPayload?.senderName,
                    profileImageURL: senderPayload?.senderImageUrl
                )
            }

        case .searching:
            RidgitNearbyShareAnimationView(
                mode: .searching,
                title: "Bring phones together",
                subtitle: subtitleForSearching,
                profileName: senderPayload?.senderName,
                profileImageURL: senderPayload?.senderImageUrl
            )

        case .inviting(let peerName), .connecting(let peerName):
            RidgitNearbyShareAnimationView(
                mode: .connecting,
                title: "Connecting with \(peerName)",
                subtitle: "Hold your phones close to share your Ridgit.",
                profileName: senderPayload?.senderName,
                profileImageURL: senderPayload?.senderImageUrl
            )

        case .sending:
            RidgitNearbyShareAnimationView(
                mode: .connecting,
                title: "Sending Ridgit…",
                subtitle: "Almost there.",
                profileName: senderPayload?.senderName,
                profileImageURL: senderPayload?.senderImageUrl
            )

        case .sent(let peerName):
            RidgitNearbyShareAnimationView(
                mode: .success,
                title: "Shared with \(peerName)",
                subtitle: "They can accept and take your quiz in Ridgits.",
                profileName: senderPayload?.senderName,
                profileImageURL: senderPayload?.senderImageUrl
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
            VStack(spacing: 16) {
                ridgitSelector

                if nearbyPresence.nearbyPeers.isEmpty {
                    Text("No one detected yet. Keep Ridgits open on both phones.")
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                } else {
                    peerPicker
                }
            }

        case .idle:
            if senderPayload != nil {
                ridgitSelector
            }

        default:
            EmptyView()
        }
    }

    /// Lets the sender switch which Ridgit gets shared before a connection
    /// starts, when they have more than one active Ridgit.
    @ViewBuilder
    private var ridgitSelector: some View {
        if availablePayloads.count > 1, let current = senderPayload {
            Menu {
                ForEach(availablePayloads) { option in
                    Button {
                        guard option.ridgitId != current.ridgitId else { return }
                        RidgitsHaptics.play(.selection)
                        onSelectPayload?(option)
                    } label: {
                        if option.ridgitId == current.ridgitId {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Sharing: \(current.title)")
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }
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
                subtitle: "Wants to share a Ridgit with you.",
                profileName: preview.senderName,
                profileImageURL: preview.senderImageUrl
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

/// Sender sheet launched from a Ridgit card. When the user has multiple
/// active Ridgits, they can switch which one to share while searching.
struct RidgitNearbyShareSenderSheet: View {
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @Environment(\.dismiss) private var dismiss

    let payload: RidgitSharePayload
    var availablePayloads: [RidgitSharePayload] = []
    let onOpenRidgit: (String) -> Void

    @State private var selectedPayload: RidgitSharePayload?

    private var currentPayload: RidgitSharePayload {
        selectedPayload ?? payload
    }

    var body: some View {
        RidgitNearbyShareOverlay(
            senderPayload: currentPayload,
            onOpenRidgit: onOpenRidgit,
            availablePayloads: availablePayloads.isEmpty ? [payload] : availablePayloads,
            onSelectPayload: { newPayload in
                selectedPayload = newPayload
                nearbyPresence.beginSharingRidgit(newPayload)
            }
        )
        .onAppear {
            nearbyPresence.beginSharingRidgit(currentPayload)
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
