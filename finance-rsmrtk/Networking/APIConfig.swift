import Foundation

enum APIConfig {
    /// Host of the finance-engine gRPC backend. Update after deploying to
    /// Render, e.g. "finance-engine-api.onrender.com".
    static let host = "localhost"
    static let port = 8443
    static let useTLS = false
}
