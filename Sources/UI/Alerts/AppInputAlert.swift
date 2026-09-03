import Foundation

/// A value-type description of a text-input alert. SwiftUI's native `alert`
/// cannot host text fields, so ``AppInputAlertModifier`` renders a custom card.
/// Bind it with `View.appInputAlert(_:)`.
public struct AppInputAlert: Identifiable {

    public let id = UUID()
    public let title: String
    public let message: String?
    public let fields: [InputField]
    public let buttons: [AlertButton]

    public init(
        title: String,
        message: String? = nil,
        fields: [InputField],
        buttons: [AlertButton]
    ) {
        self.title = title
        self.message = message
        self.fields = fields
        self.buttons = buttons
    }

    public struct InputField: Identifiable {
        public let id = UUID()
        public let placeholder: String
        public let defaultValue: String
        public let isSecure: Bool
        public let capitalization: Capitalization
        /// Named to match SwiftUI's own `autocorrectionDisabled(_:)`, and `false` by default so a
        /// field behaves like a plain `TextField`. It used to be forced on for every field. Pass
        /// `true` for a reference, a code, or anything else autocorrect would mangle.
        public let autocorrectionDisabled: Bool

        public init(
            placeholder: String,
            defaultValue: String = "",
            isSecure: Bool = false,
            capitalization: Capitalization = .sentences,
            autocorrectionDisabled: Bool = false
        ) {
            self.placeholder = placeholder
            self.defaultValue = defaultValue
            self.isSecure = isSecure
            self.capitalization = capitalization
            self.autocorrectionDisabled = autocorrectionDisabled
        }
    }

    /// How the keyboard capitalises what's typed into a field.
    ///
    /// Its own type rather than SwiftUI's `TextInputAutocapitalization`, which is UIKit-only while
    /// this file also builds for macOS and watchOS. ``AppInputAlertModifier`` maps it across.
    ///
    /// The default is `.sentences`, matching a plain `TextField`. It used to be forced to `.never`
    /// for every field, which made the alert unusable for anything a person reads — a name typed
    /// into it came out lowercase. Pass `.never` for a username, a code or an email.
    public enum Capitalization: Sendable {
        case never
        case words
        case sentences
        case characters
    }

    public struct AlertButton {
        public let title: String
        public let role: AppAlert.ButtonRole?
        public let action: (([String]) -> Void)?

        public init(
            title: String,
            role: AppAlert.ButtonRole? = nil,
            action: (([String]) -> Void)? = nil
        ) {
            self.title = title
            self.role = role
            self.action = action
        }
    }

}

// MARK: - Factory Methods

public extension AppInputAlert {

    /// A single plain-text input alert with confirm/cancel buttons.
    static func input(
        title: String,
        message: String? = nil,
        placeholder: String,
        defaultValue: String = "",
        capitalization: Capitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        confirmTitle: String = "OK",
        onConfirm: @escaping (String) -> Void,
        cancelTitle: String = "Cancel",
        onCancel: (() -> Void)? = nil
    ) -> AppInputAlert {
        AppInputAlert(
            title: title,
            message: message,
            fields: [
                InputField(
                    placeholder: placeholder,
                    defaultValue: defaultValue,
                    capitalization: capitalization,
                    autocorrectionDisabled: autocorrectionDisabled
                )
            ],
            buttons: [
                AlertButton(title: confirmTitle) { values in
                    onConfirm(values.first ?? "")
                },
                AlertButton(title: cancelTitle, role: .cancel) { _ in
                    onCancel?()
                }
            ]
        )
    }

    /// A single secure (password) input alert with confirm/cancel buttons.
    static func secureInput(
        title: String,
        message: String? = nil,
        placeholder: String,
        confirmTitle: String = "OK",
        onConfirm: @escaping (String) -> Void,
        cancelTitle: String = "Cancel",
        onCancel: (() -> Void)? = nil
    ) -> AppInputAlert {
        AppInputAlert(
            title: title,
            message: message,
            fields: [InputField(placeholder: placeholder, isSecure: true)],
            buttons: [
                AlertButton(title: confirmTitle) { values in
                    onConfirm(values.first ?? "")
                },
                AlertButton(title: cancelTitle, role: .cancel) { _ in
                    onCancel?()
                }
            ]
        )
    }

    /// A multi-field input alert. The confirm handler receives one value per field.
    static func multiInput(
        title: String,
        message: String? = nil,
        fields: [InputField],
        confirmTitle: String = "OK",
        onConfirm: @escaping ([String]) -> Void,
        cancelTitle: String = "Cancel",
        onCancel: (() -> Void)? = nil
    ) -> AppInputAlert {
        AppInputAlert(
            title: title,
            message: message,
            fields: fields,
            buttons: [
                AlertButton(title: confirmTitle, action: onConfirm),
                AlertButton(title: cancelTitle, role: .cancel) { _ in
                    onCancel?()
                }
            ]
        )
    }

}
