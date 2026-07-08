import SwiftUI

struct ProfileFirstNameHeadsUpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("No need for a last name")
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)

                Text("Just a heads up — others only see your first name on Ridgits.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                RidgitsPrimaryButton(title: "Got it") {
                    dismiss()
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
