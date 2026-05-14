import Foundation
import SwiftUI

@MainActor
final class UserStore: ObservableObject {
    static let shared = UserStore()

    @Published private(set) var user: PollyUser?

    private let storageKey = "polly.user.v1"

    init() {
        load()
    }

    var isSignedIn: Bool { user != nil }

    func signIn(_ user: PollyUser) {
        self.user = user
        persist()
    }

    func updateName(_ name: String) {
        guard var current = user else { return }
        current.name = name
        self.user = current
        persist()
    }

    func signOut() {
        user = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(PollyUser.self, from: data)
        else { return }
        user = decoded
    }

    private func persist() {
        guard let user, let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
