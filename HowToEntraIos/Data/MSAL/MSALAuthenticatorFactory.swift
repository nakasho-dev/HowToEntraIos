import Foundation
import MSAL

enum MSALAuthenticatorFactory {
    static func makeAuthenticator(config: AuthenticationConfig) throws -> MSALAuthenticating {
        let appConfig = try config.makeApplicationConfig()
        return try MSALAuthenticator(configuration: appConfig)
    }
}
