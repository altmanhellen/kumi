import UIKit

/// Kumi hides the system navigation bar and draws its own «‹ Назад» buttons. Hiding the bar also
/// switches off the iOS swipe from the left edge, so this turns it back on for every pushed screen.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
