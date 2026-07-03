import Foundation
import JavaScriptCore

enum PackQuizScoring {
    private static let context: JSContext = {
        guard let ctx = JSContext() else {
            fatalError("Unable to create JavaScriptCore context for pack scoring.")
        }
        ctx.exceptionHandler = { _, exception in
            print("[PackQuizScoring] JS error:", exception?.toString() ?? "unknown")
        }
        guard let url = Bundle.main.url(forResource: "pack_scoring", withExtension: "js", subdirectory: "Quiz/Packs")
            ?? Bundle.main.url(forResource: "pack_scoring", withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8) else {
            print("[PackQuizScoring] Missing pack_scoring.js in bundle")
            return ctx
        }
        ctx.evaluateScript(source)
        return ctx
    }()

    static func calculate(packId: String, answers: [String: Int]) -> PackQuizScoredResult? {
        guard let fn = context.objectForKeyedSubscript("calculatePackArchetype"),
              !fn.isUndefined,
              let jsAnswers = jsValue(from: answers) else {
            return nil
        }

        let raw = fn.call(withArguments: [packId, jsAnswers])
        guard let dict = raw?.toDictionary() as? [String: Any] else { return nil }

        let archetypeDict = (dict["archetype"] as? [String: Any]) ?? dict
        guard let name = archetypeDict["name"] as? String, !name.isEmpty else { return nil }

        let characteristics = (archetypeDict["characteristics"] as? [String])
            ?? (archetypeDict["traits"] as? [String])
            ?? []
        var suggestions = archetypeDict["suggestions"] as? [String] ?? []
        if suggestions.isEmpty, let growthTip = archetypeDict["growth_tip"] as? String, !growthTip.isEmpty {
            suggestions = [growthTip]
        }

        let scores = (dict["scores"] as? [String: Any])?.compactMapValues { value -> Double? in
            if let n = value as? Double { return n }
            if let n = value as? Int { return Double(n) }
            if let n = value as? NSNumber { return n.doubleValue }
            return nil
        } ?? [:]

        return PackQuizScoredResult(
            archetype: RidgitsPackArchetypeResult(
                name: name,
                description: archetypeDict["description"] as? String ?? "",
                characteristics: characteristics,
                suggestions: suggestions,
                idealMatch: archetypeDict["ideal_match"] as? String,
                growthTip: archetypeDict["growth_tip"] as? String
            ),
            categoryScores: scores
        )
    }

    private static func jsValue(from answers: [String: Int]) -> JSValue? {
        guard let data = try? JSONSerialization.data(withJSONObject: answers),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return context.evaluateScript("(\(json))")
    }
}
