//
//  HowToEntraIosApp.swift
//  HowToEntraIos
//
//  Created by Shinya Nakajima on 2025/11/26.
//

import SwiftUI
import MSAL

@main
struct HowToEntraIosApp: App {
    private let viewModel: AuthViewModel

    init() {
        viewModel = AuthViewModel(useCase: HowToEntraIosApp.makeUseCase())
    }

    var body: some Scene {
        WindowGroup {
            AuthView(viewModel: viewModel)
        }
    }
}

private extension HowToEntraIosApp {
    static func makeUseCase() -> AuthenticationUseCase {
        do {
            let config = try AuthenticationConfig.load()
            let authenticator = try MSALAuthenticator(configuration: config.makeApplicationConfig())
            let repository = MSALAuthenticationRepository(authenticator: authenticator, config: config)
            return DefaultAuthenticationUseCase(repository: repository)
        } catch {
            assertionFailure("Authentication configuration error: \(error.localizedDescription)")
            return DefaultAuthenticationUseCase(repository: FailingAuthenticationRepository(error: error))
        }
    }
}

private struct FailingAuthenticationRepository: AuthenticationRepository {
    let error: Error
    func loadAccount() async throws -> AuthenticatedUser? { throw error }
    func signIn() async throws -> AuthenticatedUser { throw error }
    func signOut() async throws { throw error }
    func getAccessToken(for scopes: [String]) async throws -> String { throw error }
}
