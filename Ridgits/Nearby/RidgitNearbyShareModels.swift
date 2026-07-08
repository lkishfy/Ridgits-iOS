import Foundation
import MultipeerConnectivity

/// Payload sent over MultipeerConnectivity when sharing a Ridgit quiz nearby.
struct RidgitSharePayload: Codable, Equatable, Identifiable {
    var id: String { ridgitId }

    let ridgitId: String
    let title: String
    let senderName: String
    let senderImageUrl: String?
    let previewQuestion: String?

    static let messageKind = "ridgit_share_v1"

    enum CodingKeys: String, CodingKey {
        case kind
        case ridgitId
        case title
        case senderName
        case senderImageUrl
        case previewQuestion
    }

    init(ridgitId: String, title: String, senderName: String, senderImageUrl: String? = nil, previewQuestion: String?) {
        self.ridgitId = ridgitId
        self.title = title
        self.senderName = senderName
        self.senderImageUrl = senderImageUrl
        self.previewQuestion = previewQuestion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decodeIfPresent(String.self, forKey: .kind)
        guard kind == nil || kind == Self.messageKind else {
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown message kind")
        }
        ridgitId = try container.decode(String.self, forKey: .ridgitId)
        title = try container.decode(String.self, forKey: .title)
        senderName = try container.decode(String.self, forKey: .senderName)
        senderImageUrl = try container.decodeIfPresent(String.self, forKey: .senderImageUrl)
        previewQuestion = try container.decodeIfPresent(String.self, forKey: .previewQuestion)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.messageKind, forKey: .kind)
        try container.encode(ridgitId, forKey: .ridgitId)
        try container.encode(title, forKey: .title)
        try container.encode(senderName, forKey: .senderName)
        try container.encodeIfPresent(senderImageUrl, forKey: .senderImageUrl)
        try container.encodeIfPresent(previewQuestion, forKey: .previewQuestion)
    }
}

enum RidgitSharePhase: Equatable {
    case idle
    case searching
    case inviting(peerName: String)
    case connecting(peerName: String)
    case sending
    case sent(peerName: String)
    case incomingInvite(RidgitSharePayload)
    case received(RidgitSharePayload)
    case failed(String)
}

struct RidgitNearbyPeer: Identifiable, Equatable {
    let id: String
    let displayName: String
    let profileCode: String?

    static func == (lhs: RidgitNearbyPeer, rhs: RidgitNearbyPeer) -> Bool {
        lhs.id == rhs.id
    }
}

struct RidgitPendingShareInvitation: Equatable {
    let peerName: String
    let preview: RidgitSharePayload
}

extension RidgitSharePayload {
    static func decodeInvitationContext(_ data: Data?) -> RidgitSharePayload? {
        guard let data, !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(RidgitSharePayload.self, from: data)
    }

    var invitationContext: Data? {
        try? JSONEncoder().encode(self)
    }
}
