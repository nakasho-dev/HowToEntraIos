import XCTest
import ViewInspector
@testable import HowToEntraIos

extension AuthView: Inspectable {}

@MainActor
final class AuthViewTests: XCTestCase {
    func test_signedOutState_showsSignInButtonLabel() throws {
        let sut = AuthView(viewModel: makeViewModel(phase: .signedOut))
        let label = try sut.inspect()
            .find(ViewType.Button.self)
            .labelView()
            .text()
            .string()
        XCTAssertEqual(label, "Sign In / Sign Up")
    }

    func test_signedInState_displaysUserInfo() throws {
        let user = AuthenticatedUser(displayName: "田中太郎", email: "taro@example.com", objectId: "object-1")
        let sut = AuthView(viewModel: makeViewModel(phase: .signedIn(user)))
        XCTAssertEqual(try sut.inspect().find(text: "ようこそ, 田中太郎").string(), "ようこそ, 田中太郎")
        XCTAssertEqual(try sut.inspect().find(text: "taro@example.com").string(), "taro@example.com")
        XCTAssertEqual(try sut.inspect().find(text: "object-1").string(), "object-1")
    }

    func test_loadingState_showsProgressView() throws {
        let sut = AuthView(viewModel: makeViewModel(phase: .loading))
        XCTAssertNoThrow(try sut.inspect().find(ViewType.ProgressView.self))
    }

    func test_processingOverlay_showsProgressIndicatorOnlyWhenProcessing() throws {
        let sutProcessing = AuthView(viewModel: makeViewModel(phase: .signedOut, isProcessing: true))
        let sutIdle = AuthView(viewModel: makeViewModel(phase: .signedOut, isProcessing: false))
        XCTAssertNoThrow(try sutProcessing.inspect().find(ViewType.ProgressView.self))
        XCTAssertThrowsError(try sutIdle.inspect().find(ViewType.ProgressView.self))
    }

    func test_signedOutButton_disabledWhileProcessing() throws {
        let sut = AuthView(viewModel: makeViewModel(phase: .signedOut, isProcessing: true))
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(button.isDisabled())
    }

    func test_signedInButton_disabledWhileProcessing() throws {
        let user = AuthenticatedUser(displayName: "A", email: "a@example.com", objectId: "id")
        let sut = AuthView(viewModel: makeViewModel(phase: .signedIn(user), isProcessing: true))
        let button = try sut.inspect().find(ViewType.Button.self, where: { view in
            try view.labelView().text().string().contains("Sign Out")
        })
        XCTAssertTrue(button.isDisabled())
    }

    func test_alertBinding_showsErrorMessage() throws {
        let viewModel = makeViewModel(phase: .signedOut)
        viewModel.state.alert = AuthAlert(message: "network error")
        let sut = AuthView(viewModel: viewModel)
        let alert = try sut.inspect().find(ViewType.Alert.self)
        XCTAssertEqual(try alert.message().text().string(), "network error")
    }

    func test_signInButton_tap_invokesUseCase() async throws {
        let useCase = SpyAuthenticationUseCase()
        let expectation = expectation(description: "signIn called")
        useCase.signInHandler = {
            expectation.fulfill()
            return AuthenticatedUser(displayName: "Spy", email: "spy@example.com", objectId: "spy")
        }
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.phase = .signedOut
        try AuthView(viewModel: viewModel)
            .inspect()
            .find(ViewType.Button.self)
            .tap()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_signOutButton_tap_invokesUseCase() async throws {
        let user = AuthenticatedUser(displayName: "User", email: "user@example.com", objectId: "id")
        let useCase = SpyAuthenticationUseCase()
        let expectation = expectation(description: "signOut called")
        useCase.signOutHandler = {
            expectation.fulfill()
        }
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.phase = .signedIn(user)
        try AuthView(viewModel: viewModel)
            .inspect()
            .find(ViewType.Button.self, where: { view in
                try view.labelView().text().string().contains("Sign Out")
            })
            .tap()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    private func makeViewModel(phase: AuthState.Phase, isProcessing: Bool = false) -> AuthViewModel {
        let viewModel = AuthViewModel(useCase: StubAuthenticationUseCase())
        viewModel.state.phase = phase
        viewModel.state.isProcessing = isProcessing
        return viewModel
    }
}

private final class StubAuthenticationUseCase: AuthenticationUseCase {
    func loadAccount() async throws -> AuthenticatedUser? { nil }
    func signIn() async throws -> AuthenticatedUser { AuthenticatedUser(displayName: "Stub", email: "stub@example.com", objectId: "stub") }
    func signOut() async throws { }
}

private final class SpyAuthenticationUseCase: AuthenticationUseCase {
    var signInHandler: (() -> AuthenticatedUser)?
    var signOutHandler: (() -> Void)?
    var loadAccountHandler: (() -> AuthenticatedUser?)?

    func loadAccount() async throws -> AuthenticatedUser? {
        loadAccountHandler?() ?? nil
    }

    func signIn() async throws -> AuthenticatedUser {
        signInHandler?() ?? AuthenticatedUser(displayName: "Spy", email: "spy@example.com", objectId: "spy")
    }

    func signOut() async throws {
        signOutHandler?()
    }
}
