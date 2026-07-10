#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

public extension UIViewController {

    /// Presents a simple alert with a dismiss button and an optional retry action.
    func showAlert(
        title: String,
        message: String,
        retryTitle: String = "Retry",
        cancelTitle: String = "OK",
        retryHandler: (() -> Void)? = nil,
        cancelHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(
            UIAlertAction(title: cancelTitle, style: .cancel) { _ in
                cancelHandler?()
            }
        )

        if let retryHandler = retryHandler {
            alert.addAction(
                UIAlertAction(title: retryTitle, style: .default) { _ in
                    retryHandler()
                }
            )
        }

        present(alert, animated: true)
    }

}
#endif
