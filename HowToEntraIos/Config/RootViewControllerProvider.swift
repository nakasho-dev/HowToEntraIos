import UIKit

enum RootViewControllerProvider {
    static func current() throws -> UIViewController {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? scene.windows.first?.rootViewController else {
            throw RootViewControllerError.unableToFindRootViewController
        }
        return root
    }
}

enum RootViewControllerError: LocalizedError {
    case unableToFindRootViewController

    var errorDescription: String? {
        "RootViewController is not available"
    }
}
