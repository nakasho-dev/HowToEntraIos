import XCTest
@testable import HowToEntraIos

final class AuthStateTests: XCTestCase {

    // MARK: - Default values

    func test_defaultPhase_isLoading() {
        let state = AuthState()
        XCTAssertEqual(state.phase, .loading)
    }

    func test_defaultAlert_isNil() {
        let state = AuthState()
        XCTAssertNil(state.alert)
    }

    func test_defaultIsProcessing_isFalse() {
        let state = AuthState()
        XCTAssertFalse(state.isProcessing)
    }

    // MARK: - Phase Equatable

    func test_loadingPhase_equals() {
        XCTAssertEqual(AuthState.Phase.loading, .loading)
    }

    func test_signedOutPhase_equals() {
        XCTAssertEqual(AuthState.Phase.signedOut, .signedOut)
    }

    func test_signedInPhase_equalsWithSameUser() {
        let user = AuthenticatedUser(displayName: "U", objectId: "1")
        XCTAssertEqual(AuthState.Phase.signedIn(user), .signedIn(user))
    }

    func test_signedInPhase_notEqualsWithDifferentUser() {
        let user1 = AuthenticatedUser(displayName: "A", objectId: "1")
        let user2 = AuthenticatedUser(displayName: "B", objectId: "2")
        XCTAssertNotEqual(AuthState.Phase.signedIn(user1), .signedIn(user2))
    }

    func test_differentPhases_notEqual() {
        XCTAssertNotEqual(AuthState.Phase.loading, .signedOut)
    }
}

final class AuthAlertTests: XCTestCase {

    func test_equality_basedOnMessage() {
        let alert1 = AuthAlert(message: "error")
        let alert2 = AuthAlert(message: "error")
        XCTAssertEqual(alert1, alert2)
    }

    func test_inequality_differentMessages() {
        let alert1 = AuthAlert(message: "error1")
        let alert2 = AuthAlert(message: "error2")
        XCTAssertNotEqual(alert1, alert2)
    }

    func test_id_isNotNil() {
        let alert = AuthAlert(message: "test")
        XCTAssertNotNil(alert.id)
    }

    func test_differentAlerts_haveDifferentIds() {
        let alert1 = AuthAlert(message: "test")
        let alert2 = AuthAlert(message: "test")
        XCTAssertNotEqual(alert1.id, alert2.id)
    }
}

final class AuthenticatedUserTests: XCTestCase {

    func test_equality() {
        let user1 = AuthenticatedUser(displayName: "User", objectId: "123")
        let user2 = AuthenticatedUser(displayName: "User", objectId: "123")
        XCTAssertEqual(user1, user2)
    }

    func test_inequality_differentDisplayName() {
        let user1 = AuthenticatedUser(displayName: "A", objectId: "123")
        let user2 = AuthenticatedUser(displayName: "B", objectId: "123")
        XCTAssertNotEqual(user1, user2)
    }

    func test_inequality_differentObjectId() {
        let user1 = AuthenticatedUser(displayName: "User", objectId: "1")
        let user2 = AuthenticatedUser(displayName: "User", objectId: "2")
        XCTAssertNotEqual(user1, user2)
    }
}
