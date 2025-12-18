import Foundation
import MSAL

struct AuthenticationConfig: Decodable, Sendable {
    let clientId: String
    let tenantDomain: String
    let policyName: String
    let redirectUri: String
    let scopes: [String]
    let authorityUrlString: String?

    private enum CodingKeys: String, CodingKey {
        case clientId = "CLIENT_ID"
        case tenantDomain = "TENANT_DOMAIN"
        case policyName = "POLICY_NAME"
        case redirectUri = "REDIRECT_URI"
        case scopes = "SCOPES"
        case authorityUrlString = "AUTHORITY_URL"
    }

    private var authorityURL: URL {
        if let authorityUrlString, let url = URL(string: authorityUrlString) {
            return url
        }
        return URL(string: "https://\(tenantDomain).b2clogin.com/\(tenantDomain).onmicrosoft.com/\(policyName)")!
    }

    func makeApplicationConfig() throws -> MSALPublicClientApplicationConfig {
        print("DEBUG: Creating MSAL config with:")
        print("  clientId: \(clientId)")
        print("  redirectUri: \(redirectUri)")
        print("  authorityURL: \(authorityURL)")

        let authority = try MSALAuthority(url: authorityURL)
        let config = MSALPublicClientApplicationConfig(clientId: clientId, redirectUri: redirectUri, authority: authority)

        print("DEBUG: MSAL config created successfully")
        return config
    }

    @MainActor
    func makeWebviewParameters() throws -> MSALWebviewParameters {
        let parameters = MSALWebviewParameters(authPresentationViewController: try RootViewControllerProvider.current())
        parameters.webviewType = .default
        return parameters
    }
}

extension AuthenticationConfig {
    static func load() throws -> AuthenticationConfig {
        guard let url = Bundle.main.url(forResource: "AuthenticationConfig", withExtension: "plist") else {
            throw ConfigError.missingFile
        }
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(AuthenticationConfig.self, from: data)
    }

    enum ConfigError: Error {
        case missingFile
    }
}
