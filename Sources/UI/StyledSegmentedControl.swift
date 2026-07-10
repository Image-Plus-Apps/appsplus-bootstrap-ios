#if canImport(UIKit) && (os(iOS) || os(tvOS))
import SwiftUI
import UIKit

/// A SwiftUI wrapper over `UISegmentedControl` that binds to any
/// `Hashable & CaseIterable & Identifiable` value, giving full control over the
/// segment fonts and colours that SwiftUI's `Picker(.segmented)` does not expose.
///
/// The styling properties default to neutral system values; override them to
/// match an app's design system.
@available(iOS 13.0, tvOS 13.0, *)
public struct StyledSegmentedControl<T: Hashable & CaseIterable & Identifiable>: UIViewRepresentable where T.AllCases: RandomAccessCollection {

    @Binding public var selection: T
    public let titles: (T) -> String

    public var font: UIFont
    public var normalTextColor: UIColor
    public var selectedTextColor: UIColor
    public var selectedTintColor: UIColor

    public init(
        selection: Binding<T>,
        font: UIFont = .preferredFont(forTextStyle: .footnote),
        normalTextColor: UIColor = .label,
        selectedTextColor: UIColor = .label,
        selectedTintColor: UIColor = .systemBackground,
        titles: @escaping (T) -> String
    ) {
        self._selection = selection
        self.font = font
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
        self.selectedTintColor = selectedTintColor
        self.titles = titles
    }

    public func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl()
        applyStyle(to: control)

        for (index, item) in T.allCases.enumerated() {
            control.insertSegment(withTitle: titles(item), at: index, animated: false)
        }

        if let selectedIndex = T.allCases.firstIndex(of: selection) {
            control.selectedSegmentIndex = T.allCases.distance(from: T.allCases.startIndex, to: selectedIndex)
        }

        control.addTarget(context.coordinator, action: #selector(SegmentedControlCoordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }

    public func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        applyStyle(to: uiView)

        if let selectedIndex = T.allCases.firstIndex(of: selection) {
            let index = T.allCases.distance(from: T.allCases.startIndex, to: selectedIndex)
            if uiView.selectedSegmentIndex != index {
                uiView.selectedSegmentIndex = index
            }
        }
    }

    public func makeCoordinator() -> SegmentedControlCoordinator {
        let allCases = Array(T.allCases)
        return SegmentedControlCoordinator { index in
            guard index >= 0, index < allCases.count else { return }
            selection = allCases[index]
        }
    }

    // MARK: - Private

    private func applyStyle(to control: UISegmentedControl) {
        control.setTitleTextAttributes([.font: font, .foregroundColor: normalTextColor], for: .normal)
        control.setTitleTextAttributes([.font: font, .foregroundColor: selectedTextColor], for: .selected)
        control.selectedSegmentTintColor = selectedTintColor
    }
}

public class SegmentedControlCoordinator: NSObject {
    var onIndexChanged: (Int) -> Void

    public init(onIndexChanged: @escaping (Int) -> Void) {
        self.onIndexChanged = onIndexChanged
    }

    @objc public func valueChanged(_ sender: UISegmentedControl) {
        onIndexChanged(sender.selectedSegmentIndex)
    }
}
#endif
