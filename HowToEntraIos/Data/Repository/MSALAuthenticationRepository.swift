import Foundation
import MSAL

struct MSALAuthenticationRepository: AuthenticationRepository {
    private let authenticator: MSALAuthenticating
    private let config: AuthenticationConfig

    init(authenticator: MSALAuthenticating, config: AuthenticationConfig) {
        self.authenticator = authenticator
        self.config = config
    }

    func loadAccount() async throws -> AuthenticatedUser? {
        if let result = try? await authenticator.acquireTokenSilently(with: config.scopes) {
            return makeUser(from: result.account)
        }
        if let account = try await authenticator.getAccounts().first {
            return AuthenticatedUser(displayName: account.username ?? "", email: account.username ?? "", objectId: account.identifier ?? "")
        }
        return nil
    }

    func signIn() async throws -> AuthenticatedUser {
        print("DEBUG: signIn() called")
        do {
            let parameters = try config.makeWebviewParameters()
            print("DEBUG: webParameters created")

            // For CIAM, try with empty scopes first (MSAL will add defaults)
            let scopes = config.scopes.isEmpty ? [] : config.scopes
            print("DEBUG: Using scopes: \(scopes)")

            let result = try await authenticator.acquireToken(with: scopes, webParameters: parameters)
            print("DEBUG: acquireToken succeeded")
            return makeUser(from: result.account)
        } catch {
            print("DEBUG: signIn() failed with error: \(error)")
            print("DEBUG: Error localizedDescription: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("DEBUG: NSError domain: \(nsError.domain)")
                print("DEBUG: NSError code: \(nsError.code)")
                print("DEBUG: NSError userInfo: \(nsError.userInfo)")
            }
            throw error
        }
    }

    func signOut() async throws {
        guard let account = try await authenticator.getAccounts().first else {
            throw MSALAuthenticatorError.missingAccount
        }
        try await authenticator.removeAccount(account)
    }

    private func makeUser(from account: MSALAccount) -> AuthenticatedUser {
        AuthenticatedUser(
            displayName: account.username ?? "",
            email: account.username ?? "",
            objectId: account.identifier ?? ""
        )
    }
}
