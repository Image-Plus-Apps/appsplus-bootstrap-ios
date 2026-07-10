#if canImport(UIKit) && (os(iOS) || os(tvOS))
import SwiftUI

@available(iOS 17.0, tvOS 17.0, *)
struct AppInputAlertModifier: ViewModifier {

    @Binding var alert: AppInputAlert?
    @State private var isVisible = false
    @State private var fieldValues: [String] = []

    func body(content: Content) -> some View {
        content
            .overlay {
                if alert != nil {
                    alertOverlay
                        .ignoresSafeArea(.all)
                }
            }
            .onChange(of: alert?.id) { _, _ in
                if let currentAlert = alert {
                    fieldValues = currentAlert.fields.map { $0.defaultValue }
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        isVisible = true
                    }
                }
            }
    }

    @ViewBuilder
    private var alertOverlay: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.15 : 0)
                .animation(.easeInOut(duration: 0.25), value: isVisible)

            if isVisible, let alert {
                alertCard(for: alert)
                    .frame(width: 340)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
    }

    private func alertCard(for alert: AppInputAlert) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text(alert.title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            // Message
            if let message = alert.message {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
            }

            // Input fields
            VStack(spacing: 8) {
                ForEach(Array(alert.fields.enumerated()), id: \.element.id) { index, field in
                    inputField(for: field, at: index)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)

            // Buttons
            Group {
                let sorted = sortedButtons(alert.buttons)
                if alert.buttons.count == 2 {
                    HStack(spacing: 8) {
                        ForEach(Array(sorted.enumerated()), id: \.offset) { _, button in
                            alertButton(button)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(sorted.enumerated()), id: \.offset) { _, button in
                            alertButton(button)
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 32))
            } else {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 30, y: 8)
    }

    @ViewBuilder
    private func inputField(for field: AppInputAlert.InputField, at index: Int) -> some View {
        let binding = Binding<String>(
            get: { index < fieldValues.count ? fieldValues[index] : "" },
            set: { newValue in
                if index < fieldValues.count {
                    fieldValues[index] = newValue
                }
            }
        )

        Group {
            if field.isSecure {
                SecureField(field.placeholder, text: binding)
            } else {
                TextField(field.placeholder, text: binding)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 15))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quinary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func alertButton(_ button: AppInputAlert.AlertButton) -> some View {
        let weight: Font.Weight = button.role == .cancel ? .regular : .semibold
        let color: Color = button.role == .destructive ? .red : Color(.label)

        return Button {
            let values = fieldValues
            dismiss()
            button.action?(values)
        } label: {
            Text(button.title)
                .font(.system(size: 17, weight: weight))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Sorts buttons to match native iOS alert behaviour:
    /// - 2 buttons (HStack): cancel left, action/destructive right
    /// - 3+ buttons (VStack): destructive first, then actions, cancel last
    private func sortedButtons(_ buttons: [AppInputAlert.AlertButton]) -> [AppInputAlert.AlertButton] {
        let cancel = buttons.filter { $0.role == .cancel }
        let destructive = buttons.filter { $0.role == .destructive }
        let normal = buttons.filter { $0.role != .cancel && $0.role != .destructive }

        if buttons.count == 2 {
            // HStack: cancel left, action/destructive right
            return cancel + destructive + normal
        } else {
            // VStack: destructive first, then normal actions, cancel last
            return destructive + normal + cancel
        }
    }

    private func dismiss() {
        withAnimation(.spring(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            alert = nil
            fieldValues = []
        }
    }

}

@available(iOS 17.0, tvOS 17.0, *)
public extension View {

    /// Presents a custom text-input alert driven by an optional ``AppInputAlert`` binding.
    func appInputAlert(_ alert: Binding<AppInputAlert?>) -> some View {
        modifier(AppInputAlertModifier(alert: alert))
    }

}
#endif
