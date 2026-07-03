import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RidgitsFirebaseClient {
    static let shared = RidgitsFirebaseClient()

    private let db = Firestore.firestore()
    private let api = RidgitsAPIClient.shared

    private init() {}

    func fetchUserProfile(uid: String) async throws -> RidgitsUserProfile {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data() else {
            return RidgitsUserProfile(
                id: uid, name: "", location: "", age: nil, image: "",
                about: "", interests: [], aspirations: "", additionalImages: []
            )
        }
        return RidgitsUserProfile.from(uid: uid, data: data)
    }

    func saveUserProfile(_ profile: RidgitsUserProfile) async throws {
        let payload: [String: Any] = [
            "name": profile.name,
            "location": profile.location,
            "age": profile.age as Any,
            "image": profile.image,
            "about": profile.about,
            "interests": profile.interests,
            "aspirations": profile.aspirations,
            "additionalImages": profile.additionalImages,
        ]
        try await db.collection("users").document(profile.id).setData(payload, merge: true)
        try await db.collection("publicProfiles").document(profile.id).setData(payload, merge: true)
    }

    func isQuizCompleted(uid: String) async throws -> Bool {
        let doc = try await db.collection("quizProgress").document(uid).getDocument()
        return doc.data()?["completed"] as? Bool ?? false
    }

    func saveQuizProgress(uid: String, answers: [String: QuizAnswerRecord], currentIndex: Int, completed: Bool) async throws {
        var flatAnswers: [String: Any] = [:]
        var preferredAnswers: [String: Any] = [:]
        var importance: [String: Int] = [:]
        var dealbreakers: [String: Bool] = [:]

        for (questionId, record) in answers {
            if let multi = record.answers, !multi.isEmpty {
                flatAnswers[questionId] = multi
            } else if let single = record.answer {
                flatAnswers[questionId] = single
            }
            preferredAnswers[questionId] = record.preferredAnswers
            importance[questionId] = record.importance
            if record.dealbreaker {
                dealbreakers[questionId] = true
            }
        }

        try await db.collection("quizProgress").document(uid).setData([
            "answers": flatAnswers,
            "preferredAnswers": preferredAnswers,
            "importance": importance,
            "dealbreakers": dealbreakers,
            "currentIndex": currentIndex,
            "completed": completed,
            "updatedAt": FieldValue.serverTimestamp(),
            "completedAt": completed ? FieldValue.serverTimestamp() : NSNull(),
        ], merge: true)
    }

    func findMatches(maxDistance: Int) async throws -> [RidgitsMatch] {
        try await api.findMatches(maxDistance: maxDistance)
    }

    func getTopNationwideMatches(limit: Int = 10) async throws -> [RidgitsMatch] {
        try await api.getTopNationwideMatches(limit: limit)
    }

    func startConversation(toUserId: String, message: String) async throws -> String {
        try await api.startConversation(toUserId: toUserId, message: message)
    }

    func approveConversation(conversationId: String) async throws {
        try await api.approveConversation(conversationId: conversationId)
    }

    func sendMessage(conversationId: String, message: String) async throws {
        try await api.sendMessage(conversationId: conversationId, message: message)
    }

    func markConversationRead(conversationId: String) async throws {
        try await api.markConversationRead(conversationId: conversationId)
    }

    func listenConversations(userId: String, onChange: @escaping ([RidgitsConversation]) -> Void) -> ListenerRegistration {
        db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, _ in
                let conversations = snapshot?.documents.compactMap { doc -> RidgitsConversation? in
                    let data = doc.data()
                    let deletedBy = data["deletedBy"] as? [String] ?? []
                    guard !deletedBy.contains(userId) else { return nil }
                    return RidgitsConversation.from(id: doc.documentID, data: data, currentUserId: userId)
                } ?? []
                onChange(conversations)
            }
    }

    func listenMessages(conversationId: String, onChange: @escaping ([RidgitsMessage]) -> Void) -> ListenerRegistration {
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(to: 100)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { doc in
                    RidgitsMessage.from(id: doc.documentID, data: doc.data())
                } ?? []
                onChange(messages)
            }
    }

    func listenConversation(conversationId: String, onChange: @escaping (RidgitsConversation?) -> Void) -> ListenerRegistration {
        db.collection("conversations").document(conversationId).addSnapshotListener { snapshot, _ in
            guard let snapshot, snapshot.exists, let data = snapshot.data(),
                  let userId = Auth.auth().currentUser?.uid else {
                onChange(nil)
                return
            }
            onChange(RidgitsConversation.from(id: snapshot.documentID, data: data, currentUserId: userId))
        }
    }
}
