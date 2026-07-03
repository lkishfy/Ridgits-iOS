import UIKit

extension UIViewController {
    var ridgitsTopMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.ridgitsTopMostViewController
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.ridgitsTopMostViewController ?? navigation
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.ridgitsTopMostViewController ?? tab
        }
        return self
    }
}

enum RidgitsPresentation {
    static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .ridgitsTopMostViewController
    }
}
