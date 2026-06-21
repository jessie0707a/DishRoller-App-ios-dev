import SwiftUI
import UIKit

@MainActor
func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

extension View {
    func dismissKeyboardOnOutsideTap() -> some View {
        background(KeyboardDismissTapInstaller().frame(width: 0, height: 0))
    }

}

private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.install(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.install(from: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.removeGestureRecognizer()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var installedWindow: UIWindow?
        private weak var gestureRecognizer: UITapGestureRecognizer?

        func install(from view: UIView) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let window = view?.window else { return }
                guard installedWindow !== window else { return }

                removeGestureRecognizer()

                let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                recognizer.cancelsTouchesInView = false
                recognizer.delegate = self
                window.addGestureRecognizer(recognizer)

                installedWindow = window
                gestureRecognizer = recognizer
            }
        }

        func removeGestureRecognizer() {
            if let gestureRecognizer {
                installedWindow?.removeGestureRecognizer(gestureRecognizer)
            }
            gestureRecognizer = nil
            installedWindow = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            var touchedView: UIView? = touch.view
            while let view = touchedView {
                if view is UITextField || view is UITextView {
                    return false
                }
                touchedView = view.superview
            }
            return true
        }

        @objc private func handleTap() {
            Task { @MainActor in
                dismissKeyboard()
            }
        }
    }
}
