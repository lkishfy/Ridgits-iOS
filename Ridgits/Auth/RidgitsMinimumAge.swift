import Foundation

enum RidgitsMinimumAge {
    /// Minimum age to create an account or pass Stripe identity verification.
    static let accountYears = 21
    /// Lowest age users can set when filtering matches in profile preferences.
    static let matchFilterYears = 21

    static var underageErrorMessage: String {
        "You must be at least \(accountYears) years old to use Ridgits."
    }

    static var confirmRequiredMessage: String {
        "You must confirm that you are \(accountYears) years or older."
    }

    static func isEligibleAccountAge(birthYear: Int, referenceDate: Date = Date()) -> Bool {
        let age = Calendar.current.component(.year, from: referenceDate) - birthYear
        return age >= accountYears && age <= 120
    }
}
