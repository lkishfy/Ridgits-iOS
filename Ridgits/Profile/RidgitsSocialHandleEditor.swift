import SwiftUI

struct RidgitsSocialHandleEditor: View {
    @Binding var platform: RidgitsSocialPlatform?
    @Binding var handle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick one channel")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textMuted)

            HStack(spacing: 8) {
                ForEach(RidgitsSocialPlatform.allCases, id: \.self) { option in
                    platformButton(option)
                }
            }

            if platform != nil || !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if platform == nil {
                    Text("Choose Instagram or TikTok to save your handle.")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)
                }
                RidgitsTextField(
                    placeholder: platform == .instagram ? "@instagram" : (platform == .tiktok ? "@tiktok" : "@username"),
                    text: $handle
                )
            }
        }
    }

    private func platformButton(_ option: RidgitsSocialPlatform) -> some View {
        let isSelected = platform == option
        return Button {
            if isSelected {
                platform = nil
                handle = ""
            } else {
                platform = option
            }
            RidgitsHaptics.play(.light)
        } label: {
            Text(option.displayName)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(isSelected ? Color.white : RidgitsColors.textHeadline)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? RidgitsColors.ctaBlack : RidgitsColors.hoverSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                        .stroke(isSelected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }
}
