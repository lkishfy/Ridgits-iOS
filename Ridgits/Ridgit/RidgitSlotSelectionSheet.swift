import SwiftUI

/// Blocking sheet when a downgrade (or expired membership) leaves more Ridgits than the tier allows active.
struct RidgitSlotSelectionSheet: View {
    let ridgits: [RidgitChallenge]
    let slotLimit: Int
    let tierName: String
    let onConfirm: ([String]) async -> Void

    @State private var selectedIds: Set<String> = []
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your \(tierName) plan includes \(slotLimit) active \(slotLimit == 1 ? "Ridgit" : "Ridgits"). Choose which to keep. The rest stay saved but greyed out — you can delete them or upgrade to use them again.")
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(selectedIds.count) of \(slotLimit) selected")
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(RidgitsColors.textHeadline)

                    ForEach(ridgits) { ridgit in
                        selectionRow(ridgit)
                    }

                    RidgitsPrimaryButton(
                        title: isSaving ? "Saving…" : "Keep selected Ridgits",
                        isDisabled: selectedIds.count != slotLimit || isSaving
                    ) {
                        Task {
                            isSaving = true
                            defer { isSaving = false }
                            await onConfirm(Array(selectedIds))
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle("Choose your Ridgits")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            if selectedIds.isEmpty {
                selectedIds = Set(RidgitSlotManager.defaultActiveIds(from: ridgits, limit: slotLimit))
            }
        }
    }

    private func selectionRow(_ ridgit: RidgitChallenge) -> some View {
        let isSelected = selectedIds.contains(ridgit.id)
        return Button {
            toggle(ridgit.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? RidgitsColors.ctaBlack : RidgitsColors.textMuted)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ridgit.title)
                        .font(RidgitsTypography.label(15))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .lineLimit(1)
                    Text("\(ridgit.questions.count) question\(ridgit.questions.count == 1 ? "" : "s")")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(isSelected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    private func toggle(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if selectedIds.count < slotLimit {
            selectedIds.insert(id)
        }
    }
}
