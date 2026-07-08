import Foundation
import FirebaseAuth
import FirebaseFirestore

struct CommunityQuizStats: Equatable {
    var totalCompleted: Int = 0
    var completedThisMonth: Int = 0
}

struct PopularQuestionRating: Equatable {
    let questionText: String
    let upCount: Int
}

struct ArchetypeDistributionEntry: Identifiable, Equatable {
    let name: String
    let count: Int
    var id: String { name }
}

enum QuestionSubmitStatus: Equatable {
    case idle
    case success
    case error
}

@MainActor
final class CommunityStatsViewModel: ObservableObject {
    @Published private(set) var stats = CommunityQuizStats()
    @Published private(set) var isLoading = true
    @Published private(set) var popularCommunityQuestion: PopularQuestionRating?
    @Published private(set) var popularOriginalQuestion: PopularQuestionRating?
    @Published private(set) var archetypeDistribution: [ArchetypeDistributionEntry] = []
    @Published var questionDraft = ""
    @Published private(set) var isSubmittingQuestion = false
    @Published private(set) var questionSubmitStatus: QuestionSubmitStatus = .idle

    private var statsListener: ListenerRegistration?
    private var ratingsListener: ListenerRegistration?
    private var archetypeListener: ListenerRegistration?

    static let communityQuestionCount: Int = {
        QuizCatalog.questions.filter(\.userSubmitted).count
    }()

    func startListening() {
        guard statsListener == nil else { return }
        isLoading = true

        statsListener = RidgitsFirebaseClient.shared.listenCommunityQuizStats { [weak self] stats in
            Task { @MainActor in
                self?.stats = stats
                self?.isLoading = false
            }
        }

        ratingsListener = RidgitsFirebaseClient.shared.listenQuestionRatings { [weak self] community, original in
            Task { @MainActor in
                self?.popularCommunityQuestion = community
                self?.popularOriginalQuestion = original
            }
        }

        archetypeListener = RidgitsFirebaseClient.shared.listenCommunityArchetypeDistribution { [weak self] distribution in
            Task { @MainActor in
                self?.archetypeDistribution = distribution
                    .sorted { $0.value > $1.value }
                    .map { ArchetypeDistributionEntry(name: $0.key, count: $0.value) }
            }
        }
    }

    func stopListening() {
        statsListener?.remove()
        statsListener = nil
        ratingsListener?.remove()
        ratingsListener = nil
        archetypeListener?.remove()
        archetypeListener = nil
    }

    func submitQuestionIdea() async {
        let trimmed = questionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmittingQuestion else { return }

        isSubmittingQuestion = true
        questionSubmitStatus = .idle

        do {
            try await RidgitsFirebaseClient.shared.submitQuestionIdea(
                idea: trimmed,
                userId: Auth.auth().currentUser?.uid
            )
            questionDraft = ""
            questionSubmitStatus = .success
            try? await Task.sleep(for: .seconds(3))
            if questionSubmitStatus == .success {
                questionSubmitStatus = .idle
            }
        } catch {
            questionSubmitStatus = .error
        }

        isSubmittingQuestion = false
    }
}
