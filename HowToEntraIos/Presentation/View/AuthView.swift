import SwiftUI
import MapLibre
import MapLibreSwiftUI
import MapLibreSwiftDSL
import CoreLocation

enum AzureMapStyle: String, CaseIterable, Identifiable {
    case road = "microsoft.base.road"
    case darkgrey = "microsoft.base.darkgrey"
    case imagery = "microsoft.imagery"
    case hybridRoad = "microsoft.base.hybrid.road"
    case hybridDarkgrey = "microsoft.base.hybrid.darkgrey"
    case terra = "microsoft.terra.main"
    case weatherRadar = "microsoft.weather.radar.main"
    case weatherInfrared = "microsoft.weather.infrared.main"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .road: return "道路"
        case .darkgrey: return "ダークグレー"
        case .imagery: return "衛星画像"
        case .hybridRoad: return "ハイブリッド(道路)"
        case .hybridDarkgrey: return "ハイブリッド(ダークグレー)"
        case .terra: return "地形"
        case .weatherRadar: return "気象レーダー"
        case .weatherInfrared: return "赤外線"
        }
    }
    
    var styleURL: URL {
        let styleJson = """
        {
          "version": 8,
          "sources": {
            "azure-maps-raster": {
              "type": "raster",
              "tiles": [
                "https://atlas.microsoft.com/map/tile?api-version=2024-04-01&tilesetId=\(rawValue)&zoom={z}&x={x}&y={y}&tileSize=256"
              ],
              "tileSize": 256
            }
          },
          "layers": [
            {
              "id": "azure-maps-raster-layer",
              "type": "raster",
              "source": "azure-maps-raster",
              "paint": {}
            }
          ]
        }
        """
        
        let fileName = "azure-maps-style-\(rawValue.replacingOccurrences(of: ".", with: "-")).json"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? styleJson.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

struct AuthView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var camera = MapViewCamera.center(CLLocationCoordinate2D(latitude: 35.66500, longitude: 139.73942), zoom: 16)
    @State private var selectedMapStyle: AzureMapStyle = .road
    @State private var mapKey: UUID = UUID()

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
            Text("Microsoft Entra ID")
                .font(.title)
            Button {
                Task { await viewModel.signIn() }
            } label: {
                Label("Sign In", systemImage: "person.crop.circle.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state.isProcessing)
        }
    }

    private func signedInView(_ user: AuthenticatedUser) -> some View {
        ZStack(alignment: .topLeading) {
            MapView(styleURL: selectedMapStyle.styleURL, camera: $camera)
                .ignoresSafeArea()
                .id(mapKey)

            VStack(alignment: .leading, spacing: 16) {
                Text("ようこそ, \(user.displayName)")
                    .font(.headline)
                
                Picker("地図スタイル", selection: $selectedMapStyle) {
                    ForEach(AzureMapStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: selectedMapStyle) { _, _ in
                    mapKey = UUID()
                }
                
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
