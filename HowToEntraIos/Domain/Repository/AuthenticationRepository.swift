import Foundation

protocol AuthenticationRepository {
    func loadAccount() async throws -> AuthenticatedUser?
    func signIn() async throws -> AuthenticatedUser
    func signOut() async throws
}
