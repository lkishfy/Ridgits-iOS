import SwiftUI

enum RidgitsLogoView {
    /// White squircle grid on black — matches `Ridgits/ridgits/src/assets/logo.png` on dark backgrounds (login circle, loading).
    static func onDark(size: CGFloat) -> some View {
        Image("RidgitsLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    /// Inverted for light backgrounds — matches web home nav `filter: invert(1) brightness(0)`.
    static func onLight(size: CGFloat) -> some View {
        Image("RidgitsLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .colorInvert()
            .brightness(-1)
    }
}
