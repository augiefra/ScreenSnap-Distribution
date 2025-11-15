import Foundation

@MainActor
final class ScreenshotIntentBridge {
    static let shared = ScreenshotIntentBridge()
    weak var appDelegate: AppDelegate?

    enum IntentError: LocalizedError {
        case appUnavailable

        var errorDescription: String? {
            switch self {
            case .appUnavailable:
                return "PastScreen doit être en cours d'exécution pour exécuter cette action."
            }
        }
    }

    func triggerAreaCapture() async throws {
        guard let delegate = appDelegate else { throw IntentError.appUnavailable }
        delegate.performAreaCapture(source: .appIntent)
    }

    func triggerFullScreenCapture() async throws {
        guard let delegate = appDelegate else { throw IntentError.appUnavailable }
        delegate.performFullScreenCapture(source: .appIntent)
    }
}
