import Foundation
import FirebaseFirestore

struct CommunityQuizStats: Equatable {
    var totalCompleted: Int = 0
    var completedThisWeek: Int = 0
}

@MainActor
final class CommunityStatsViewModel: ObservableObject {
    @Published private(set) var stats = CommunityQuizStats()
    @Published private(set) var isLoading = true

    private var listener: ListenerRegistration?

    func startListening() {
        guard listener == nil else { return }
        isLoading = true
        listener = RidgitsFirebaseClient.shared.listenCommunityQuizStats { [weak self] stats in
            Task { @MainActor in
                self?.stats = stats
                self?.isLoading = false
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
