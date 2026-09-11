import Foundation
import Observation

@Observable
final class AuthSession {
    private enum Keys {
        static let accessToken = "accessToken"
        static let userID = "userID"
        static let userEmail = "userEmail"
        static let isDevSession = "isDevSession"
    }

    private(set) var accessToken: String?
    private(set) var userID: String?
    private(set) var userEmail: String?
    /// True when signed in via AuthService.DevSignIn (the Sign in with Apple
    /// bypass for testing without a paid Apple Developer account) rather
    /// than a real Apple ID.
    private(set) var isDevSession = false

    var isSignedIn: Bool { accessToken != nil }

    init() {
        accessToken = KeychainStore.get(Keys.accessToken)
        userID = KeychainStore.get(Keys.userID)
        userEmail = KeychainStore.get(Keys.userEmail)
        isDevSession = KeychainStore.get(Keys.isDevSession) == "true"
    }

    func store(accessToken: String, userID: String, userEmail: String, isDevSession: Bool = false) {
        KeychainStore.set(accessToken, forKey: Keys.accessToken)
        KeychainStore.set(userID, forKey: Keys.userID)
        KeychainStore.set(userEmail, forKey: Keys.userEmail)
        KeychainStore.set(isDevSession ? "true" : "false", forKey: Keys.isDevSession)

        self.accessToken = accessToken
        self.userID = userID
        self.userEmail = userEmail
        self.isDevSession = isDevSession
    }

    func signOut() {
        KeychainStore.delete(Keys.accessToken)
        KeychainStore.delete(Keys.userID)
        KeychainStore.delete(Keys.userEmail)
        KeychainStore.delete(Keys.isDevSession)

        accessToken = nil
        userID = nil
        userEmail = nil
        isDevSession = false
    }
}
