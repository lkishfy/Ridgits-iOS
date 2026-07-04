import Foundation

struct RidgitsCompatibilityScores: Equatable {
    let communication: Int
    let intimacy: Int
    let values: Int
    let social: Int
    let commitment: Int
    let overall: Int
}

enum RidgitsQuizCompatibility {
    enum CompatAnswer: Equatable {
        case single(Int)
        case multi([Int])
    }

    struct Input {
        var answers: [String: CompatAnswer]
        var preferredAnswers: [String: CompatAnswer]
        var importance: [String: Int]
        var dealbreakers: [String: Bool]
    }

    static func input(from progress: LoadedQuizProgress) -> Input {
        var answers: [String: CompatAnswer] = [:]
        var preferred: [String: CompatAnswer] = [:]
        var importance: [String: Int] = [:]
        var dealbreakers: [String: Bool] = [:]

        for (questionId, record) in progress.answers {
            if let answer = compatAnswer(from: record) {
                answers[questionId] = answer
            }
            if !record.preferredAnswers.isEmpty {
                preferred[questionId] = .multi(record.preferredAnswers)
            }
            importance[questionId] = record.importance
            if record.dealbreaker {
                dealbreakers[questionId] = true
            }
        }

        return Input(
            answers: answers,
            preferredAnswers: preferred,
            importance: importance,
            dealbreakers: dealbreakers
        )
    }

    static func calculate(_ user1: Input, _ user2: Input) -> RidgitsCompatibilityScores {
        struct CategoryStats {
            var questions = 0
            var user1Points = 0
            var user1MaxPoints = 0
            var user2Points = 0
            var user2MaxPoints = 0
        }

        var categories: [String: CategoryStats] = [
            "communication": CategoryStats(),
            "intimacy": CategoryStats(),
            "values": CategoryStats(),
            "social": CategoryStats(),
            "commitment": CategoryStats(),
        ]

        var totalQuestions = 0
        var dealbreakerViolations = 0

        let commonQuestions = user1.answers.keys.filter { key in
            user2.answers[key] != nil && !isDemographicQuestionKey(key)
        }

        for questionId in commonQuestions {
            guard let category = questionCategory(for: questionId),
                  categories[category] != nil,
                  let ans1 = user1.answers[questionId],
                  let ans2 = user2.answers[questionId] else { continue }

            let pref1 = user1.preferredAnswers[questionId] ?? ans1
            let pref2 = user2.preferredAnswers[questionId] ?? ans2
            let imp1 = user1.importance[questionId] ?? 50
            let imp2 = user2.importance[questionId] ?? 50
            let isDealbreaker1 = user1.dealbreakers[questionId] == true
            let isDealbreaker2 = user2.dealbreakers[questionId] == true

            var cat = categories[category]!
            cat.questions += 1
            totalQuestions += 1

            if matchesPreference(answer: ans2, preference: pref1) { cat.user1Points += imp1 }
            cat.user1MaxPoints += imp1
            if matchesPreference(answer: ans1, preference: pref2) { cat.user2Points += imp2 }
            cat.user2MaxPoints += imp2

            if isDealbreaker1 && !matchesPreference(answer: ans2, preference: pref1) {
                dealbreakerViolations += 1
            }
            if isDealbreaker2 && !matchesPreference(answer: ans1, preference: pref2) {
                dealbreakerViolations += 1
            }

            categories[category] = cat
        }

        func scoreCategory(_ cat: CategoryStats) -> Int {
            guard cat.questions > 0 else { return 0 }
            let user1Satisfaction = cat.user1MaxPoints > 0
                ? (Double(cat.user1Points) / Double(cat.user1MaxPoints)) * 100
                : 0
            let user2Satisfaction = cat.user2MaxPoints > 0
                ? (Double(cat.user2Points) / Double(cat.user2MaxPoints)) * 100
                : 0
            return Int((sqrt(user1Satisfaction * user2Satisfaction)).rounded())
        }

        let communication = scoreCategory(categories["communication"]!)
        let intimacy = scoreCategory(categories["intimacy"]!)
        let values = scoreCategory(categories["values"]!)
        let social = scoreCategory(categories["social"]!)
        let commitment = scoreCategory(categories["commitment"]!)

        let weightedSum = communication + intimacy + values + social + commitment
        let overallScore = totalQuestions > 0 ? Int((Double(weightedSum) / 5.0).rounded()) : 0
        let dealbreakerPenalty = min(20, dealbreakerViolations * 5)
        let overall = max(0, overallScore - dealbreakerPenalty)

        return RidgitsCompatibilityScores(
            communication: communication,
            intimacy: intimacy,
            values: values,
            social: social,
            commitment: commitment,
            overall: overall
        )
    }

    static func dimensionAverages(from progress: LoadedQuizProgress) -> RidgitsCompatibilityScores {
        let raw = categoryAveragesRaw(from: progress)
        func averagePercent(_ value: Double) -> Int {
            Int((value / 3.0 * 100).rounded())
        }

        let communication = averagePercent(raw["communication"] ?? 1.5)
        let intimacy = averagePercent(raw["intimacy"] ?? 1.5)
        let values = averagePercent(raw["values"] ?? 1.5)
        let social = averagePercent(raw["social"] ?? 1.5)
        let commitment = averagePercent(raw["commitment"] ?? 1.5)
        let overall = (communication + intimacy + values + social + commitment) / 5

        return RidgitsCompatibilityScores(
            communication: communication,
            intimacy: intimacy,
            values: values,
            social: social,
            commitment: commitment,
            overall: overall
        )
    }

    static func insights(from progress: LoadedQuizProgress) -> [String] {
        let raw = categoryAveragesRaw(from: progress)
        let communication = raw["communication"] ?? 1.5
        let intimacy = raw["intimacy"] ?? 1.5
        let values = raw["values"] ?? 1.5
        let social = raw["social"] ?? 1.5
        let commitment = raw["commitment"] ?? 1.5

        var insights: [String] = []

        if communication <= 1 {
            insights.append("You really value open, expressive communication. Vet people for emotional availability early on—if they're closed off or hard to read, that's a red flag for you.")
        } else if communication <= 2 {
            insights.append("You value thoughtful, deep conversations. Look for people who can match your communication style and don't shy away from meaningful discussions.")
        } else {
            insights.append("You prefer people who respect your independence in how you communicate. Make sure they understand you need space and won't take it personally.")
        }

        if intimacy <= 1 {
            insights.append("Physical affection and closeness are important to you. Don't settle for someone who's cold or distant—you need warmth and connection.")
        } else if intimacy <= 2 {
            insights.append("You build intimacy gradually and that's completely valid. Find someone patient who won't rush you into emotional or physical closeness before you're ready.")
        } else {
            insights.append("You value your personal space and boundaries. Be upfront about this—the right person will respect your need for independence.")
        }

        if values <= 1 {
            insights.append("Shared values and lifestyle alignment matter deeply to you. Pay attention to how someone lives day-to-day, not just what they say they want.")
        } else if values <= 2 {
            insights.append("You appreciate a balance between structure and openness. Look for someone flexible enough to grow with you without constant friction.")
        } else {
            insights.append("You embrace spontaneity and flexibility. Make sure a partner won't mistake your adaptability for a lack of standards.")
        }

        if social <= 1 {
            insights.append("You're energized by social connection and new experiences. A partner who pulls you into the world—or happily joins you in it—will fit best.")
        } else if social <= 2 {
            insights.append("You enjoy social time but still need recovery space. Look for someone who understands both sides of your social battery.")
        } else {
            insights.append("You prefer intimate, quality time with close connections over constant socializing. Don't let anyone pressure you into being more extroverted than you are.")
        }

        if commitment <= 1 {
            insights.append("You're ready for serious commitment and clarity. Be direct about what you want so you don't waste time with people who aren't aligned.")
        } else if commitment <= 2 {
            insights.append("You take time to trust and commit fully. That's healthy—just communicate your pace so the right person can meet you there.")
        } else {
            insights.append("You value flexibility in how relationships develop. Make sure potential partners understand you're not rushing labels before the connection is real.")
        }

        return insights
    }

    private static func categoryAveragesRaw(from progress: LoadedQuizProgress) -> [String: Double] {
        var groups: [String: [Double]] = [
            "communication": [],
            "intimacy": [],
            "values": [],
            "social": [],
            "commitment": [],
        ]

        for (index, question) in QuizCatalog.questions.enumerated() {
            guard question.category != "Demographics" else { continue }
            guard let numeric = numericAnswer(for: question, at: index, in: progress) else { continue }
            guard let key = categoryKey(for: question) else { continue }
            groups[key, default: []].append(numeric)
        }

        func average(_ values: [Double]) -> Double {
            guard !values.isEmpty else { return 1.5 }
            return values.reduce(0, +) / Double(values.count)
        }

        return [
            "communication": average(groups["communication"] ?? []),
            "intimacy": average(groups["intimacy"] ?? []),
            "values": average(groups["values"] ?? []),
            "social": average(groups["social"] ?? []),
            "commitment": average(groups["commitment"] ?? []),
        ]
    }

    private static func numericAnswer(
        for question: QuizQuestion,
        at index: Int,
        in progress: LoadedQuizProgress
    ) -> Double? {
        let record: QuizAnswerRecord?
        if let byID = progress.answers[question.id], byID.hasAnswer {
            record = byID
        } else if let byIndex = progress.answers[String(index)], byIndex.hasAnswer {
            record = byIndex
        } else {
            record = nil
        }

        guard let record else { return nil }
        if let multi = record.answers, !multi.isEmpty {
            return Double(multi.reduce(0, +)) / Double(multi.count)
        }
        if let single = record.answer {
            return Double(single)
        }
        return nil
    }

    private static func categoryKey(for question: QuizQuestion) -> String? {
        if let fromID = questionCategory(for: question.id) {
            return fromID
        }
        let category = question.category.lowercased()
        if category.contains("communication") { return "communication" }
        if category.contains("intimacy") { return "intimacy" }
        if category.contains("values") { return "values" }
        if category.contains("social") { return "social" }
        if category.contains("commitment") { return "commitment" }
        return nil
    }

    private static func compatAnswer(from record: QuizAnswerRecord) -> CompatAnswer? {
        if let multi = record.answers, !multi.isEmpty {
            return .multi(multi)
        }
        if let single = record.answer {
            return .single(single)
        }
        return nil
    }

    private static func isDemographicQuestionKey(_ key: String) -> Bool {
        if key.hasPrefix("demo_") { return true }
        if let num = Int(key), num < 3 { return true }
        return false
    }

    private static func questionCategory(for questionId: String) -> String? {
        let id = questionId.replacingOccurrences(of: "ll_", with: "")
        if id.hasPrefix("comm_") || id.hasPrefix("spicy_comm_") { return "communication" }
        if id.hasPrefix("intm_") || id.hasPrefix("msg_") || id.hasPrefix("bnd_") { return "intimacy" }
        if id.hasPrefix("vals_") || id.hasPrefix("spicy_vals_") { return "values" }
        if id.hasPrefix("socl_") { return "social" }
        if id.hasPrefix("comt_") { return "commitment" }

        if let question = QuizCatalog.questions.first(where: { $0.id == questionId }) {
            let category = question.category.lowercased()
            if category.contains("communication") { return "communication" }
            if category.contains("intimacy") { return "intimacy" }
            if category.contains("values") { return "values" }
            if category.contains("social") { return "social" }
            if category.contains("commitment") { return "commitment" }
        }
        return nil
    }

    private static func matchesPreference(answer: CompatAnswer, preference: CompatAnswer) -> Bool {
        switch preference {
        case .multi(let preferredValues):
            switch answer {
            case .single(let value):
                return preferredValues.contains(value)
            case .multi(let values):
                return !Set(values).isDisjoint(with: preferredValues)
            }
        case .single(let preferredValue):
            switch answer {
            case .single(let value):
                return value == preferredValue
            case .multi(let values):
                return values.contains(preferredValue)
            }
        }
    }
}

extension RidgitsCompatibilityScores {
    var asRidgitsCompatibility: RidgitsCompatibility {
        RidgitsCompatibility(
            overall: overall,
            communication: communication,
            intimacy: intimacy,
            values: values,
            social: social,
            commitment: commitment
        )
    }
}

extension RidgitsQuizCompatibility {
    static func compatibilityBetween(currentUserId: String, otherUserId: String) async -> RidgitsCompatibility? {
        do {
            guard let myProgress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: currentUserId),
                  myProgress.completed || QuizCatalog.hasEnoughPersonalityAnswers(in: myProgress.answers),
                  let otherProgress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: otherUserId),
                  otherProgress.completed || QuizCatalog.hasEnoughPersonalityAnswers(in: otherProgress.answers) else {
                return nil
            }

            return calculate(
                input(from: myProgress),
                input(from: otherProgress)
            ).asRidgitsCompatibility.withDerivedOverallIfNeeded()
        } catch {
            return nil
        }
    }
}
