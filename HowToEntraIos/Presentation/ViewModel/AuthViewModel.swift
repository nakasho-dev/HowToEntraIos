import Foundation
import Observation

@Observable
final class AuthViewModel {
    private let useCase: AuthenticationUseCase
    var state = AuthState()

    init(useCase: AuthenticationUseCase) {
        self.useCase = useCase
    }

    func loadAccount() async {
        state.phase = .loading
        state.alert = nil
        do {
            if let user = try await useCase.loadAccount() {
                state.phase = .signedIn(user)
            } else {
                state.phase = .signedOut
            }
        } catch {
            state.phase = .signedOut
            state.alert = AuthAlert(message: error.localizedDescription)
        }
    }

    func signIn() async {
        guard state.isProcessing == false else { return }
        state.isProcessing = true
        defer { state.isProcessing = false }
        state.alert = nil
        do {
            let user = try await useCase.signIn()
            state.phase = .signedIn(user)
        } catch {
            state.alert = AuthAlert(message: error.localizedDescription)
            state.phase = .signedOut
        }
    }

    func signOut() async {
        guard state.isProcessing == false else { return }
        state.isProcessing = true
        defer { state.isProcessing = false }
        state.alert = nil
        do {
            try await useCase.signOut()
            state.phase = .signedOut
        } catch {
            state.alert = AuthAlert(message: error.localizedDescription)
        }
    }
}
