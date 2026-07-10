import Foundation

/// A value-type description of a native alert, letting view models present
/// alerts without importing SwiftUI. Bind it with `View.appAlert(_:)`.
public struct AppAlert: Identifiable {

    public let id = UUID()
    public let title: String
    public let message: String
    public let buttons: [AlertButton]

    public init(
        title: String,
        message: String,
        buttons: [AlertButton]
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }

    public struct AlertButton {
        public let title: String
        public let role: ButtonRole?
        public let action: (() -> Void)?

        public init(
            title: String,
            role: ButtonRole? = nil,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.role = role
            self.action = action
        }
    }

    public enum ButtonRole {
        case cancel
        case destructive
    }

}

// MARK: - Factory Methods

public extension AppAlert {

    /// A single-button informational alert.
    static func ok(
        title: String,
        message: String,
        okTitle: String = "OK"
    ) -> AppAlert {
        AppAlert(
            title: title,
            message: message,
            buttons: [AlertButton(title: okTitle)]
        )
    }

    /// An error alert. When a `retryHandler` is supplied the alert offers
    /// retry/cancel, otherwise a single dismiss button.
    static func error(
        _ error: Error,
        title: String,
        okTitle: String = "OK",
        retryTitle: String = "Retry",
        cancelTitle: String = "Cancel",
        retryHandler: (() -> Void)? = nil
    ) -> AppAlert {
        if let retryHandler {
            return AppAlert(
                title: title,
                message: error.localizedDescription,
                buttons: [
                    AlertButton(title: retryTitle, action: retryHandler),
                    AlertButton(title: cancelTitle, role: .cancel)
                ]
            )
        } else {
            return AppAlert(
                title: title,
                message: error.localizedDescription,
                buttons: [AlertButton(title: okTitle)]
            )
        }
    }

    /// A confirm/cancel alert.
    static func confirmation(
        title: String,
        message: String,
        confirmTitle: String = "OK",
        confirmRole: ButtonRole? = nil,
        onConfirm: @escaping () -> Void,
        cancelTitle: String = "Cancel",
        onCancel: (() -> Void)? = nil
    ) -> AppAlert {
        AppAlert(
            title: title,
            message: message,
            buttons: [
                AlertButton(title: confirmTitle, role: confirmRole, action: onConfirm),
                AlertButton(title: cancelTitle, role: .cancel, action: onCancel)
            ]
        )
    }

}
