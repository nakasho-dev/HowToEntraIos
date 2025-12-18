import XCTest
@testable import HowToEntraIos

@MainActor
final class AuthViewModelTests: XCTestCase {

    func test_loadAccount_whenRepositoryReturnsUser_transitionsToSignedIn() async throws {
        let expectedUser = AuthenticatedUser(displayName: "Test User", email: "test@example.com", objectId: "object-id")
        let useCase = MockAuthenticationUseCase()
        useCase.loadAccountResult = .success(expectedUser)
        let viewModel = AuthViewModel(useCase: useCase)

        await viewModel.loadAccount()

        switch viewModel.state.phase {
        case .signedIn(let user):
            XCTAssertEqual(user, expectedUser)
        default:
            XCTFail("Expected signedIn state")
        }
    }

    func test_loadAccount_whenRepositoryReturnsNil_transitionsToSignedOut() async {
        let useCase = MockAuthenticationUseCase()
        useCase.loadAccountResult = .success(nil)
        let viewModel = AuthViewModel(useCase: useCase)

        await viewModel.loadAccount()

        XCTAssertEqual(viewModel.state.phase, .signedOut)
    }

    func test_signIn_success_updatesStateAndClearsAlert() async throws {
        let expectedUser = AuthenticatedUser(displayName: "User", email: "user@example.com", objectId: "1")
        let useCase = MockAuthenticationUseCase()
        useCase.signInResult = .success(expectedUser)
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.alert = AuthAlert(message: "旧エラー")

        await viewModel.signIn()

        switch viewModel.state.phase {
        case .signedIn(let user):
            XCTAssertEqual(user, expectedUser)
        default:
            XCTFail("State should be signedIn")
        }
        XCTAssertNil(viewModel.state.alert)
    }

    func test_signIn_failure_setsAlertAndKeepsSignedOut() async {
        let useCase = MockAuthenticationUseCase()
        useCase.signInResult = .failure(MockAuthenticationUseCase.MockError.signInFailed)
        let viewModel = AuthViewModel(useCase: useCase)

        await viewModel.signIn()

        XCTAssertEqual(viewModel.state.phase, .signedOut)
        XCTAssertEqual(viewModel.state.alert?.message, MockAuthenticationUseCase.MockError.signInFailed.localizedDescription)
    }

    func test_signOut_success_returnsToSignedOut() async throws {
        let user = AuthenticatedUser(displayName: "User", email: "user@example.com", objectId: "1")
        let useCase = MockAuthenticationUseCase()
        useCase.signOutError = nil
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.phase = .signedIn(user)

        await viewModel.signOut()

        XCTAssertEqual(viewModel.state.phase, .signedOut)
    }

    func test_signOut_failure_setsAlert() async {
        let useCase = MockAuthenticationUseCase()
        useCase.signOutError = MockAuthenticationUseCase.MockError.signOutFailed
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.phase = .signedIn(.init(displayName: "User", email: "user@example.com", objectId: "1"))

        await viewModel.signOut()

        XCTAssertEqual(viewModel.state.alert?.message, MockAuthenticationUseCase.MockError.signOutFailed.localizedDescription)
    }
}

private final class MockAuthenticationUseCase: AuthenticationUseCase {
    enum MockError: Error, LocalizedError {
        case signInFailed
        case signOutFailed

        var errorDescription: String? {
            switch self {
            case .signInFailed:
                return "sign in failed"
            case .signOutFailed:
                return "sign out failed"
            }
        }
    }

    var loadAccountResult: Result<AuthenticatedUser?, Error> = .success(nil)
    var signInResult: Result<AuthenticatedUser, Error> = .failure(MockError.signInFailed)
    var signOutError: Error?

    func loadAccount() async throws -> AuthenticatedUser? {
        try loadAccountResult.get()
    }

    func signIn() async throws -> AuthenticatedUser {
        try signInResult.get()
    }

    func signOut() async throws {
        if let signOutError {
            throw signOutError
        }
    }
}
