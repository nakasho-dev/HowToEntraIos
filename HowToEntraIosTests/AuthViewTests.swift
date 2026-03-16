import XCTest
import SwiftUI
import ViewInspector
@testable import HowToEntraIos

@MainActor
final class SignedOutViewTests: XCTestCase {

    func test_showsSignInButtonLabel() throws {
        let sut = SignedOutView(isProcessing: false, onSignIn: {})
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertNoThrow(try button.find(text: "Sign In"))
    }

    func test_showsTitleText() throws {
        let sut = SignedOutView(isProcessing: false, onSignIn: {})
        XCTAssertEqual(try sut.inspect().find(text: "Microsoft Entra ID").string(), "Microsoft Entra ID")
    }

    func test_buttonDisabledWhileProcessing() throws {
        let sut = SignedOutView(isProcessing: true, onSignIn: {})
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(button.isDisabled())
    }

    func test_buttonEnabledWhenNotProcessing() throws {
        let sut = SignedOutView(isProcessing: false, onSignIn: {})
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertFalse(button.isDisabled())
    }

    func test_signInButton_tap_invokesCallback() throws {
        var signInCalled = false
        let sut = SignedOutView(isProcessing: false, onSignIn: { signInCalled = true })
        try sut.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(signInCalled)
    }
}

@MainActor
final class SignedInOverlayViewTests: XCTestCase {

    func test_displaysUserName() throws {
        let user = AuthenticatedUser(displayName: "田中太郎", objectId: "object-1")
        let sut = makeView(user: user)
        XCTAssertEqual(try sut.inspect().find(text: "ようこそ, 田中太郎").string(), "ようこそ, 田中太郎")
    }

    func test_signOutButtonDisabledWhileProcessing() throws {
        let user = AuthenticatedUser(displayName: "A", objectId: "id")
        let sut = makeView(user: user, isProcessing: true)
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(button.isDisabled())
    }

    func test_signOutButtonEnabledWhenNotProcessing() throws {
        let user = AuthenticatedUser(displayName: "A", objectId: "id")
        let sut = makeView(user: user, isProcessing: false)
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertFalse(button.isDisabled())
    }

    func test_signOutButton_tap_invokesCallback() throws {
        var signOutCalled = false
        let user = AuthenticatedUser(displayName: "User", objectId: "id")
        let sut = makeView(user: user, onSignOut: { signOutCalled = true })
        try sut.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(signOutCalled)
    }

    func test_pickerShowsAllMapStyles() throws {
        let user = AuthenticatedUser(displayName: "User", objectId: "id")
        let sut = makeView(user: user)
        let picker = try sut.inspect().find(ViewType.Picker.self)
        let items = try picker.forEach(0).count
        XCTAssertEqual(items, AzureMapStyle.allCases.count)
    }

    private func makeView(
        user: AuthenticatedUser,
        isProcessing: Bool = false,
        onSignOut: @escaping () -> Void = {}
    ) -> SignedInOverlayView {
        SignedInOverlayView(
            user: user,
            isProcessing: isProcessing,
            selectedMapStyle: .constant(.road),
            onSignOut: onSignOut
        )
    }
}

@MainActor
final class AuthViewUseCaseIntegrationTests: XCTestCase {

    func test_signOutButton_tap_invokesUseCase() async throws {
        let user = AuthenticatedUser(displayName: "User", objectId: "id")
        let useCase = SpyAuthenticationUseCase()
        let expectation = expectation(description: "signOut called")
        useCase.signOutHandler = {
            expectation.fulfill()
        }
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.phase = .signedIn(user)

        await viewModel.signOut()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_signInButton_tap_invokesUseCase() async throws {
        let useCase = SpyAuthenticationUseCase()
        let expectation = expectation(description: "signIn called")
        useCase.signInHandler = {
            expectation.fulfill()
            return AuthenticatedUser(displayName: "Spy", objectId: "spy")
        }
        let viewModel = AuthViewModel(useCase: useCase)
        viewModel.state.phase = .signedOut

        await viewModel.signIn()

        await fulfillment(of: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Helpers

private final class SpyAuthenticationUseCase: AuthenticationUseCase {
    var signInHandler: (() -> AuthenticatedUser)?
    var signOutHandler: (() -> Void)?
    var loadAccountHandler: (() -> AuthenticatedUser?)?

    func loadAccount() async throws -> AuthenticatedUser? {
        loadAccountHandler?() ?? nil
    }

    func signIn() async throws -> AuthenticatedUser {
        signInHandler?() ?? AuthenticatedUser(displayName: "Spy", objectId: "spy")
    }

    func signOut() async throws {
        signOutHandler?()
    }

    func getAccessToken(for scopes: [String]) async throws -> String {
        "spy-token"
    }
}
