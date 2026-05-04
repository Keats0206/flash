import SwiftUI
#if canImport(UIKit)
import UIKit

// MARK: - Core introspection bridge

private struct IntrospectView<Target: UIView>: UIViewRepresentable {
    let customize: (Target) -> Void

    func makeUIView(context: Context) -> _IntrospectAnchor {
        _IntrospectAnchor()
    }

    func updateUIView(_ anchor: _IntrospectAnchor, context: Context) {
        DispatchQueue.main.async {
            guard let target = anchor.find(Target.self) else { return }
            customize(target)
        }
    }
}

final class _IntrospectAnchor: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }

    func find<T: UIView>(_ type: T.Type) -> T? {
        // Walk up the responder/superview chain first
        var candidate: UIView? = superview
        while let view = candidate {
            if let match = view as? T { return match }
            // Also check siblings for cases like TextField wrapping UITextField
            for sibling in view.subviews {
                if let match = sibling as? T { return match }
                for child in sibling.subviews {
                    if let match = child as? T { return match }
                }
            }
            candidate = view.superview
        }
        return nil
    }
}

// MARK: - View modifiers

extension View {
    /// Access the underlying UIScrollView (e.g. to disable bounce or set indicators).
    func introspectScrollView(_ customize: @escaping (UIScrollView) -> Void) -> some View {
        overlay(
            IntrospectView(customize: customize)
                .frame(width: 0, height: 0)
        )
    }

    /// Access the underlying UITextField (e.g. to set keyboard appearance or return key).
    func introspectTextField(_ customize: @escaping (UITextField) -> Void) -> some View {
        overlay(
            IntrospectView(customize: customize)
                .frame(width: 0, height: 0)
        )
    }

    /// Access the underlying UITextView (e.g. axis:.vertical TextFields backed by UITextView).
    func introspectTextView(_ customize: @escaping (UITextView) -> Void) -> some View {
        overlay(
            IntrospectView(customize: customize)
                .frame(width: 0, height: 0)
        )
    }

}
#endif
