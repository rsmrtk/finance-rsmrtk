import Foundation
import Observation

@Observable
final class AuthSession {
    private enum Keys {
        static let accessToken = "accessToken"
        static let userID = "userID"
        static let userEmail = "userEmail"
    }

    private(set) var accessToken: String?
    private(set) var userID: String?
    private(set) var userEmail: String?

    var isSignedIn: Bool { accessToken != nil }

    init() {
        accessToken = KeychainStore.get(Keys.accessToken)
        userID = KeychainStore.get(Keys.userID)
        userEmail = KeychainStore.get(Keys.userEmail)
    }

    func store(accessToken: String, userID: String, userEmail: String) {
        KeychainStore.set(accessToken, forKey: Keys.accessToken)
        KeychainStore.set(userID, forKey: Keys.userID)
        KeychainStore.set(userEmail, forKey: Keys.userEmail)

        self.accessToken = accessToken
        self.userID = userID
        self.userEmail = userEmail
    }

    func signOut() {
        KeychainStore.delete(Keys.accessToken)
        KeychainStore.delete(Keys.userID)
        KeychainStore.delete(Keys.userEmail)

        accessToken = nil
        userID = nil
        userEmail = nil
    }
}
