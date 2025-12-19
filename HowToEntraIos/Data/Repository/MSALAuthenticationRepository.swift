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
            return makeUser(from: result)
        }
        print("DEBUG [loadAccount]: Silent token acquisition failed, checking for existing accounts")
        
        if let account = try await authenticator.getAccounts().first {
            print("DEBUG [loadAccount]: Found existing account: \(account.username ?? "unknown")")
            // アカウントのみの場合は、表示名が取得できないためusernameを使用
            return AuthenticatedUser(
                displayName: account.username ?? "",
                objectId: account.identifier ?? ""
            )
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
        
        return makeUser(from: result)
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
            print("DEBUG [getAccessToken]: Trying silent token acquisition...")
            let result = try await authenticator.acquireTokenSilently(with: scopes)
            print("DEBUG [getAccessToken]: Silent token acquired successfully")
            print("DEBUG [getAccessToken]: Access token (first 50 chars): \(String(result.accessToken.prefix(50)))...")
            return result.accessToken
        } catch {
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

    private func makeUser(from result: MSALResult) -> AuthenticatedUser {
        let account = result.account
        print("DEBUG [makeUser]: Creating user from MSALResult")
        print("DEBUG [makeUser]: username = \(account.username ?? "nil")")
        print("DEBUG [makeUser]: identifier = \(account.identifier ?? "nil")")
        
        // IDトークンのクレームから表示名を取得
        var displayName = account.username ?? ""
        if let claims = account.accountClaims,
           let name = claims["name"] as? String {
            displayName = name
            print("DEBUG [makeUser]: displayName from claims = \(name)")
        } else {
            print("DEBUG [makeUser]: No name claim found, using username")
        }
        
        return AuthenticatedUser(
            displayName: displayName,
            objectId: account.identifier ?? ""
        )
    }
}
