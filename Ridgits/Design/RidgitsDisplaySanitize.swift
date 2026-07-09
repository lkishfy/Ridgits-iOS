import Foundation

enum RidgitsDisplaySanitize {
    private static let profanityWords: [String] = [
        "anal", "anus", "asshole", "bastard", "bitch", "blowjob", "clit", "cock", "cum", "cunt",
        "deepthroat", "dick", "dildo", "facial", "faggot", "fuck", "gangbang", "handjob", "hentai",
        "jerkoff", "jizz", "kike", "labia", "masturbat", "milf", "motherfucker", "nazi", "negro",
        "nigga", "nigger", "pecker", "penis", "porn", "pussy", "rimjob", "rape", "shemale", "shit",
        "slut", "spic", "titty", "twat", "vagina",
    ]

    private static let profanityPatterns: [String] = [
        #"(f+[\W_]*u+[\W_]*c+[\W_]*k+)"#,
        #"(s+[\W_]*h+[\W_]*i+[\W_]*t+)"#,
        #"(b+[\W_]*i+[\W_]*t+[\W_]*c+[\W_]*h+)"#,
        #"(c+[\W_]*u+[\W_]*n+[\W_]*t+)"#,
        #"(n+[\W_]*i+[\W_]*g+[\W_]*g+[\W_]*a+)"#,
        #"(p+[\W_]*o+[\W_]*r+[\W_]*n+)"#,
    ]

    /// Keeps only the first name token and allowed characters for profile setup.
    static func sanitizeProfileFirstNameInput(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstToken = trimmed
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .first ?? trimmed
        let filtered = firstToken.filter { character in
            character.isLetter || character == "'" || character == "-"
        }
        return String(filtered.prefix(30))
    }

    static func isValidProfileFirstName(_ name: String) -> Bool {
        let sanitized = sanitizeProfileFirstNameInput(name)
        guard !sanitized.isEmpty, sanitized.count <= 30 else { return false }
        guard sanitized.first?.isLetter == true else { return false }
        return sanitized.allSatisfy { $0.isLetter || $0 == "'" || $0 == "-" }
    }

    /// Filters characters while typing but keeps spaces so we can block save if a last name was entered.
    static func filterProfileFirstNameTyping(_ raw: String) -> String {
        let filtered = raw.filter { character in
            character.isLetter || character.isWhitespace || character == "'" || character == "-"
        }
        return String(filtered.prefix(40))
    }

    static func containsLastNameAttempt(_ raw: String) -> Bool {
        raw.contains(where: \.isWhitespace)
    }
    static func profileFirstNameInputFeedback(for raw: String) -> (sanitized: String, attemptedLastName: Bool, validationMessage: String?) {
        let filtered = filterProfileFirstNameTyping(raw)
        if containsLastNameAttempt(filtered) {
            return (filtered, true, nil)
        }
        let sanitized = sanitizeProfileFirstNameInput(filtered)
        if !filtered.isEmpty, sanitized != filtered.trimmingCharacters(in: .whitespacesAndNewlines) {
            return (sanitized, false, "Use letters only.")
        }
        return (sanitized, false, nil)
    }

    static func displayFirstName(_ fullName: String) -> String {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard !trimmed.isEmpty, trimmed.lowercased() != "anonymous" else { return "Someone" }

        if trimmed.contains(",") {
            let afterComma = trimmed.split(separator: ",").last.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !afterComma.isEmpty {
                return afterComma.split(whereSeparator: \.isWhitespace).map(String.init).first ?? afterComma
            }
        }

        let parts = trimmed.split(whereSeparator: \.isWhitespace).map(String.init)
        if parts.count == 1 { return parts[0] }

        if let first = parts.first, first.range(of: #"^[A-Z]\.$"#, options: .regularExpression) != nil, parts.count > 1 {
            return parts[1]
        }

        return parts[0]
    }

    static func sanitizeBio(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        var result = text
        result = maskMatches(in: result, pattern: #"\b(?:https?://|www\.)[^\s]+"#)
        result = maskMatches(in: result, pattern: #"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#, options: [.caseInsensitive])
        result = maskMatches(in: result, pattern: #"\b(?:\+?1[-.\s]?)?(?:\(\d{3}\)|\d{3})[-.\s]?\d{3}[-.\s]?\d{4}\b"#)
        result = maskMatches(in: result, pattern: #"\b(?:\d[\s.\-()]*){7,}\d\b"#)
        result = maskMatches(in: result, pattern: #"@[\w.]{2,}"#)
        result = maskMatches(
            in: result,
            pattern: #"\b(?:snap(?:chat)?|instagram|insta|ig|tik\s*tok|tiktok|whatsapp|telegram|discord|twitter|x\.com|facebook|fb|linkedin|onlyfans|cash\s*app|cashapp|venmo|zelle)\s*[:@]?\s*[\w.]{2,}\b"#,
            options: [.caseInsensitive]
        )
        result = maskProfanity(in: result)
        return result
    }

    private static func maskMatches(
        in text: String,
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return text }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange).reversed()
        var result = text
        for match in matches {
            guard let range = Range(match.range, in: result) else { continue }
            let segment = String(result[range])
            result.replaceSubrange(range, with: String(repeating: "*", count: segment.count))
        }
        return result
    }

    private static func maskProfanity(in text: String) -> String {
        var result = text
        for word in profanityWords {
            result = maskMatches(in: result, pattern: #"\b\#(word)\w*\b"#, options: [.caseInsensitive])
        }
        for pattern in profanityPatterns {
            result = maskMatches(in: result, pattern: pattern, options: [.caseInsensitive])
        }
        return result
    }
}

extension RidgitsMatch {
    var displayFirstName: String {
        RidgitsDisplaySanitize.displayFirstName(name)
    }

    var sanitizedAbout: String? {
        guard let about, !about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return RidgitsDisplaySanitize.sanitizeBio(about)
    }
}
