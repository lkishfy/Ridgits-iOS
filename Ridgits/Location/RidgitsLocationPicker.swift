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

    static func searchCities(_ query: String, limit: Int = 8) -> [CityOption] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else { return [] }

        return cities
            .filter { option in
                let cityLower = option.city.lowercased()
                let labelLower = option.label.lowercased()
                return cityLower.hasPrefix(q) || labelLower.contains(q)
            }
            .sorted { lhs, rhs in
                let lhsPrefix = lhs.city.lowercased().hasPrefix(q) ? 0 : 1
                let rhsPrefix = rhs.city.lowercased().hasPrefix(q) ? 0 : 1
                if lhsPrefix != rhsPrefix { return lhsPrefix < rhsPrefix }
                return lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    private static let countryTokens: Set<String> = [
        "usa", "u.s.a.", "u.s.a", "us", "united states", "united states of america", "america",
    ]

    private static func stripTrailingCountryParts(_ parts: [String]) -> [String] {
        guard !parts.isEmpty else { return parts }
        let last = parts[parts.count - 1].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if countryTokens.contains(last) {
            return stripTrailingCountryParts(Array(parts.dropLast()))
        }
        return parts
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
}

struct RidgitsLocationPicker: View {
    @Binding var city: String
    @Binding var stateCode: String
    var legacyLocation: String = ""

    @State private var query = ""
    @State private var isOpen = false
    @State private var suggestions: [RidgitsUSLocations.CityOption] = []
    @FocusState private var isFocused: Bool

    private var showLegacyHint: Bool {
        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            stateCode.isEmpty &&
            !legacyLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RidgitsTextField(
                    placeholder: "Search city and state",
                    text: $query
                )
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onChange(of: query) { _, newValue in
                    isOpen = true
                    suggestions = RidgitsUSLocations.searchCities(newValue)
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        isOpen = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isOpen = false
                            query = RidgitsUSLocations.displayLabel(
                                city: city,
                                stateCode: stateCode,
                                legacyLocation: legacyLocation
                            )
                        }
                    }
                }
                .onAppear {
                    query = RidgitsUSLocations.displayLabel(
                        city: city,
                        stateCode: stateCode,
                        legacyLocation: legacyLocation
                    )
                }
                .onChange(of: city) { _, _ in syncQueryFromSelection() }
                .onChange(of: stateCode) { _, _ in syncQueryFromSelection() }
                .onChange(of: legacyLocation) { _, _ in syncQueryFromSelection() }

                if isOpen && !suggestions.isEmpty {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 52)

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
                }
            }

            if showLegacyHint {
                Text("Current location: \(legacyLocation). Select a city from the list to improve nearby matching.")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
        }
    }

    private func syncQueryFromSelection() {
        guard !isFocused else { return }
        query = RidgitsUSLocations.displayLabel(
            city: city,
            stateCode: stateCode,
            legacyLocation: legacyLocation
        )
    }

    private func select(_ option: RidgitsUSLocations.CityOption) {
        city = option.city
        stateCode = option.stateCode
        query = option.label
        isOpen = false
        isFocused = false
        suggestions = []
    }
}
