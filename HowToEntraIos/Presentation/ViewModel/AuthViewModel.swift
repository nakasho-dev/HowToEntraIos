import Foundation
import Observation
import MapLibre

@Observable
final class AuthViewModel {
    private let useCase: AuthenticationUseCase
    var state = AuthState()

    init(useCase: AuthenticationUseCase) {
        self.useCase = useCase
    }

    func loadAccount() async {
        print("DEBUG [AuthViewModel.loadAccount]: Starting...")
        state.phase = .loading
        state.alert = nil
        do {
            if let user = try await useCase.loadAccount() {
                print("DEBUG [AuthViewModel.loadAccount]: User loaded: \(user.displayName)")
                state.phase = .signedIn(user)
                await setupMapAuthentication()
            } else {
                print("DEBUG [AuthViewModel.loadAccount]: No user found")
                state.phase = .signedOut
            }
        } catch {
            print("DEBUG [AuthViewModel.loadAccount]: Error: \(error)")
            state.phase = .signedOut
            state.alert = AuthAlert(message: error.localizedDescription)
        }
    }

    func signIn() async {
        print("DEBUG [AuthViewModel.signIn]: Starting...")
        guard state.isProcessing == false else { return }
        state.isProcessing = true
        defer { state.isProcessing = false }
        state.alert = nil
        do {
            let user = try await useCase.signIn()
            print("DEBUG [AuthViewModel.signIn]: User signed in: \(user.displayName)")
            state.phase = .signedIn(user)
            await setupMapAuthentication()
        } catch {
            print("DEBUG [AuthViewModel.signIn]: Error: \(error)")
            if let nsError = error as NSError? {
                print("DEBUG [AuthViewModel.signIn]: NSError domain: \(nsError.domain), code: \(nsError.code)")
            }
            state.alert = AuthAlert(message: error.localizedDescription)
            state.phase = .signedOut
        }
    }

    func signOut() async {
        print("DEBUG [AuthViewModel.signOut]: Starting...")
        guard state.isProcessing == false else { return }
        state.isProcessing = true
        defer { state.isProcessing = false }
        state.alert = nil
        do {
            try await useCase.signOut()
            print("DEBUG [AuthViewModel.signOut]: User signed out")
            state.phase = .signedOut
            // サインアウト時にヘッダーをクリアする
            MLNNetworkConfiguration.sharedManager.sessionConfiguration = nil
        } catch {
            print("DEBUG [AuthViewModel.signOut]: Error: \(error)")
            state.alert = AuthAlert(message: error.localizedDescription)
        }
    }

    private func setupMapAuthentication() async {
        print("DEBUG [AuthViewModel.setupMapAuthentication]: Starting...")
        do {
            let config = try AuthenticationConfig.load()
            print("DEBUG [AuthViewModel.setupMapAuthentication]: Config loaded")
            print("DEBUG [AuthViewModel.setupMapAuthentication]: azureMapsClientId = \(config.azureMapsClientId ?? "nil")")
            print("DEBUG [AuthViewModel.setupMapAuthentication]: scopes from config = \(config.scopes)")
            
            guard let azureMapsClientId = config.azureMapsClientId, !azureMapsClientId.isEmpty else {
                print("DEBUG [AuthViewModel.setupMapAuthentication]: Azure Maps Client ID is not configured.")
                return
            }

            // サインイン時と同じスコープを使用する
            let scopes = config.scopes
            print("DEBUG [AuthViewModel.setupMapAuthentication]: Requesting token for scopes: \(scopes)")
            
            let token = try await useCase.getAccessToken(for: scopes)
            print("DEBUG [AuthViewModel.setupMapAuthentication]: Token acquired (first 50 chars): \(String(token.prefix(50)))...")

            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.httpAdditionalHeaders = [
                "Authorization": "Bearer \(token)",
                "x-ms-client-id": azureMapsClientId
            ]
            MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
            print("DEBUG [AuthViewModel.setupMapAuthentication]: MapLibre authentication configured for Azure Maps.")
        } catch {
            print("DEBUG [AuthViewModel.setupMapAuthentication]: Failed to setup map authentication")
            print("DEBUG [AuthViewModel.setupMapAuthentication]: Error: \(error)")
            if let nsError = error as NSError? {
                print("DEBUG [AuthViewModel.setupMapAuthentication]: NSError domain: \(nsError.domain), code: \(nsError.code)")
                print("DEBUG [AuthViewModel.setupMapAuthentication]: NSError userInfo: \(nsError.userInfo)")
            }
            state.alert = AuthAlert(message: "地図認証の設定に失敗しました: \(error.localizedDescription)")
        }
    }
}
