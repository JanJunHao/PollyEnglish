import Foundation

struct PollyUser: Codable, Equatable {
    enum SignInMethod: String, Codable {
        case apple
        case phone
        case email
        case guest

        var displayName: String {
            switch self {
            case .apple: return "Apple ID"
            case .phone: return "手机号"
            case .email: return "邮箱"
            case .guest: return "游客模式"
            }
        }
    }

    let id: String
    var name: String
    let method: SignInMethod
    let signedInAt: Date
    var email: String?

    var avatarInitial: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "P" }
        return String(first).uppercased()
    }
}
