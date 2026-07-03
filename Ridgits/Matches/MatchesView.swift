import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var nearbyMatches: [RidgitsMatch] = []
    @Published var nationwideMatches: [RidgitsMatch] = []
    @Published var maxDistance = 25
    @Published var isLoading = false
    @Published var errorMessage: String?

    var nearbyAvailableCount: Int { nearbyMatches.count }

    func load(hasNearbyAccess: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            nationwideMatches = try await RidgitsFirebaseClient.shared.getTopNationwideMatches(limit: 10)
            nearbyMatches = try await RidgitsFirebaseClient.shared.findMatches(maxDistance: maxDistance)
        } catch {
            errorMessage = error.localizedDescription
            if !hasNearbyAccess {
                nearbyMatches = []
            }
        }
    }

    func sendPoke(to match: RidgitsMatch) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await Firestore.firestore().collection("pokes").addDocument(data: [
            "fromUserId": uid,
            "toUserId": match.userId,
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }
}

struct MatchesView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @StateObject private var viewModel = MatchesViewModel()
    @State private var showPaywall = false
    @State private var composeMatch: RidgitsMatch?
    @State private var composeMessage = ""

    private var nearbyPeopleAvailable: Bool {
        viewModel.nearbyAvailableCount > 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                nearbySection
                RidgitsSectionHeader(title: "Top nationwide", subtitle: "Preview compatibility scores")
                matchSection(viewModel.nationwideMatches, locked: false, allowInteraction: true)
            }
            .padding(20)
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle("Matches")
        .refreshable {
            await viewModel.load(hasNearbyAccess: ridgitsStore.hasNearbyAccess)
        }
        .task {
            await viewModel.load(hasNearbyAccess: ridgitsStore.hasNearbyAccess)
        }
        .onChange(of: ridgitsStore.hasNearbyAccess) { _, hasAccess in
            Task { await viewModel.load(hasNearbyAccess: hasAccess) }
        }
        .sheet(isPresented: $showPaywall) {
            NearbyPaywallView(nearbyCount: viewModel.nearbyAvailableCount, radiusMiles: viewModel.maxDistance)
        }
        .sheet(item: $composeMatch) { match in
            composeSheet(for: match)
        }
    }

    @ViewBuilder
    private var nearbySection: some View {
        RidgitsSectionHeader(
            title: "Nearby",
            subtitle: ridgitsStore.hasNearbyAccess
                ? "Within \(viewModel.maxDistance) miles"
                : nearbyPeopleAvailable
                    ? "\(viewModel.nearbyAvailableCount) people within \(viewModel.maxDistance) miles"
                    : "Checking who's close to you"
        )

        if ridgitsStore.hasNearbyAccess {
            distanceSlider
            matchSection(viewModel.nearbyMatches, locked: false, allowInteraction: true)
        } else if viewModel.isLoading {
            ProgressView().padding(.vertical, 12)
        } else if nearbyPeopleAvailable {
            nearbyUnlockCard
            matchSection(Array(viewModel.nearbyMatches.prefix(3)), locked: true, allowInteraction: false)
        } else {
            noNearbyCard
        }
    }

    private var distanceSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Radius: \(viewModel.maxDistance) mi")
                .font(RidgitsTypography.label())
            Slider(value: Binding(
                get: { Double(viewModel.maxDistance) },
                set: { viewModel.maxDistance = Int($0) }
            ), in: 5...100, step: 5)
            .tint(RidgitsColors.ctaBlack)
            .onChange(of: viewModel.maxDistance) { _, _ in
                Task { await viewModel.load(hasNearbyAccess: ridgitsStore.hasNearbyAccess) }
            }
        }
        .padding(16)
        .background(RidgitsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.lg).stroke(RidgitsColors.border, lineWidth: 1))
    }

    private var nearbyUnlockCard: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: 0x059669))
                        .frame(width: 8, height: 8)
                    Text("\(viewModel.nearbyAvailableCount) compatible \(viewModel.nearbyAvailableCount == 1 ? "person" : "people") within \(viewModel.maxDistance) miles")
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                Text("Unlock nearby matches")
                    .font(RidgitsTypography.headline())
                Text("Get 12 months of local discovery for \(ridgitsStore.yearlyPriceLine).")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                RidgitsPrimaryButton(title: "See who's near you — \(ridgitsStore.yearlyPriceLine)") {
                    showPaywall = true
                }
            }
        }
    }

    private var noNearbyCard: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No one nearby yet")
                    .font(RidgitsTypography.headline())
                Text("There aren't compatible people within \(viewModel.maxDistance) miles right now. Check back later or browse nationwide matches below.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }

    private func matchSection(_ matches: [RidgitsMatch], locked: Bool, allowInteraction: Bool) -> some View {
        VStack(spacing: 12) {
            if viewModel.isLoading && matches.isEmpty {
                ProgressView().padding()
            } else if matches.isEmpty {
                Text("No matches yet — finish your quiz and profile.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(matches) { match in
                    MatchCard(match: match, locked: locked) {
                        guard allowInteraction else {
                            if nearbyPeopleAvailable { showPaywall = true }
                            return
                        }
                        composeMatch = match
                    } onPoke: {
                        guard allowInteraction else {
                            if nearbyPeopleAvailable { showPaywall = true }
                            return
                        }
                        Task { await viewModel.sendPoke(to: match) }
                    }
                }
            }
        }
    }

    private func composeSheet(for match: RidgitsMatch) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Message \(match.name)")
                    .font(RidgitsTypography.headline())
                Text("Once they accept, you have 24 hours and 16 messages total.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                TextEditor(text: $composeMessage)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(RidgitsColors.inputSurface)
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.md).stroke(RidgitsColors.inputBorder, lineWidth: 1))
                RidgitsPrimaryButton(title: "Send request", isDisabled: composeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    Task {
                        _ = try? await RidgitsFirebaseClient.shared.startConversation(
                            toUserId: match.userId,
                            message: composeMessage
                        )
                        composeMessage = ""
                        composeMatch = nil
                    }
                }
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { composeMatch = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct MatchCard: View {
    let match: RidgitsMatch
    let locked: Bool
    let onMessage: () -> Void
    let onPoke: () -> Void

    var body: some View {
        RidgitsCard {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: match.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        RidgitsColors.border
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(locked ? "Someone nearby" : match.name)
                            .font(RidgitsTypography.headline(16))
                        Spacer()
                        RidgitsCompatibilityBadge(percent: match.compatibility.overall)
                    }
                    if let miles = match.distanceMiles {
                        Text(String(format: "%.0f mi away · %@", miles, locked ? "Unlock to view" : match.location))
                            .font(RidgitsTypography.caption())
                            .foregroundStyle(RidgitsColors.textSecondary)
                    } else if !locked {
                        Text(match.location)
                            .font(RidgitsTypography.caption())
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    if let about = match.about, !locked {
                        Text(about)
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 8) {
                        Button("Message", action: onMessage)
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RidgitsColors.ctaBlack)
                            .clipShape(Capsule())
                        Button("Poke", action: onPoke)
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(RidgitsColors.border, lineWidth: 1))
                    }
                    .padding(.top, 4)
                    .blur(radius: locked ? 6 : 0)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if locked { onMessage() } }
    }
}
