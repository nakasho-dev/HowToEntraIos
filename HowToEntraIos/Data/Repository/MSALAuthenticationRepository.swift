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
        print("DEBUG [loadAccount]: Starting...")
        print("DEBUG [loadAccount]: Scopes = \(config.scopes)")
        
        if let result = try? await authenticator.acquireTokenSilently(with: config.scopes) {
            print("DEBUG [loadAccount]: Silent token acquired successfully")
            return makeUser(from: result.account)
        }
        print("DEBUG [loadAccount]: Silent token acquisition failed, checking for existing accounts")
        
        if let account = try await authenticator.getAccounts().first {
            print("DEBUG [loadAccount]: Found existing account: \(account.username ?? "unknown")")
            return AuthenticatedUser(displayName: account.username ?? "", email: account.username ?? "", objectId: account.identifier ?? "")
        }
        print("DEBUG [loadAccount]: No account found")
        return nil
    }

    func signIn() async throws -> AuthenticatedUser {
        print("DEBUG [signIn]: Starting...")
        print("DEBUG [signIn]: Scopes = \(config.scopes)")
        
        let parameters = try config.makeWebviewParameters()
        print("DEBUG [signIn]: WebviewParameters created")
        
        let result = try await authenticator.acquireToken(with: config.scopes, webParameters: parameters)
        print("DEBUG [signIn]: Token acquired successfully")
        print("DEBUG [signIn]: Access token (first 50 chars): \(String(result.accessToken.prefix(50)))...")
        print("DEBUG [signIn]: Scopes granted: \(result.scopes)")
        
        return makeUser(from: result.account)
    }

    func signOut() async throws {
        print("DEBUG [signOut]: Starting...")
        guard let account = try await authenticator.getAccounts().first else {
            print("DEBUG [signOut]: No account found to sign out")
            throw MSALAuthenticatorError.missingAccount
        }
        print("DEBUG [signOut]: Removing account: \(account.username ?? "unknown")")
        try await authenticator.removeAccount(account)
        print("DEBUG [signOut]: Account removed successfully")
    }

    func getAccessToken(for scopes: [String]) async throws -> String {
        print("DEBUG [getAccessToken]: Starting...")
        print("DEBUG [getAccessToken]: Requested scopes = \(scopes)")
        
        do {
            // まずサイレント取得を試みる
            print("DEBUG [getAccessToken]: Trying silent token acquisition...")
            let result = try await authenticator.acquireTokenSilently(with: scopes)
            print("DEBUG [getAccessToken]: Silent token acquired successfully")
            print("DEBUG [getAccessToken]: Access token (first 50 chars): \(String(result.accessToken.prefix(50)))...")
            return result.accessToken
        } catch {
            // サイレント取得に失敗した場合は対話的取得を試みる
            print("DEBUG [getAccessToken]: Silent token acquisition failed")
            print("DEBUG [getAccessToken]: Error: \(error)")
            if let nsError = error as NSError? {
                print("DEBUG [getAccessToken]: NSError domain: \(nsError.domain), code: \(nsError.code)")
                print("DEBUG [getAccessToken]: NSError userInfo: \(nsError.userInfo)")
            }
            
            print("DEBUG [getAccessToken]: Trying interactive token acquisition...")
            let parameters = try config.makeWebviewParameters()
            let result = try await authenticator.acquireToken(with: scopes, webParameters: parameters)
            print("DEBUG [getAccessToken]: Interactive token acquired successfully")
            print("DEBUG [getAccessToken]: Access token (first 50 chars): \(String(result.accessToken.prefix(50)))...")
            return result.accessToken
        }
    }

    private func makeUser(from account: MSALAccount) -> AuthenticatedUser {
        print("DEBUG [makeUser]: Creating user from account")
        print("DEBUG [makeUser]: username = \(account.username ?? "nil")")
        print("DEBUG [makeUser]: identifier = \(account.identifier ?? "nil")")
        
        return AuthenticatedUser(
            displayName: account.username ?? "",
            email: account.username ?? "",
            objectId: account.identifier ?? ""
        )
    }
}
