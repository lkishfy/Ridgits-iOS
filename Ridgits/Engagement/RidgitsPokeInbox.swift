import Foundation
import FirebaseFirestore

struct RidgitsPoke: Identifiable, Equatable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromName: String
    let createdAt: Date?
    let seen: Bool
    let profileVisited: Bool

    var isActionable: Bool {
        !seen || !profileVisited
    }

    static func from(id: String, data: [String: Any]) -> RidgitsPoke? {
        guard let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String else { return nil }
        return RidgitsPoke(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            fromName: data["fromName"] as? String ?? "Someone nearby",
            createdAt: (data["createdAt"] as? Timestamp)?.ridgitsDate,
            seen: data["seen"] as? Bool ?? false,
            profileVisited: data["profileVisited"] as? Bool ?? false
        )
    }
}

@MainActor
final class RidgitsPokeInbox: ObservableObject {
    @Published private(set) var receivedPokes: [RidgitsPoke] = []
    @Published private(set) var sentPokeIdsByUser: [String: String] = [:]

    var unseenCount: Int {
        receivedPokes.filter(\.isActionable).count
    }

    private var receivedListener: ListenerRegistration?
    private var sentListener: ListenerRegistration?

    func startListening(userId: String) {
        stopListening()
        let db = Firestore.firestore()

        receivedListener = db.collection("pokes")
            .whereField("toUserId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                Task { @MainActor in
                    self.receivedPokes = snapshot?.documents.compactMap {
                        RidgitsPoke.from(id: $0.documentID, data: $0.data())
                    } ?? []
                }
            }

        sentListener = db.collection("pokes")
            .whereField("fromUserId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                Task { @MainActor in
                    var map: [String: String] = [:]
                    snapshot?.documents.forEach { doc in
                        if let toUserId = doc.data()["toUserId"] as? String {
                            map[toUserId] = doc.documentID
                        }
                    }
                    self.sentPokeIdsByUser = map
                }
            }
    }

    func stopListening() {
        receivedListener?.remove()
        sentListener?.remove()
        receivedListener = nil
        sentListener = nil
        receivedPokes = []
        sentPokeIdsByUser = [:]
    }
}
