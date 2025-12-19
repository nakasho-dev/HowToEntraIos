import SwiftUI
import MapLibre
import MapLibreSwiftUI
import MapLibreSwiftDSL
import CoreLocation

struct AuthView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var camera = MapViewCamera.center(CLLocationCoordinate2D(latitude: 35.66500, longitude: 139.73942), zoom: 14)

    var body: some View {
        Group {
            switch viewModel.state.phase {
            case .loading:
                ProgressView()
            case .signedOut:
                signedOutView
                    .padding()
            case .signedIn(let user):
                signedInView(user)
            }
        }
        .overlay(alignment: .center) {
            if viewModel.state.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .accessibilityLabel("処理中")
            }
        }
        .alert(item: $viewModel.state.alert) { alert in
            Alert(title: Text("エラー"), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
        .task {
            await viewModel.loadAccount()
        }
    }

    private var signedOutView: some View {
        VStack(spacing: 16) {
            Text("Microsoft Entra B2C")
                .font(.title)
            Button {
                Task { await viewModel.signIn() }
            } label: {
                Label("Sign In / Sign Up", systemImage: "person.crop.circle.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state.isProcessing)
        }
    }

    private func signedInView(_ user: AuthenticatedUser) -> some View {
        ZStack(alignment: .topLeading) {
            MapView(styleURL: mapStyleURL, camera: $camera)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("ようこそ, \(user.displayName)")
                    .font(.headline)
                
                Button(role: .destructive) {
                    Task { await viewModel.signOut() }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.state.isProcessing)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospaced())
        }
    }

    private var mapStyleURL: URL {
        if let url = Bundle.main.url(forResource: "azure-maps-style", withExtension: "json") {
            return url
        }
        return URL(string: "https://demotiles.maplibre.org/style.json")!
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(useCase: PreviewAuthenticationUseCase()))
}

private final class PreviewAuthenticationUseCase: AuthenticationUseCase {
    func loadAccount() async throws -> AuthenticatedUser? {
        AuthenticatedUser(displayName: "Preview", objectId: "0000")
    }

    func signIn() async throws -> AuthenticatedUser {
        AuthenticatedUser(displayName: "Preview", objectId: "0000")
    }

    func signOut() async throws { }

    func getAccessToken(for scopes: [String]) async throws -> String {
        "dummy-access-token"
    }
}
