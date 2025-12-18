import Foundation

struct AuthState: Equatable {
    var phase: Phase = .loading
    var alert: AuthAlert?
    var isProcessing: Bool = false

    enum Phase: Equatable {
        case loading
        case signedOut
        case signedIn(AuthenticatedUser)
    }
}

struct AuthAlert: Identifiable, Equatable {
    let id = UUID()
    let message: String

    static func == (lhs: AuthAlert, rhs: AuthAlert) -> Bool {
        lhs.message == rhs.message
    }
}
