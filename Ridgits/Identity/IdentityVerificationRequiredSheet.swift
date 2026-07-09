import SwiftUI

enum IdentityVerificationMessagingGate: Identifiable {
    case requiredPrompt
    case verificationFlow

    var id: String {
        switch self {
        case .requiredPrompt: return "requiredPrompt"
        case .verificationFlow: return "verificationFlow"
        }
    }
}

struct IdentityVerificationRequiredSheet: View {
    var onVerify: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Verify before messaging")
                .font(RidgitsTypography.headline(22))
                .foregroundStyle(RidgitsColors.textHeadline)

            Text("You need to verify your identity before you can send or accept messages. Your subscription badge stays active either way.")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("We verify your government ID, phone number, and a quick selfie. Add a profile photo on your profile before you start.")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            RidgitsPrimaryButton(title: "Verify identity", action: onVerify)
                .padding(.top, 4)

            Button("Not now", action: onCancel)
                .font(RidgitsTypography.label(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RidgitsColors.feedBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private struct IdentityVerificationMessagingGateSheet: ViewModifier {
    @Binding var gate: IdentityVerificationMessagingGate?
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    func body(content: Content) -> some View {
        content
            .sheet(item: $gate) { presentation in
                switch presentation {
                case .requiredPrompt:
                    IdentityVerificationRequiredSheet(
                        onVerify: { gate = .verificationFlow },
                        onCancel: { gate = nil }
                    )
                case .verificationFlow:
                    IdentityVerificationView(autoStart: true) { success in
                        gate = nil
                        if success {
                            Task { await ridgitsStore.refreshAccessInBackground() }
                        }
                    }
                    .environmentObject(ridgitsStore)
                }
            }
    }
}

extension View {
    func identityVerificationMessagingGate(_ gate: Binding<IdentityVerificationMessagingGate?>) -> some View {
        modifier(IdentityVerificationMessagingGateSheet(gate: gate))
    }
}
