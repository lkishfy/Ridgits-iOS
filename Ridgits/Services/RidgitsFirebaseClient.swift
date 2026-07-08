import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RidgitsFirebaseClient {
    static let shared = RidgitsFirebaseClient()

    private let db = Firestore.firestore()
    private let api = RidgitsAPIClient.shared
    private var profileRefreshTasks: [String: Task<Void, Never>] = [:]
    private var ridgitListRefreshTasks: [String: Task<Void, Never>] = [:]

    private init() {}

    enum ProfileFetchPolicy {
        case cacheFirst
        case networkOnly
    }

    func fetchUserProfile(uid: String, policy: ProfileFetchPolicy = .cacheFirst) async throws -> RidgitsUserProfile {
        switch policy {
        case .cacheFirst:
            if let cached = RidgitsProfileCache.shared.profile(for: uid) {
                if RidgitsProfileCache.shared.isStale(uid: uid) {
                    scheduleProfileRefresh(uid: uid)
                }
                return cached
            }
            return try await fetchUserProfile(uid: uid, policy: .networkOnly)
        case .networkOnly:
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data() else {
                let empty = RidgitsUserProfile.empty(uid: uid)
                RidgitsProfileCache.shared.save(empty)
                return empty
            }
            let profile = RidgitsUserProfile.from(uid: uid, data: data)
            RidgitsProfileCache.shared.save(profile)
            return profile
        }
    }

    func saveUserProfile(_ profile: RidgitsUserProfile) async throws {
        var normalizedProfile = profile
        RidgitsUSLocations.applyNormalizedLocation(to: &normalizedProfile)

        let payload: [String: Any] = [
            "name": normalizedProfile.name,
            "location": normalizedProfile.location,
            "locationCity": normalizedProfile.locationCity,
            "locationStateCode": normalizedProfile.locationStateCode,
            "age": normalizedProfile.age as Any,
            "image": normalizedProfile.image,
            "about": normalizedProfile.about,
            "interests": normalizedProfile.interests,
            "aspirations": normalizedProfile.aspirations,
            "additionalImages": normalizedProfile.additionalImages,
            "socialHandle": normalizedProfile.socialHandle,
            "ageRangeMin": normalizedProfile.ageRangeMin as Any,
            "ageRangeMax": normalizedProfile.ageRangeMax as Any,
            "visibleInCommunity": normalizedProfile.visibleInCommunity,
            "coordinates": FieldValue.delete(),
            "coordinatesUpdatedAt": FieldValue.delete(),
            "geocodedFromLocation": FieldValue.delete(),
        ]
        try await db.collection("users").document(normalizedProfile.id).setData(payload, merge: true)
        try await db.collection("publicProfiles").document(normalizedProfile.id).setData(payload, merge: true)
        RidgitsProfileCache.shared.save(normalizedProfile)

        let image = normalizedProfile.image.trimmingCharacters(in: .whitespacesAndNewlines)
        if !image.isEmpty {
            try await api.registerProfilePhoto(imageUrl: image)
        }
    }

    func isQuizCompleted(uid: String) async throws -> Bool {
        async let quizSnapTask = db.collection("quizProgress").document(uid).getDocument()
        async let userSnapTask = db.collection("users").document(uid).getDocument()
        let quizSnap = try await quizSnapTask
        let userSnap = try await userSnapTask

        if let data = quizSnap.data() {
            if data["eligibleForMatching"] as? Bool == true { return true }
            if data["completed"] as? Bool == true { return true }
            if let answered = parseInt(data["questionsAnswered"]),
               answered >= QuizCatalog.onboardingSkipThreshold {
                return true
            }
            if let progress = try await fetchQuizProgress(uid: uid),
               QuizCatalog.hasEnoughPersonalityAnswers(in: progress.answers) {
                return true
            }
        }

        let userData = userSnap.data() ?? [:]
        if userData["onboardingCompleted"] as? Bool == true { return true }
        if userData["quizCompletedAt"] != nil { return true }
        return false
    }

    /// Marks quiz + onboarding complete on Firestore when the user has enough valid answers.
    /// Migrates legacy index keys to question IDs and clears stale match caches.
    @discardableResult
    func ensureQuizCompletionRecorded(uid: String) async throws -> Bool {
        guard let progress = try await fetchQuizProgress(uid: uid) else { return false }

        let doc = try await db.collection("quizProgress").document(uid).getDocument()
        let questionsAnswered = parseInt(doc.data()?["questionsAnswered"]) ?? 0
        let eligible = progress.completed
            || QuizCatalog.hasEnoughPersonalityAnswers(in: progress.answers)
            || questionsAnswered >= QuizCatalog.onboardingSkipThreshold
        guard eligible else { return false }

        let rawAnswers = doc.data()?["answers"] as? [String: Any] ?? [:]
        let keysNeedMigration = rawAnswers.keys.contains {
            QuizCatalog.normalizedQuestionId(forStorageKey: $0) != $0
        }
        let needsCompletionFlag = !(doc.data()?["completed"] as? Bool ?? false)

        if keysNeedMigration || (needsCompletionFlag && QuizCatalog.hasEnoughPersonalityAnswers(in: progress.answers)) {
            let archetype = QuizArchetypeCalculator.calculate(
                answers: progress.answers,
                questions: QuizCatalog.questions
            )
            try await saveQuizProgress(
                uid: uid,
                answers: progress.answers,
                currentQuestion: progress.currentQuestion,
                freePassesRemaining: progress.freePassesRemaining,
                completed: true,
                archetype: archetype
            )
        } else if needsCompletionFlag {
            try await db.collection("quizProgress").document(uid).setData(
                [
                    "completed": true,
                    "eligibleForMatching": true,
                    "completedAt": FieldValue.serverTimestamp(),
                    "questionsAnswered": max(questionsAnswered, QuizCatalog.onboardingSkipThreshold),
                ],
                merge: true
            )
        }

        try await db.collection("users").document(uid).setData(
            [
                "onboardingCompleted": true,
                "quizCompletedAt": FieldValue.serverTimestamp(),
            ],
            merge: true
        )
        await syncCompletedQuizBadges(uid: uid)
        RidgitsMatchesCache.shared.clearNationwide(uid: uid)
        return true
    }

    func fetchQuizProgress(uid: String, source: FirestoreSource = .default) async throws -> LoadedQuizProgress? {
        let doc = try await db.collection("quizProgress").document(uid).getDocument(source: source)
        guard let data = doc.data() else { return nil }

        let flatAnswers = data["answers"] as? [String: Any] ?? [:]
        let preferredAnswers = data["preferredAnswers"] as? [String: Any] ?? [:]
        let importanceMap = data["importance"] as? [String: Any] ?? [:]
        let dealbreakers = data["dealbreakers"] as? [String: Bool] ?? [:]

        var answers: [String: QuizAnswerRecord] = [:]
        let allRawKeys = Set(flatAnswers.keys)
            .union(preferredAnswers.keys)
            .union(importanceMap.keys)
            .union(dealbreakers.keys)

        let sortedKeys = allRawKeys.sorted { lhs, rhs in
            let lhsIsId = lhs.first?.isLetter == true
            let rhsIsId = rhs.first?.isLetter == true
            if lhsIsId != rhsIsId { return !lhsIsId && rhsIsId }
            return lhs < rhs
        }

        for rawKey in sortedKeys {
            let questionId = QuizCatalog.normalizedQuestionId(forStorageKey: rawKey)
            var record = answers[questionId] ?? QuizAnswerRecord(
                preferredAnswers: parseIntArray(preferredAnswers[questionId] ?? preferredAnswers[rawKey]) ?? [],
                importance: parseInt(importanceMap[questionId] ?? importanceMap[rawKey]) ?? QuizImportance.somewhat.rawValue,
                dealbreaker: dealbreakers[questionId] == true || dealbreakers[rawKey] == true
            )

            if let rawValue = flatAnswers[questionId] ?? flatAnswers[rawKey],
               let parsed = parseStoredAnswerValue(rawValue) {
                record.answers = parsed.answers
                record.answer = parsed.answer
            }

            if record.preferredAnswers.isEmpty,
               let preferred = parseIntArray(preferredAnswers[questionId] ?? preferredAnswers[rawKey]) {
                record.preferredAnswers = preferred
            }

            if !record.hasAnswer,
               let preferred = parseIntArray(preferredAnswers[questionId] ?? preferredAnswers[rawKey]),
               !preferred.isEmpty {
                record.answers = preferred
                record.answer = preferred.count == 1 ? preferred[0] : nil
            }

            if let importance = parseInt(importanceMap[questionId] ?? importanceMap[rawKey]) {
                record.importance = importance
            }

            if record.hasAnswer {
                answers[questionId] = record
            }
        }

        let currentQuestion = parseInt(data["currentQuestion"]) ?? parseInt(data["currentIndex"]) ?? 0
        let freePasses = parseInt(data["freePassesRemaining"]) ?? deriveFreePassesRemaining(from: flatAnswers)
        let serverCompleted = data["completed"] as? Bool ?? false
        let derivedCompleted = serverCompleted || QuizCatalog.hasEnoughPersonalityAnswers(in: answers)
        let questionsAnswered = parseInt(data["questionsAnswered"])
            ?? QuizCatalog.personalityAnsweredCount(in: answers)

        return LoadedQuizProgress(
            answers: answers,
            currentQuestion: currentQuestion,
            completed: derivedCompleted,
            freePassesRemaining: freePasses,
            questionsAnswered: questionsAnswered
        )
    }

    func saveQuizProgress(
        uid: String,
        answers: [String: QuizAnswerRecord],
        currentQuestion: Int,
        freePassesRemaining: Int,
        completed: Bool,
        archetype: QuizArchetypeDefinition? = nil
    ) async throws {
        let personalityAnswered = QuizCatalog.personalityAnsweredCount(in: answers)

        if answers.isEmpty && !completed {
            if let existing = try await fetchQuizProgress(uid: uid),
               QuizCatalog.personalityAnsweredCount(in: existing.answers) > 0 {
                return
            }
            let snapshot = try await db.collection("quizProgress").document(uid).getDocument()
            let serverAnswered = parseInt(snapshot.data()?["questionsAnswered"]) ?? 0
            if serverAnswered >= QuizCatalog.onboardingSkipThreshold {
                return
            }
        }

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
            if !record.preferredAnswers.isEmpty {
                preferredAnswers[questionId] = record.preferredAnswers
            }
            importance[questionId] = record.importance
            if record.dealbreaker {
                dealbreakers[questionId] = true
            }
        }

        let existingSnap = try await db.collection("quizProgress").document(uid).getDocument()
        mergePreservedDemographicAnswers(into: &flatAnswers, from: existingSnap.data())

        var payload: [String: Any] = [
            "answers": flatAnswers,
            "preferredAnswers": preferredAnswers,
            "importance": importance,
            "dealbreakers": dealbreakers,
            "currentQuestion": currentQuestion,
            "currentIndex": currentQuestion,
            "freePassesRemaining": freePassesRemaining,
            "questionsAnswered": personalityAnswered,
            "totalQuestions": QuizCatalog.questions.count,
            "completed": completed,
            "eligibleForMatching": completed || personalityAnswered >= QuizCatalog.onboardingSkipThreshold,
            "updatedAt": FieldValue.serverTimestamp(),
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "completedAt": completed ? FieldValue.serverTimestamp() : NSNull(),
        ]

        if let user = Auth.auth().currentUser {
            payload["userId"] = uid
            if let email = user.email {
                payload["email"] = email
            }
        }

        if let archetype {
            payload["archetype"] = archetype.firestorePayload
        }

        try await db.collection("quizProgress").document(uid).setData(payload, merge: true)
        if completed {
            await syncCompletedQuizBadges(uid: uid)
        }
        RidgitsMatchesCache.shared.clearNationwide(uid: uid)
    }

    /// Merges only demographic quiz answers without touching personality answers.
    func saveDemographicAnswers(
        uid: String,
        gender: [Int],
        interestedIn: [Int],
        lookingFor: [Int]
    ) async throws {
        guard !gender.isEmpty || !interestedIn.isEmpty || !lookingFor.isEmpty else { return }

        let docRef = db.collection("quizProgress").document(uid)
        let snap = try await docRef.getDocument()
        let existing = snap.data() ?? [:]

        var answers = existing["answers"] as? [String: Any] ?? [:]
        var preferredAnswers = existing["preferredAnswers"] as? [String: Any] ?? [:]

        if !gender.isEmpty {
            answers["demo_000"] = gender
            preferredAnswers["demo_000"] = gender
            answers.removeValue(forKey: "0")
            preferredAnswers.removeValue(forKey: "0")
        }
        if !interestedIn.isEmpty {
            answers["demo_001"] = interestedIn
            preferredAnswers["demo_001"] = interestedIn
            answers.removeValue(forKey: "1")
            preferredAnswers.removeValue(forKey: "1")
        }
        if !lookingFor.isEmpty {
            answers["demo_002"] = lookingFor
            preferredAnswers["demo_002"] = lookingFor
            answers.removeValue(forKey: "2")
            preferredAnswers.removeValue(forKey: "2")
        }

        var payload: [String: Any] = [
            "answers": answers,
            "preferredAnswers": preferredAnswers,
            "demographicsUpdatedAt": FieldValue.serverTimestamp(),
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        for legacyKey in ["0", "1", "2"] {
            payload["answers.\(legacyKey)"] = FieldValue.delete()
            payload["preferredAnswers.\(legacyKey)"] = FieldValue.delete()
        }

        if let user = Auth.auth().currentUser {
            payload["userId"] = uid
            if let email = user.email {
                payload["email"] = email
            }
        }

        try await docRef.setData(payload, merge: true)
        try? await db.collection("topNationwideMatches").document(uid).delete()
        RidgitsMatchesCache.shared.clear(uid: uid)
        NotificationCenter.default.post(name: .ridgitsMatchPreferencesDidChange, object: nil)
    }

    private static let legacyDemographicKeys = ["0": "demo_000", "1": "demo_001", "2": "demo_002"]

    private func mergePreservedDemographicAnswers(into flatAnswers: inout [String: Any], from existing: [String: Any]?) {
        guard let existingAnswers = existing?["answers"] as? [String: Any] else { return }
        for demoId in QuizCatalog.demographicQuestionIDs {
            guard flatAnswers[demoId] == nil else { continue }
            if let value = existingAnswers[demoId] {
                flatAnswers[demoId] = value
                continue
            }
            if let legacyKey = Self.legacyDemographicKeys.first(where: { $0.value == demoId })?.key,
               let value = existingAnswers[legacyKey] {
                flatAnswers[demoId] = value
            }
        }
    }

    private func parseInt(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double.rounded()) }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String, let int = Int(string) { return int }
        return nil
    }

    private func parseIntArray(_ value: Any?) -> [Int]? {
        if let array = value as? [Int] { return array }
        if let array = value as? [Double] { return array.map { Int($0.rounded()) } }
        if let array = value as? [NSNumber] { return array.map(\.intValue) }
        if let single = parseInt(value) { return [single] }
        return nil
    }

    private func parseStoredAnswerValue(_ value: Any?) -> (answer: Int?, answers: [Int]?)? {
        if let array = parseIntArray(value) {
            return (array.count == 1 ? array[0] : nil, array)
        }
        if let single = parseInt(value) {
            return (single, [single])
        }
        if let dict = value as? [String: Any] {
            if let nestedAnswers = dict["answers"], let array = parseIntArray(nestedAnswers) {
                return (array.count == 1 ? array[0] : nil, array)
            }
            if let nestedAnswer = dict["answer"] {
                if let array = parseIntArray(nestedAnswer) {
                    return (array.count == 1 ? array[0] : nil, array)
                }
                if let single = parseInt(nestedAnswer) {
                    return (single, [single])
                }
            }
        }
        return nil
    }

    private func deriveFreePassesRemaining(from flatAnswers: [String: Any]) -> Int {
        let used = flatAnswers.filter { key, value in
            guard !key.hasPrefix("demo_") else { return false }
            if let array = value as? [Any] { return array.count > 1 }
            return false
        }.count
        return max(0, 3 - used)
    }

    func fetchQuizArchetype(uid: String) async -> (name: String, description: String)? {
        guard let doc = try? await db.collection("quizProgress").document(uid).getDocument(),
              let data = doc.data() else { return nil }

        if let archetype = data["archetype"] as? [String: Any],
           let name = archetype["name"] as? String {
            let description = archetype["description"] as? String ?? ""
            return (name, description)
        }

        if let name = data["archetype"] as? String, !name.isEmpty {
            return (name, "")
        }

        if let name = data["archetypeName"] as? String, !name.isEmpty {
            let description = data["archetypeDescription"] as? String ?? ""
            return (name, description)
        }

        return nil
    }

    func fetchProfileCode(uid: String, policy: ProfileFetchPolicy = .cacheFirst) async -> String? {
        switch policy {
        case .cacheFirst:
            if let cached = RidgitsProfileCache.shared.profileCode(for: uid) {
                return cached
            }
            return await fetchProfileCode(uid: uid, policy: .networkOnly)
        case .networkOnly:
            guard let code = await fetchProfileCodeFromFirestore(uid: uid) else { return nil }
            RidgitsProfileCache.shared.saveProfileCode(code, uid: uid)
            return code
        }
    }

    private func scheduleProfileRefresh(uid: String) {
        guard profileRefreshTasks[uid] == nil else { return }
        profileRefreshTasks[uid] = Task {
            try? await fetchUserProfile(uid: uid, policy: .networkOnly)
            profileRefreshTasks[uid] = nil
        }
    }

    private func fetchProfileCodeFromFirestore(uid: String) async -> String? {
        guard let snapshot = try? await db.collection("profileCodes")
            .whereField("userId", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments(),
              let doc = snapshot.documents.first else { return nil }
        return doc.documentID
    }

    func fetchUserId(forProfileCode code: String) async -> String? {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty,
              let doc = try? await db.collection("profileCodes").document(normalized).getDocument(),
              doc.exists,
              let userId = doc.data()?["userId"] as? String else { return nil }
        return userId
    }

    func fetchPackProfile(uid: String) async -> RidgitsPackProfile {
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let data = doc.data() else {
            return RidgitsPackProfile()
        }

        var profile = RidgitsPackProfile(
            purchasedPacks: data["purchasedPacks"] as? [String] ?? [],
            unlockedPacks: data["unlockedPacks"] as? [String] ?? [],
            subscriptionTier: data["subscriptionTier"] as? String ?? "free"
        )

        for pack in RidgitsArchetypePack.catalog + RidgitsArchetypePack.referralCatalog {
            guard let raw = data[pack.resultKey] as? [String: Any] else { continue }
            let archetype = (raw["archetype"] as? [String: Any]) ?? raw
            let name = archetype["name"] as? String ?? ""
            let description = archetype["description"] as? String ?? ""
            guard !name.isEmpty else { continue }

            let characteristics = (archetype["characteristics"] as? [String])
                ?? (archetype["traits"] as? [String])
                ?? []
            var suggestions = archetype["suggestions"] as? [String] ?? []
            if suggestions.isEmpty, let growthTip = archetype["growth_tip"] as? String, !growthTip.isEmpty {
                suggestions = [growthTip]
            }

            profile.packResults[pack.resultKey] = RidgitsPackArchetypeResult(
                name: name,
                description: description,
                characteristics: characteristics,
                suggestions: suggestions,
                idealMatch: archetype["ideal_match"] as? String,
                growthTip: archetype["growth_tip"] as? String
            )
        }

        return profile
    }

    func fetchPackQuizState(uid: String, pack: RidgitsArchetypePack) async throws -> PackQuizSavedState {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard doc.exists, let data = doc.data() else {
            return PackQuizSavedState()
        }

        var answers: [String: Int] = [:]
        if let rawAnswers = data[pack.answersKey] as? [String: Any] {
            for (key, value) in rawAnswers {
                if let intValue = value as? Int {
                    answers[key] = intValue
                } else if let number = value as? NSNumber {
                    answers[key] = number.intValue
                }
            }
        }

        guard let rawResult = data[pack.resultKey] as? [String: Any] else {
            return PackQuizSavedState(answers: answers, result: nil)
        }

        let archetypeDict = (rawResult["archetype"] as? [String: Any]) ?? rawResult
        guard let name = archetypeDict["name"] as? String, !name.isEmpty else {
            return PackQuizSavedState(answers: answers, result: nil)
        }

        let characteristics = (archetypeDict["characteristics"] as? [String])
            ?? (archetypeDict["traits"] as? [String])
            ?? []
        var suggestions = archetypeDict["suggestions"] as? [String] ?? []
        if suggestions.isEmpty, let growthTip = archetypeDict["growth_tip"] as? String, !growthTip.isEmpty {
            suggestions = [growthTip]
        }

        let scores = (rawResult["scores"] as? [String: Any])?.compactMapValues { value -> Double? in
            if let number = value as? Double { return number }
            if let number = value as? Int { return Double(number) }
            if let number = value as? NSNumber { return number.doubleValue }
            return nil
        } ?? [:]

        let archetype = RidgitsPackArchetypeResult(
            name: name,
            description: archetypeDict["description"] as? String ?? "",
            characteristics: characteristics,
            suggestions: suggestions,
            idealMatch: archetypeDict["ideal_match"] as? String,
            growthTip: archetypeDict["growth_tip"] as? String
        )

        return PackQuizSavedState(
            answers: answers,
            result: PackQuizScoredResult(archetype: archetype, categoryScores: scores)
        )
    }

    func savePackQuizResults(
        uid: String,
        pack: RidgitsArchetypePack,
        answers: [String: Int],
        result: PackQuizScoredResult
    ) async throws {
        var archetypePayload: [String: Any] = [
            "name": result.archetype.name,
            "description": result.archetype.description,
            "characteristics": result.archetype.characteristics,
            "suggestions": result.archetype.suggestions,
        ]
        if let idealMatch = result.archetype.idealMatch {
            archetypePayload["ideal_match"] = idealMatch
        }
        if let growthTip = result.archetype.growthTip {
            archetypePayload["growth_tip"] = growthTip
        }

        var resultPayload: [String: Any] = ["archetype": archetypePayload]
        if !result.categoryScores.isEmpty {
            resultPayload["scores"] = result.categoryScores
        }

        let payload: [String: Any] = [
            pack.answersKey: answers,
            pack.resultKey: resultPayload,
            pack.completedAtKey: ISO8601DateFormatter().string(from: Date()),
        ]

        try await db.collection("users").document(uid).setData(payload, merge: true)
        await syncCompletedQuizBadges(uid: uid)
    }

    func syncCompletedQuizBadges(uid: String) async {
        let packProfile = await fetchPackProfile(uid: uid)
        let progress = try? await fetchQuizProgress(uid: uid)
        let personalityCompleted = progress.map {
            $0.completed || QuizCatalog.hasEnoughPersonalityAnswers(in: $0.answers)
        } ?? false
        let badges = RidgitsQuizBadgeBuilder.badges(
            packProfile: packProfile,
            personalityQuizCompleted: personalityCompleted
        )
        let payload: [String: Any] = [
            "completedQuizBadges": badges.map(\.firestorePayload),
        ]
        try? await db.collection("users").document(uid).setData(payload, merge: true)
        try? await db.collection("publicProfiles").document(uid).setData(payload, merge: true)
        if var cached = RidgitsProfileCache.shared.profile(for: uid) {
            cached.completedQuizBadges = badges
            RidgitsProfileCache.shared.save(cached)
        }
    }

    func fetchRidgits(userId: String, policy: ProfileFetchPolicy = .cacheFirst) async -> [RidgitChallenge] {
        switch policy {
        case .cacheFirst:
            if let cached = RidgitsRidgitListCache.shared.ridgits(for: userId) {
                if RidgitsRidgitListCache.shared.isStale(uid: userId) {
                    scheduleRidgitListRefresh(uid: userId)
                }
                return cached
            }
            return await fetchRidgits(userId: userId, policy: .networkOnly)
        case .networkOnly:
            let ridgits = await fetchRidgitsFromFirestore(userId: userId)
            let activeIds = await fetchActiveRidgitIdsFromFirestore(uid: userId)
            RidgitsRidgitListCache.shared.save(
                ridgits: ridgits,
                activeRidgitIds: activeIds,
                uid: userId
            )
            return ridgits
        }
    }

    func fetchRidgit(id: String) async -> RidgitChallenge? {
        if let cached = RidgitsRidgitListCache.shared.ridgits(for: Auth.auth().currentUser?.uid ?? "")?
            .first(where: { $0.id == id }) {
            return cached
        }
        guard let doc = try? await db.collection("ridgits").document(id).getDocument(),
              doc.exists,
              let data = doc.data() else { return nil }
        return RidgitChallenge.from(id: doc.documentID, data: data)
    }

    func fetchActiveRidgitIds(uid: String, policy: ProfileFetchPolicy = .cacheFirst) async -> [String] {
        switch policy {
        case .cacheFirst:
            if let cached = RidgitsRidgitListCache.shared.activeRidgitIds(for: uid) {
                if RidgitsRidgitListCache.shared.isStale(uid: uid) {
                    scheduleRidgitListRefresh(uid: uid)
                }
                return cached
            }
            return await fetchActiveRidgitIds(uid: uid, policy: .networkOnly)
        case .networkOnly:
            let ridgits = await fetchRidgitsFromFirestore(userId: uid)
            let activeIds = await fetchActiveRidgitIdsFromFirestore(uid: uid)
            RidgitsRidgitListCache.shared.save(
                ridgits: ridgits,
                activeRidgitIds: activeIds,
                uid: uid
            )
            return activeIds
        }
    }

    func saveActiveRidgitIds(uid: String, ids: [String]) async throws {
        try await db.collection("users").document(uid).setData(["activeRidgitIds": ids], merge: true)
        RidgitsRidgitListCache.shared.updateActiveRidgitIds(ids, uid: uid)
    }

    func addActiveRidgitId(uid: String, ridgitId: String, limit: Int) async throws {
        var ids = await fetchActiveRidgitIdsFromFirestore(uid: uid)
        guard !ids.contains(ridgitId), ids.count < limit else { return }
        ids.append(ridgitId)
        try await saveActiveRidgitIds(uid: uid, ids: ids)
    }

    func removeActiveRidgitId(uid: String, ridgitId: String) async throws {
        var ids = await fetchActiveRidgitIdsFromFirestore(uid: uid)
        ids.removeAll { $0 == ridgitId }
        try await saveActiveRidgitIds(uid: uid, ids: ids)
    }

    func saveRidgit(
        id: String?,
        userId: String,
        title: String,
        questions: [RidgitQuestion],
        profile: RidgitsUserProfile,
        activeSlotLimit: Int? = nil
    ) async throws -> RidgitChallenge {
        let docRef = id.map { db.collection("ridgits").document($0) } ?? db.collection("ridgits").document()
        let isNew = id == nil
        let shareableLink = RidgitsAppLinks.ridgitURL(id: docRef.documentID).absoluteString
        let payload: [String: Any] = [
            "title": title,
            "userId": userId,
            "questions": questions.map { $0.firestorePayload() },
            "profile": profile.ridgitSnapshot(),
            "shareableLink": shareableLink,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        try await docRef.setData(payload, merge: true)
        if isNew, let activeSlotLimit {
            try await addActiveRidgitId(uid: userId, ridgitId: docRef.documentID, limit: activeSlotLimit)
        }
        let ridgits = await fetchRidgits(userId: userId, policy: .networkOnly)
        guard let saved = ridgits.first(where: { $0.id == docRef.documentID }) else {
            throw RidgitsError.server("Could not save ridgit.")
        }
        return saved
    }

    func deleteRidgit(id: String, userId: String) async throws {
        try await db.collection("ridgits").document(id).delete()
        try await removeActiveRidgitId(uid: userId, ridgitId: id)
        _ = await fetchRidgits(userId: userId, policy: .networkOnly)
    }

    private func fetchRidgitsFromFirestore(userId: String) async -> [RidgitChallenge] {
        guard let snapshot = try? await db.collection("ridgits")
            .whereField("userId", isEqualTo: userId)
            .getDocuments() else { return [] }
        return snapshot.documents.compactMap { RidgitChallenge.from(id: $0.documentID, data: $0.data()) }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    private func fetchActiveRidgitIdsFromFirestore(uid: String) async -> [String] {
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let data = doc.data(),
              let ids = data["activeRidgitIds"] as? [String] else { return [] }
        return ids
    }

    private func scheduleRidgitListRefresh(uid: String) {
        guard ridgitListRefreshTasks[uid] == nil else { return }
        ridgitListRefreshTasks[uid] = Task {
            _ = await fetchRidgits(userId: uid, policy: .networkOnly)
            ridgitListRefreshTasks[uid] = nil
        }
    }

    /// Reads the private `birthYear` field off `users/{uid}` (not part of `publicProfiles`).
    /// Used to prompt OAuth (Google/Apple) sign-ups for a birth year, since only the
    /// email/password signup sheet collects it today.
    func fetchBirthYear(uid: String) async -> Int? {
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let data = doc.data() else { return nil }
        if let year = data["birthYear"] as? Int { return year }
        if let year = data["birthYear"] as? Double { return Int(year) }
        if let raw = data["birthYear"] as? String { return Int(raw) }
        return nil
    }

    func saveBirthYear(uid: String, birthYear: Int) async throws {
        let age = Calendar.current.component(.year, from: Date()) - birthYear
        try await db.collection("users").document(uid).setData(
            [
                "birthYear": birthYear,
                "age": age,
                "ageVerificationConfirmed": true,
                "ageVerifiedAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": FieldValue.serverTimestamp(),
            ],
            merge: true
        )
    }

    func isUserSubscribed(uid: String) async -> Bool {
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let data = doc.data() else { return false }
        if data["subscriptionStatus"] as? String == "active" { return true }
        let tier = data["subscriptionTier"] as? String ?? "free"
        return tier == "premium" || tier == "ultra" || tier == "plus"
    }

    func findMatches(
        maxDistance: Int,
        forceRefresh: Bool = false,
        previewCloseMatches: Bool = false
    ) async throws -> RidgitsNearbyMatchesResult {
        guard let uid = Auth.auth().currentUser?.uid else {
            return RidgitsNearbyMatchesResult(matches: [], closeMatchCount: 0, closeMatches: [])
        }

        if !previewCloseMatches,
           !forceRefresh,
           let cached = RidgitsMatchesCache.shared.nearby(for: uid, maxDistance: maxDistance),
           !RidgitsMatchesCache.shared.isNearbyStale(uid: uid, maxDistance: maxDistance) {
            return RidgitsNearbyMatchesResult(matches: cached, closeMatchCount: 0, closeMatches: [])
        }

        let result = try await api.findMatches(
            maxDistance: maxDistance,
            previewCloseMatches: previewCloseMatches
        )
        if !previewCloseMatches {
            RidgitsMatchesCache.shared.saveNearby(result.matches, uid: uid, maxDistance: maxDistance)
        }
        return result
    }

    func findNearbyPool(
        poolRadius: Int,
        poolAccessKey: String,
        forceRefresh: Bool = false
    ) async throws -> RidgitsNearbyMatchesResult {
        guard let uid = Auth.auth().currentUser?.uid else {
            return RidgitsNearbyMatchesResult(matches: [], closeMatchCount: 0, closeMatches: [])
        }

        if !forceRefresh,
           let cached = RidgitsMatchesCache.shared.nearbyPool(for: uid),
           cached.poolRadius >= poolRadius,
           cached.poolAccessKey == poolAccessKey,
           !RidgitsMatchesCache.shared.isNearbyPoolStale(uid: uid) {
            return RidgitsNearbyMatchesResult(
                matches: cached.matches,
                closeMatchCount: cached.closeMatchCount,
                closeMatches: cached.closeMatches
            )
        }

        let result = try await api.findMatches(maxDistance: poolRadius)
        let enrichedMatches = await enrichMatchCompatibilityIfNeeded(result.matches, uid: uid)
        RidgitsMatchesCache.shared.saveNearbyPool(
            enrichedMatches,
            closeMatchCount: result.closeMatchCount,
            closeMatches: result.closeMatches,
            poolRadius: poolRadius,
            poolAccessKey: poolAccessKey,
            uid: uid
        )
        return RidgitsNearbyMatchesResult(
            matches: enrichedMatches,
            closeMatchCount: result.closeMatchCount,
            closeMatches: result.closeMatches
        )
    }

    private func enrichMatchCompatibilityIfNeeded(_ matches: [RidgitsMatch], uid: String) async -> [RidgitsMatch] {
        guard !matches.isEmpty else { return matches }
        guard matches.contains(where: { !$0.compatibility.hasScores }) else { return matches }

        var enriched: [RidgitsMatch] = []
        enriched.reserveCapacity(matches.count)
        for match in matches {
            if match.compatibility.hasScores {
                enriched.append(match)
                continue
            }
            if let compatibility = await RidgitsQuizCompatibility.compatibilityBetween(
                currentUserId: uid,
                otherUserId: match.userId
            ), compatibility.hasScores {
                enriched.append(match.withCompatibility(compatibility))
            } else {
                enriched.append(match)
            }
        }
        return enriched
    }

    func getTopNationwideMatches(limit: Int = 50, forceRefresh: Bool = false) async throws -> [RidgitsMatch] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }

        let cached = RidgitsMatchesCache.shared.nationwide(for: uid, limit: limit)
        let cachedLooksBroken = cached?.isEmpty == false
            && cached?.allSatisfy { $0.compatibility.overall == 0 && $0.compatibility.communication == 0 } == true
        let shouldRefresh = forceRefresh
            || cached == nil
            || cached?.isEmpty == true
            || cachedLooksBroken
            || RidgitsMatchesCache.shared.isNationwideStale(uid: uid, limit: limit)

        if !shouldRefresh, let cached {
            return cached
        }

        var matches = try await api.getTopNationwideMatches(limit: limit, forceRefresh: shouldRefresh)

        let apiLooksBroken = !matches.isEmpty
            && matches.allSatisfy({ $0.compatibility.overall == 0 && $0.compatibility.communication == 0 })
        if apiLooksBroken && !forceRefresh {
            matches = try await api.getTopNationwideMatches(limit: limit, forceRefresh: true)
        }

        matches = await enrichMatchCompatibilityIfNeeded(matches, uid: uid)
        RidgitsMatchesCache.shared.saveNationwide(matches, uid: uid, limit: limit)
        return matches
    }

    nonisolated static func conversationId(for userId: String, and otherUserId: String) -> String {
        [userId, otherUserId].sorted().joined(separator: "_")
    }

    func startConversation(toUserId: String, message: String) async throws -> String {
        try await api.startConversation(toUserId: toUserId, message: message)
    }

    func fetchConversation(conversationId: String, userId: String) async throws -> RidgitsConversation? {
        let doc = try await db.collection("conversations").document(conversationId).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        guard let conversation = RidgitsConversation.from(id: doc.documentID, data: data, currentUserId: userId) else {
            return nil
        }
        return await enrichConversations([conversation], forceRefreshProfiles: true).first
    }

    func approveConversation(conversationId: String) async throws {
        try await api.approveConversation(conversationId: conversationId)
    }

    func declineConversation(conversationId: String) async throws {
        try await api.declineConversation(conversationId: conversationId)
    }

    func withdrawConversation(conversationId: String) async throws {
        try await api.withdrawConversation(conversationId: conversationId)
    }

    func sendMessage(conversationId: String, message: String) async throws {
        try await api.sendMessage(conversationId: conversationId, message: message)
    }

    func markConversationRead(conversationId: String) async throws {
        try await api.markConversationRead(conversationId: conversationId)
    }

    func flagConversation(conversationId: String, reason: String) async throws {
        try await api.flagConversation(conversationId: conversationId, reason: reason)
    }

    func archiveConversation(conversationId: String) async throws {
        try await api.archiveConversation(conversationId: conversationId)
    }

    func unarchiveConversation(conversationId: String) async throws {
        try await api.unarchiveConversation(conversationId: conversationId)
    }

    func fetchMessagingQuota() async throws -> RidgitsMonthlyMessageQuota {
        try await api.fetchMessagingQuota()
    }

    func fetchPublicProfile(uid: String) async -> RidgitsUserProfile? {
        guard let doc = try? await db.collection("publicProfiles").document(uid).getDocument(),
              doc.exists,
              let data = doc.data() else { return nil }
        return RidgitsUserProfile.from(uid: uid, data: data)
    }

    func enrichConversations(
        _ conversations: [RidgitsConversation],
        forceRefreshProfiles: Bool = false
    ) async -> [RidgitsConversation] {
        var enriched: [RidgitsConversation] = []
        enriched.reserveCapacity(conversations.count)

        for conversation in conversations {
            let profile: RidgitsUserProfile?
            if !forceRefreshProfiles,
               let cached = RidgitsPublicProfileCache.shared.profile(for: conversation.otherUserId) {
                profile = cached
            } else if let fetched = await fetchPublicProfile(uid: conversation.otherUserId) {
                RidgitsPublicProfileCache.shared.save(fetched)
                profile = fetched
            } else {
                profile = nil
            }

            guard let profile else {
                let fallbackName = conversation.otherUserName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !fallbackName.isEmpty {
                    enriched.append(conversation)
                } else {
                    enriched.append(
                        conversation.updatingOtherUser(
                            name: "Ridgits member",
                            image: conversation.otherUserImage
                        )
                    )
                }
                continue
            }

            let name = conversation.otherUserName.isEmpty ? profile.name : conversation.otherUserName
            let image = conversation.otherUserImage.isEmpty ? profile.image : conversation.otherUserImage
            let resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Ridgits member"
                : name

            enriched.append(conversation.updatingOtherUser(
                name: resolvedName,
                image: image,
                subscriptionTier: profile.subscriptionTier == "free" ? conversation.otherUserSubscriptionTier : profile.subscriptionTier,
                profilePhotoVerified: profile.profilePhotoVerified
            ))
        }

        return enriched
    }

    private func parseConversationDocuments(_ documents: [QueryDocumentSnapshot], userId: String) -> [RidgitsConversation] {
        documents.compactMap { doc -> RidgitsConversation? in
            let data = doc.data()
            let deletedBy = data["deletedBy"] as? [String] ?? []
            guard let conversation = RidgitsConversation.from(id: doc.documentID, data: data, currentUserId: userId) else {
                return nil
            }
            if deletedBy.contains(userId),
               !conversation.isMessagingClosed,
               conversation.status != .expired {
                return nil
            }
            return conversation
        }
    }

    private func sortConversationsByRecency(_ conversations: [RidgitsConversation]) -> [RidgitsConversation] {
        conversations.sorted {
            ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
        }
    }

    private func fetchConversationDocuments(userId: String, ordered: Bool) async throws -> [QueryDocumentSnapshot] {
        var query: Query = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
        if ordered {
            query = query.order(by: "updatedAt", descending: true)
        }
        let snapshot = try await query.limit(to: 50).getDocuments()
        return snapshot.documents
    }

    func fetchConversations(userId: String, forceRefreshProfiles: Bool = false) async throws -> [RidgitsConversation] {
        let documents: [QueryDocumentSnapshot]
        do {
            documents = try await fetchConversationDocuments(userId: userId, ordered: true)
        } catch {
            RidgitsFirestoreIndexErrorLogging.logIfMissingIndex(error, context: "fetchConversations")
            documents = try await fetchConversationDocuments(userId: userId, ordered: false)
        }

        let conversations = sortConversationsByRecency(parseConversationDocuments(documents, userId: userId))
        return await enrichConversations(conversations, forceRefreshProfiles: forceRefreshProfiles)
    }

    func listenConversations(userId: String, onChange: @escaping ([RidgitsConversation]) -> Void) -> ListenerRegistration {
        let orderedQuery = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)

        let fallbackQuery = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .limit(to: 50)

        var usingFallback = false
        var registration: ListenerRegistration?

        func deliver(_ snapshot: QuerySnapshot?) {
            let conversations = sortConversationsByRecency(
                parseConversationDocuments(snapshot?.documents ?? [], userId: userId)
            )
            Task {
                let enriched = await self.enrichConversations(conversations)
                await MainActor.run {
                    onChange(enriched)
                }
            }
        }

        func attachFallbackListener() {
            guard !usingFallback else { return }
            usingFallback = true
            registration?.remove()
            registration = fallbackQuery.addSnapshotListener { snapshot, error in
                if let error {
                    RidgitsFirestoreIndexErrorLogging.logIfMissingIndex(error, context: "listenConversations(fallback)")
                    Task {
                        let convos = (try? await self.fetchConversations(userId: userId)) ?? []
                        await MainActor.run { onChange(convos) }
                    }
                    return
                }
                deliver(snapshot)
            }
        }

        registration = orderedQuery.addSnapshotListener { snapshot, error in
            if let error {
                RidgitsFirestoreIndexErrorLogging.logIfMissingIndex(error, context: "listenConversations")
                attachFallbackListener()
                Task {
                    let convos = (try? await self.fetchConversations(userId: userId)) ?? []
                    await MainActor.run { onChange(convos) }
                }
                return
            }
            deliver(snapshot)
        }

        return CompositeListenerRegistration {
            registration?.remove()
        }
    }

    private final class CompositeListenerRegistration: NSObject, ListenerRegistration {
        private let onRemove: () -> Void

        init(onRemove: @escaping () -> Void) {
            self.onRemove = onRemove
        }

        func remove() {
            onRemove()
        }
    }

    func listenMessages(conversationId: String, onChange: @escaping ([RidgitsMessage]) -> Void) -> ListenerRegistration {
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                if let error {
                    RidgitsFirestoreIndexErrorLogging.logIfMissingIndex(error, context: "listenMessages(\(conversationId))")
                    return
                }
                let messages = snapshot?.documents.compactMap { doc in
                    RidgitsMessage.from(id: doc.documentID, data: doc.data())
                } ?? []
                onChange(messages)
            }
    }

    func listenConversation(conversationId: String, onChange: @escaping (RidgitsConversation?) -> Void) -> ListenerRegistration {
        db.collection("conversations").document(conversationId).addSnapshotListener { snapshot, _ in
            guard let snapshot, snapshot.exists, let data = snapshot.data(),
                  let userId = Auth.auth().currentUser?.uid,
                  let conversation = RidgitsConversation.from(id: snapshot.documentID, data: data, currentUserId: userId) else {
                onChange(nil)
                return
            }

            Task {
                let enriched = await self.enrichConversations([conversation]).first
                await MainActor.run {
                    onChange(enriched)
                }
            }
        }
    }

    func listenCommunityQuizStats(onChange: @escaping (CommunityQuizStats) -> Void) -> ListenerRegistration {
        db.collection("platformStats").document("community")
            .addSnapshotListener { snapshot, error in
                guard error == nil, let snapshot, snapshot.exists, let data = snapshot.data() else {
                    Task { @MainActor in
                        onChange(CommunityQuizStats())
                    }
                    return
                }

                let totalCompleted = data["totalCompleted"] as? Int ?? 0
                let completedThisMonth = data["completedThisMonth"] as? Int
                    ?? data["completedThisWeek"] as? Int
                    ?? 0

                Task { @MainActor in
                    onChange(
                        CommunityQuizStats(
                            totalCompleted: totalCompleted,
                            completedThisMonth: completedThisMonth
                        )
                    )
                }
            }
    }

    func listenQuestionRatings(
        onChange: @escaping (PopularQuestionRating?, PopularQuestionRating?) -> Void
    ) -> ListenerRegistration {
        db.collection("questionRatingsGlobal")
            .addSnapshotListener { snapshot, error in
                guard error == nil, let snapshot, !snapshot.documents.isEmpty else {
                    Task { @MainActor in
                        onChange(nil, nil)
                    }
                    return
                }

                var mostPopularCommunity: PopularQuestionRating?
                var highestCommunityUpCount = -1
                var mostPopularOriginal: PopularQuestionRating?
                var highestOriginalUpCount = -1

                for document in snapshot.documents {
                    let data = document.data()
                    guard let questionText = data["questionText"] as? String,
                          let upCount = data["upCount"] as? Int else {
                        continue
                    }

                    let rating = PopularQuestionRating(questionText: questionText, upCount: upCount)
                    if data["userSubmitted"] as? Bool == true {
                        if upCount > highestCommunityUpCount {
                            highestCommunityUpCount = upCount
                            mostPopularCommunity = rating
                        }
                    } else if upCount > highestOriginalUpCount {
                        highestOriginalUpCount = upCount
                        mostPopularOriginal = rating
                    }
                }

                Task { @MainActor in
                    onChange(mostPopularCommunity, mostPopularOriginal)
                }
            }
    }

    func listenCommunityArchetypeDistribution(
        onChange: @escaping ([String: Int]) -> Void
    ) -> ListenerRegistration {
        db.collection("quizProgress")
            .whereField("completed", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                guard error == nil, let snapshot else {
                    Task { @MainActor in
                        onChange(Self.emptyArchetypeDistribution)
                    }
                    return
                }

                var distribution = Self.emptyArchetypeDistribution
                for document in snapshot.documents {
                    guard let archetypeName = Self.normalizedArchetypeName(from: document.data()) else {
                        continue
                    }
                    if distribution.keys.contains(archetypeName) {
                        distribution[archetypeName, default: 0] += 1
                    }
                }

                Task { @MainActor in
                    onChange(distribution)
                }
            }
    }

    func submitQuestionIdea(idea: String, userId: String?) async throws {
        let trimmed = idea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var payload: [String: Any] = [
            "idea": trimmed,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending",
            "source": "ios-dashboard",
        ]
        if let userId {
            payload["userId"] = userId
        }

        try await db.collection("questionIdeas").addDocument(data: payload)
    }

    private static let emptyArchetypeDistribution: [String: Int] = [
        "The Deep Connector": 0,
        "The Enthusiast": 0,
        "The Independent Spirit": 0,
        "The Explorer": 0,
        "The Steady Builder": 0,
        "The Pragmatist": 0,
        "The Free Spirit": 0,
        "The Well-Rounded": 0,
    ]

    private static let legacyArchetypeNameMap: [String: String] = [
        "The Hopeless Romantic": "The Deep Connector",
        "The Thoughtful Partner": "The Enthusiast",
        "The Adventure Seeker": "The Explorer",
        "The Slow Burn": "The Steady Builder",
        "The Practical Partner": "The Pragmatist",
        "The Balanced One": "The Well-Rounded",
    ]

    private static func normalizedArchetypeName(from data: [String: Any]) -> String? {
        guard let archetype = data["archetype"] else { return nil }

        let rawName: String
        if let name = archetype as? String {
            rawName = name
        } else if let dict = archetype as? [String: Any] {
            rawName = (dict["name"] as? String) ?? (dict["title"] as? String) ?? ""
        } else {
            return nil
        }

        guard !rawName.isEmpty else { return nil }
        let mapped = legacyArchetypeNameMap[rawName] ?? rawName
        return emptyArchetypeDistribution.keys.contains(mapped) ? mapped : nil
    }
}

extension Notification.Name {
    static let ridgitsMatchPreferencesDidChange = Notification.Name("ridgitsMatchPreferencesDidChange")
}
