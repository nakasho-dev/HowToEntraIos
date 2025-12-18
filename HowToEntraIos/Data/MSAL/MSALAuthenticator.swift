import Foundation
import MSAL

protocol MSALAuthenticating {
    func acquireToken(with scopes: [String], webParameters: MSALWebviewParameters) async throws -> MSALResult
    func acquireTokenSilently(with scopes: [String]) async throws -> MSALResult
    func removeAccount(_ account: MSALAccount) async throws
    func getAccounts() async throws -> [MSALAccount]
}

final class MSALAuthenticator: MSALAuthenticating {
    private let application: MSALPublicClientApplication

    init(configuration: MSALPublicClientApplicationConfig) throws {
        print("DEBUG: Initializing MSALPublicClientApplication...")
        print("DEBUG: Config clientId: \(configuration.clientId)")
        print("DEBUG: Config redirectUri: \(configuration.redirectUri ?? "nil")")
        print("DEBUG: Config authority: \(configuration.authority.url.absoluteString ?? "nil")")

        do {
            application = try MSALPublicClientApplication(configuration: configuration)
            print("DEBUG: MSALPublicClientApplication initialized successfully")
        } catch {
            print("DEBUG: MSALPublicClientApplication initialization FAILED")
            print("DEBUG: Error: \(error)")
            print("DEBUG: Error localizedDescription: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("DEBUG: NSError domain: \(nsError.domain)")
                print("DEBUG: NSError code: \(nsError.code)")
                print("DEBUG: NSError userInfo: \(nsError.userInfo)")
            }
            throw error
        }
    }

    func acquireToken(with scopes: [String], webParameters: MSALWebviewParameters) async throws -> MSALResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MSALResult, Error>) in
            let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webParameters)
            application.acquireToken(with: parameters) { result, error in
                if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: error ?? MSALAuthenticatorError.unknown)
                }
            }
        }
    }

    func acquireTokenSilently(with scopes: [String]) async throws -> MSALResult {
        guard let account = try application.allAccounts().first else {
            throw MSALAuthenticatorError.missingAccount
        }
        let parameters = MSALSilentTokenParameters(scopes: scopes, account: account)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MSALResult, Error>) in
            application.acquireTokenSilent(with: parameters) { result, error in
                if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: error ?? MSALAuthenticatorError.unknown)
                }
            }
        }
    }

    func removeAccount(_ account: MSALAccount) async throws {
        try application.remove(account)
    }

    func getAccounts() async throws -> [MSALAccount] {
        try application.allAccounts()
    }
}

enum MSALAuthenticatorError: LocalizedError {
    case missingAccount
    case removeAccountFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingAccount:
            return "サインイン済みのアカウントが存在しません"
        case .removeAccountFailed:
            return "アカウント削除に失敗しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
