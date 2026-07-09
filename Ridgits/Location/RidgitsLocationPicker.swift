import SwiftUI

enum RidgitsUSLocations {
    struct StateOption: Identifiable, Hashable {
        let code: String
        let name: String
        var id: String { code }
    }

    struct CityOption: Identifiable, Hashable {
        let city: String
        let stateCode: String
        var id: String { "\(city)|\(stateCode)" }
        var label: String { "\(city), \(stateCode)" }
    }

    private struct CityEntry: Decodable {
        let city: String
        let stateCode: String
    }

    static let states: [StateOption] = [
        StateOption(code: "AL", name: "Alabama"),
        StateOption(code: "AK", name: "Alaska"),
        StateOption(code: "AZ", name: "Arizona"),
        StateOption(code: "AR", name: "Arkansas"),
        StateOption(code: "CA", name: "California"),
        StateOption(code: "CO", name: "Colorado"),
        StateOption(code: "CT", name: "Connecticut"),
        StateOption(code: "DE", name: "Delaware"),
        StateOption(code: "DC", name: "District of Columbia"),
        StateOption(code: "FL", name: "Florida"),
        StateOption(code: "GA", name: "Georgia"),
        StateOption(code: "HI", name: "Hawaii"),
        StateOption(code: "ID", name: "Idaho"),
        StateOption(code: "IL", name: "Illinois"),
        StateOption(code: "IN", name: "Indiana"),
        StateOption(code: "IA", name: "Iowa"),
        StateOption(code: "KS", name: "Kansas"),
        StateOption(code: "KY", name: "Kentucky"),
        StateOption(code: "LA", name: "Louisiana"),
        StateOption(code: "ME", name: "Maine"),
        StateOption(code: "MD", name: "Maryland"),
        StateOption(code: "MA", name: "Massachusetts"),
        StateOption(code: "MI", name: "Michigan"),
        StateOption(code: "MN", name: "Minnesota"),
        StateOption(code: "MS", name: "Mississippi"),
        StateOption(code: "MO", name: "Missouri"),
        StateOption(code: "MT", name: "Montana"),
        StateOption(code: "NE", name: "Nebraska"),
        StateOption(code: "NV", name: "Nevada"),
        StateOption(code: "NH", name: "New Hampshire"),
        StateOption(code: "NJ", name: "New Jersey"),
        StateOption(code: "NM", name: "New Mexico"),
        StateOption(code: "NY", name: "New York"),
        StateOption(code: "NC", name: "North Carolina"),
        StateOption(code: "ND", name: "North Dakota"),
        StateOption(code: "OH", name: "Ohio"),
        StateOption(code: "OK", name: "Oklahoma"),
        StateOption(code: "OR", name: "Oregon"),
        StateOption(code: "PA", name: "Pennsylvania"),
        StateOption(code: "RI", name: "Rhode Island"),
        StateOption(code: "SC", name: "South Carolina"),
        StateOption(code: "SD", name: "South Dakota"),
        StateOption(code: "TN", name: "Tennessee"),
        StateOption(code: "TX", name: "Texas"),
        StateOption(code: "UT", name: "Utah"),
        StateOption(code: "VT", name: "Vermont"),
        StateOption(code: "VA", name: "Virginia"),
        StateOption(code: "WA", name: "Washington"),
        StateOption(code: "WV", name: "West Virginia"),
        StateOption(code: "WI", name: "Wisconsin"),
        StateOption(code: "WY", name: "Wyoming"),
    ]

    private static let nameToCode: [String: String] = {
        Dictionary(uniqueKeysWithValues: states.map { ($0.name.lowercased(), $0.code) })
    }()

    private static let validCodes = Set(states.map(\.code))

    private static let cities: [CityOption] = {
        guard
            let url = Bundle.main.url(forResource: "us_cities", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([CityEntry].self, from: data)
        else {
            return []
        }

        return entries.map { CityOption(city: $0.city, stateCode: $0.stateCode) }
    }()

    private static let citiesByPrefix: [String: [CityOption]] = {
        var buckets: [String: [CityOption]] = [:]
        for option in cities {
            let prefix = String(option.city.prefix(2)).lowercased()
            buckets[prefix, default: []].append(option)
        }
        return buckets
    }()

    struct NormalizedLocation: Equatable {
        let city: String
        let stateCode: String
        let display: String
    }

    static func resolveStateCode(_ token: String) -> String? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.count == 2, trimmed.allSatisfy({ $0.isLetter }) {
            let code = trimmed.uppercased()
            return validCodes.contains(code) ? code : nil
        }

        return nameToCode[trimmed.lowercased()]
    }

    static func normalize(city: String, stateCode: String) -> NormalizedLocation? {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty,
              let code = resolveStateCode(stateCode) else { return nil }

        let normalizedCity = titleCaseCity(trimmedCity)
        let display = "\(normalizedCity), \(code)"
        return NormalizedLocation(city: normalizedCity, stateCode: code, display: display)
    }

    static func displayLabel(city: String, stateCode: String, legacyLocation: String = "") -> String {
        if let normalized = normalize(city: city, stateCode: stateCode) {
            return normalized.display
        }
        let trimmed = legacyLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }

    static func searchCities(_ query: String, limit: Int = 12) -> [CityOption] {
        let (cityQuery, stateFilter) = parseSearchQuery(query)
        let q = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else { return [] }

        let prefix = String(q.prefix(2))
        let bucket = citiesByPrefix[prefix] ?? []

        return bucket
            .filter { option in
                cityMatchesQuery(
                    option.city,
                    stateCode: option.stateCode,
                    query: q,
                    stateFilter: stateFilter
                )
            }
            .sorted { lhs, rhs in
                let lhsScore = matchScore(city: lhs.city, stateCode: lhs.stateCode, query: q, stateFilter: stateFilter)
                let rhsScore = matchScore(city: rhs.city, stateCode: rhs.stateCode, query: q, stateFilter: stateFilter)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                return lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    static func parseSearchQuery(_ query: String) -> (cityQuery: String, stateFilter: String?) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let commaParts = trimmed
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if commaParts.count >= 2, let code = resolveStateCode(commaParts[commaParts.count - 1]) {
            let cityPart = commaParts.dropLast().joined(separator: ", ")
            return (cityPart, code)
        }

        return (trimmed, nil)
    }

    private static func cityMatchesQuery(
        _ city: String,
        stateCode: String,
        query: String,
        stateFilter: String?
    ) -> Bool {
        if let stateFilter, stateCode.uppercased() != stateFilter.uppercased() {
            return false
        }

        let cityLower = city.lowercased()
        let labelLower = "\(cityLower), \(stateCode.lowercased())"
        if cityLower.hasPrefix(query) || labelLower.contains(query) {
            return true
        }

        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return false }

        var searchStart = cityLower.startIndex
        for token in tokens {
            guard let range = cityLower[searchStart...].range(of: token) else { return false }
            searchStart = range.upperBound
        }
        return true
    }

    private static func matchScore(city: String, stateCode: String, query: String, stateFilter: String?) -> Int {
        if let stateFilter, stateCode.uppercased() != stateFilter.uppercased() {
            return 100
        }
        let cityLower = city.lowercased()
        if cityLower == query { return 0 }
        if cityLower.hasPrefix(query) { return 1 }
        if cityLower.contains(query) { return 2 }
        return 3
    }

    private static let countryTokens: Set<String> = [
        "usa", "u.s.a.", "u.s.a", "us", "united states", "united states of america", "america",
    ]

    private static func stripTrailingCountryParts(_ parts: [String]) -> [String] {
        var result = parts
        while !result.isEmpty {
            let last = result[result.count - 1].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if countryTokens.contains(last) {
                result.removeLast()
            } else {
                break
            }
        }
        return result
    }

    static func parse(_ location: String, city: String = "", stateCode: String = "") -> (city: String, stateCode: String) {
        if let normalized = normalize(city: city, stateCode: stateCode) {
            return (normalized.city, normalized.stateCode)
        }

        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", "") }

        let commaParts = stripTrailingCountryParts(
            trimmed
                .split(separator: ",", omittingEmptySubsequences: true)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )

        if commaParts.count >= 2,
           let code = resolveStateCode(commaParts.last ?? "") {
            let cityParts = commaParts.dropLast()
            let parsedCity = dedupeCityParts(Array(cityParts))
            if !parsedCity.isEmpty {
                return (titleCaseCity(parsedCity), code)
            }
        }

        if let match = trimmed.range(of: #"[,\s]+([A-Za-z]{2})$"#, options: .regularExpression) {
            let codeToken = String(trimmed[match]).trimmingCharacters(in: CharacterSet(charactersIn: ", "))
            if let code = resolveStateCode(codeToken) {
                let cityPart = trimmed[..<match.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                if !cityPart.isEmpty {
                    return (titleCaseCity(cityPart), code)
                }
            }
        }

        return ("", "")
    }

    static func applyNormalizedLocation(to profile: inout RidgitsUserProfile) {
        if let normalized = normalize(city: profile.locationCity, stateCode: profile.locationStateCode) {
            profile.locationCity = normalized.city
            profile.locationStateCode = normalized.stateCode
            profile.location = normalized.display
            return
        }

        let parsed = parse(profile.location, city: profile.locationCity, stateCode: profile.locationStateCode)
        if let normalized = normalize(city: parsed.city, stateCode: parsed.stateCode) {
            profile.locationCity = normalized.city
            profile.locationStateCode = normalized.stateCode
            profile.location = normalized.display
        }
    }

    private static func dedupeCityParts(_ parts: [String]) -> String {
        guard let first = parts.first else { return "" }
        if parts.count == 1 { return first }
        let lowerFirst = first.lowercased()
        if parts.allSatisfy({ $0.lowercased() == lowerFirst }) {
            return first
        }
        return first
    }

    private static func titleCaseCity(_ value: String) -> String {
        value
            .split(whereSeparator: \.isWhitespace)
            .map { part in
                let token = String(part)
                if token.count <= 3 && token == token.uppercased() { return token }
                return token.prefix(1).uppercased() + token.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }

    static func resolveDraftSelection(_ query: String) -> NormalizedLocation? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let suggestions = searchCities(trimmed)
        if let exact = suggestions.first(where: { $0.label.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            return normalize(city: exact.city, stateCode: exact.stateCode)
        }

        if suggestions.count == 1, trimmed.compare(suggestions[0].city, options: .caseInsensitive) == .orderedSame {
            let only = suggestions[0]
            return normalize(city: only.city, stateCode: only.stateCode)
        }

        let needle = trimmed.lowercased()
        if needle.count >= 2 {
            let cityMatches = suggestions.filter { $0.city.lowercased() == needle }
            if cityMatches.count == 1, let match = cityMatches.first {
                return normalize(city: match.city, stateCode: match.stateCode)
            }

            let prefixMatches = suggestions.filter { $0.city.lowercased().hasPrefix(needle) }
            if prefixMatches.count == 1, let match = prefixMatches.first {
                return normalize(city: match.city, stateCode: match.stateCode)
            }
        }

        let parsed = parse(trimmed)
        return normalize(city: parsed.city, stateCode: parsed.stateCode)
    }

    static func resolveDraftSelectionAsync(_ query: String) async -> NormalizedLocation? {
        resolveDraftSelection(query)
    }
}

struct RidgitsLocationPicker: View {
    @Binding var city: String
    @Binding var stateCode: String
    @Binding var query: String
    var legacyLocation: String = ""
    /// Increment from parent to flush typed city text into bindings before save.
    var commitNonce: Int = 0

    @State private var isOpen = false
    @State private var suggestions: [RidgitsUSLocations.CityOption] = []
    @State private var validationMessage: String?
    @State private var didInitializeQuery = false
    @FocusState private var isFocused: Bool

    private var hasValidSelection: Bool {
        RidgitsUSLocations.normalize(city: city, stateCode: stateCode) != nil
    }

    private var showLegacyHint: Bool {
        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            stateCode.isEmpty &&
            !legacyLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RidgitsTextField(
                placeholder: "Search city and state",
                text: $query
            )
            .focused($isFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onChange(of: query) { _, newValue in
                guard isFocused else { return }
                validationMessage = nil
                isOpen = true
                suggestions = RidgitsUSLocations.searchCities(newValue)
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    isOpen = true
                    validationMessage = nil
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        Task { await commitQueryOnBlur() }
                        isOpen = false
                        suggestions = []
                    }
                }
            }
            .onAppear {
                guard !didInitializeQuery else { return }
                didInitializeQuery = true
                syncQueryFromSelection()
            }
            .onChange(of: commitNonce) { _, _ in
                Task { await commitQueryOnBlur() }
            }
            .onChange(of: city) { _, _ in syncQueryFromSelection() }
            .onChange(of: stateCode) { _, _ in syncQueryFromSelection() }
            .onChange(of: legacyLocation) { _, _ in syncQueryFromSelection() }
            .overlay(alignment: .topLeading) {
                if isOpen && isFocused && !suggestions.isEmpty {
                    suggestionsDropdown
                        .offset(y: 52)
                        .zIndex(20)
                }
            }
            .zIndex(isOpen && isFocused ? 10 : 0)

            if let validationMessage {
                Text(validationMessage)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.destructive)
            } else if showLegacyHint {
                Text("Current location: \(legacyLocation). Select a city from the list to improve nearby matching.")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            } else if isFocused && query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && suggestions.isEmpty {
                Text("No matches found. Try a nearby city or type City, ST (e.g. East Providence, RI).")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
        }
    }

    private var suggestionsDropdown: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(suggestions) { option in
                    Button {
                        select(option)
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(RidgitsTypography.body(14))
                                .foregroundStyle(RidgitsColors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RidgitsColors.inputSurface)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if option.id != suggestions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxHeight: 220)
        .background(RidgitsColors.inputSurface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    private func syncQueryFromSelection() {
        guard !isFocused else { return }
        query = RidgitsUSLocations.displayLabel(
            city: city,
            stateCode: stateCode,
            legacyLocation: legacyLocation
        )
        if hasValidSelection {
            validationMessage = nil
        }
    }

    private func commitQueryOnBlur() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if hasValidSelection {
                syncQueryFromSelection()
            } else {
                validationMessage = "City and state are required."
            }
            return
        }

        if let normalized = await RidgitsUSLocations.resolveDraftSelectionAsync(trimmed) {
            applySelection(
                city: normalized.city,
                stateCode: normalized.stateCode,
                label: normalized.display
            )
            return
        }

        if hasValidSelection {
            syncQueryFromSelection()
            return
        }

        validationMessage = "Select a city from the list, or type City, ST (e.g. East Providence, RI)."
    }

    private func applySelection(city newCity: String, stateCode newStateCode: String, label: String) {
        city = newCity
        stateCode = newStateCode
        query = label
        validationMessage = nil
    }

    private func select(_ option: RidgitsUSLocations.CityOption) {
        applySelection(city: option.city, stateCode: option.stateCode, label: option.label)
        isOpen = false
        isFocused = false
        suggestions = []
    }
}
