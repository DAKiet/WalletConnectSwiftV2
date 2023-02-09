import Foundation

protocol SocketAuthenticating {
    func createAuthToken() throws -> String
}

struct SocketAuthenticator: SocketAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private let didKeyFactory: DIDKeyFactory
    private let relayHost: String

    init(clientIdStorage: ClientIdStoring, didKeyFactory: DIDKeyFactory, relayHost: String) {
        self.clientIdStorage = clientIdStorage
        self.didKeyFactory = didKeyFactory
        self.relayHost = relayHost
    }

    func createAuthToken() throws -> String {
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        return try JWTFactory().createRelayJWT(
            keyPair: keyPair,
            sub: getSubject(),
            aud: getAudience(),
            exp: getExpiry()
        )
    }

    private func getExpiry() -> Int {
        var components = DateComponents()
        components.setValue(1, for: .day)
        // safe to unwrap as the date must be calculated
        let date = Calendar.current.date(byAdding: components, to: Date())!
        return Int(date.timeIntervalSince1970)
    }

    private func getAudience() -> String {
        return "wss://\(relayHost)"
    }

    private func getSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}
