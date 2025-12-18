import SwiftUI

struct AuthView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            switch viewModel.state.phase {
            case .loading:
                ProgressView()
            case .signedOut:
                signedOutView
            case .signedIn(let user):
                signedInView(user)
            }
        }
        .padding()
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
        VStack(spacing: 16) {
            Text("ようこそ, \(user.displayName)")
                .font(.title)
            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "メール", value: user.email)
                infoRow(label: "ObjectId", value: user.objectId)
            }
            Button(role: .destructive) {
                Task { await viewModel.signOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state.isProcessing)
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
}

#Preview {
    AuthView(viewModel: AuthViewModel(useCase: PreviewAuthenticationUseCase()))
}

private final class PreviewAuthenticationUseCase: AuthenticationUseCase {
    func loadAccount() async throws -> AuthenticatedUser? {
        AuthenticatedUser(displayName: "Preview", email: "preview@example.com", objectId: "0000")
    }

    func signIn() async throws -> AuthenticatedUser {
        AuthenticatedUser(displayName: "Preview", email: "preview@example.com", objectId: "0000")
    }

    func signOut() async throws { }
}
