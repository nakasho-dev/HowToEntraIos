import Foundation

struct DefaultAuthenticationUseCase: AuthenticationUseCase {
    private let repository: AuthenticationRepository

    init(repository: AuthenticationRepository) {
        self.repository = repository
    }

    func loadAccount() async throws -> AuthenticatedUser? {
        try await repository.loadAccount()
    }

    func signIn() async throws -> AuthenticatedUser {
        try await repository.signIn()
    }

    func signOut() async throws {
        try await repository.signOut()
    }
}
