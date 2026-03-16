import XCTest
@testable import HowToEntraIos

final class DefaultAuthenticationUseCaseTests: XCTestCase {

    // MARK: - loadAccount

    func test_loadAccount_delegatesToRepository() async throws {
        let expected = AuthenticatedUser(displayName: "User", objectId: "123")
        let repository = MockAuthenticationRepository()
        repository.loadAccountResult = expected
        let sut = DefaultAuthenticationUseCase(repository: repository)

        let result = try await sut.loadAccount()

        XCTAssertEqual(result, expected)
    }

    func test_loadAccount_returnsNilWhenRepositoryReturnsNil() async throws {
        let repository = MockAuthenticationRepository()
        repository.loadAccountResult = nil
        let sut = DefaultAuthenticationUseCase(repository: repository)

        let result = try await sut.loadAccount()

        XCTAssertNil(result)
    }

    func test_loadAccount_throwsWhenRepositoryThrows() async {
        let repository = MockAuthenticationRepository()
        repository.error = MockError.test
        let sut = DefaultAuthenticationUseCase(repository: repository)

        do {
            _ = try await sut.loadAccount()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }

    // MARK: - signIn

    func test_signIn_delegatesToRepository() async throws {
        let expected = AuthenticatedUser(displayName: "Signed In", objectId: "456")
        let repository = MockAuthenticationRepository()
        repository.signInResult = expected
        let sut = DefaultAuthenticationUseCase(repository: repository)

        let result = try await sut.signIn()

        XCTAssertEqual(result, expected)
    }

    func test_signIn_throwsWhenRepositoryThrows() async {
        let repository = MockAuthenticationRepository()
        repository.error = MockError.test
        let sut = DefaultAuthenticationUseCase(repository: repository)

        do {
            _ = try await sut.signIn()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }

    // MARK: - signOut

    func test_signOut_delegatesToRepository() async throws {
        let repository = MockAuthenticationRepository()
        let sut = DefaultAuthenticationUseCase(repository: repository)

        try await sut.signOut()

        XCTAssertTrue(repository.signOutCalled)
    }

    func test_signOut_throwsWhenRepositoryThrows() async {
        let repository = MockAuthenticationRepository()
        repository.error = MockError.test
        let sut = DefaultAuthenticationUseCase(repository: repository)

        do {
            try await sut.signOut()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }

    // MARK: - getAccessToken

    func test_getAccessToken_delegatesToRepository() async throws {
        let repository = MockAuthenticationRepository()
        repository.accessToken = "test-token"
        let sut = DefaultAuthenticationUseCase(repository: repository)

        let token = try await sut.getAccessToken(for: ["scope1"])

        XCTAssertEqual(token, "test-token")
        XCTAssertEqual(repository.lastRequestedScopes, ["scope1"])
    }

    func test_getAccessToken_throwsWhenRepositoryThrows() async {
        let repository = MockAuthenticationRepository()
        repository.error = MockError.test
        let sut = DefaultAuthenticationUseCase(repository: repository)

        do {
            _ = try await sut.getAccessToken(for: ["scope1"])
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }
}

// MARK: - Test Helpers

private enum MockError: Error {
    case test
}

private final class MockAuthenticationRepository: AuthenticationRepository {
    var loadAccountResult: AuthenticatedUser?
    var signInResult: AuthenticatedUser = AuthenticatedUser(displayName: "Default", objectId: "0")
    var accessToken: String = "default-token"
    var error: Error?
    var signOutCalled = false
    var lastRequestedScopes: [String]?

    func loadAccount() async throws -> AuthenticatedUser? {
        if let error { throw error }
        return loadAccountResult
    }

    func signIn() async throws -> AuthenticatedUser {
        if let error { throw error }
        return signInResult
    }

    func signOut() async throws {
        if let error { throw error }
        signOutCalled = true
    }

    func getAccessToken(for scopes: [String]) async throws -> String {
        if let error { throw error }
        lastRequestedScopes = scopes
        return accessToken
    }
}
