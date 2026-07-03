import Foundation

enum RidgitsAppLinks {
    /// Replace with your App Store listing URL once the app is live.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/ridgits/id0000000000")!
    static let terms = URL(string: "https://ridgits.com/terms-conditions")!
    static let privacy = URL(string: "https://ridgits.com/privacy-policy")!
    static let urlScheme = "ridgits"

    static func ridgitURL(id: String) -> URL {
        URL(string: "\(urlScheme)://ridgit/\(id)")!
    }

    static func inAppPackURL(id: String) -> URL {
        URL(string: "\(urlScheme)://pack/\(id)")!
    }

    static func parsePackId(from url: URL) -> String? {
        if url.scheme?.lowercased() == urlScheme, url.host?.lowercased() == "pack" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        if url.host?.lowercased() == "ridgits.com" || url.host?.lowercased() == "www.ridgits.com" {
            let parts = url.path.split(separator: "/").map(String.init)
            if parts.count >= 2, parts[0].lowercased() == "pack", !parts[1].isEmpty {
                return parts[1]
            }
        }

        return nil
    }

    static func ridgitShareMessage(title: String, id: String) -> String {
        """
        Take my Ridgit quiz "\(title)" in the Ridgits app — quizzes only work in-app.

        Open in Ridgits: \(ridgitURL(id: id).absoluteString)

        Get Ridgits: \(appStoreURL.absoluteString)
        """
    }

    static func referralURL(code: String) -> URL {
        URL(string: "\(urlScheme)://invite?ref=\(code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? code)")!
    }

    static func parseReferralCode(from url: URL) -> String? {
        if url.scheme?.lowercased() == urlScheme, url.host?.lowercased() == "invite" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let ref = components.queryItems?.first(where: { $0.name.lowercased() == "ref" })?.value {
                let trimmed = ref.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed.uppercased()
            }
        }

        if url.host?.lowercased() == "ridgits.com" || url.host?.lowercased() == "www.ridgits.com" {
            let parts = url.path.split(separator: "/").map(String.init)
            if parts.first?.lowercased() == "invite" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let ref = components.queryItems?.first(where: { $0.name.lowercased() == "ref" })?.value {
                    let trimmed = ref.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed.uppercased()
                }
            }
        }

        return nil
    }

    static func parseRidgitId(from url: URL) -> String? {
        if url.scheme?.lowercased() == urlScheme, url.host?.lowercased() == "ridgit" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        // Legacy web links still open the app when universal links are configured.
        if url.host?.lowercased() == "ridgits.com" || url.host?.lowercased() == "www.ridgits.com" {
            let parts = url.path.split(separator: "/").map(String.init)
            if parts.count >= 2, parts[0].lowercased() == "ridgit", !parts[1].isEmpty {
                return parts[1]
            }
        }

        return nil
    }
}
