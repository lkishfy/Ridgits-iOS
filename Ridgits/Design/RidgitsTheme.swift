import SwiftUI

// MARK: - Ridgits monochromatic palette (matches ridgits web + LinearDesign)

enum RidgitsColors {
    static let feedBackground = Color(hex: 0xFAFAFA)
    static let surface = Color.white
    static let contextBar = Color(hex: 0xF7F7F7)
    static let hoverSurface = Color(hex: 0xF5F5F5)
    static let border = Color(hex: 0xE5E5E5)
    static let borderLight = Color(hex: 0xEEEEEE)
    static let textPrimary = Color(hex: 0x0F1419)
    static let textHeadline = Color(hex: 0x0A0A0A)
    static let textSecondary = Color(hex: 0x666666)
    static let textMuted = Color(hex: 0x999999)
    static let timestamp = Color(hex: 0x536471)
    static let inputSurface = Color(hex: 0xF8F9FA)
    static let inputBorder = Color(hex: 0xE1E5E9)
    static let destructive = Color(hex: 0xF4212E)
    static let ctaBlack = Color.black
    static let primaryBlue = Color(hex: 0x0066FF)
    static let pendingYellow = Color(hex: 0xFFF9E6)
    static let pendingBorder = Color(hex: 0xF5E6A3)

    // Login hero
    static let charcoal = Color(hex: 0x0A0A0A)
    static let buttonPrimary = Color(hex: 0x333333)
    static let assistantGreen = Color(hex: 0x76B88E)
    static let assistantDark = Color(hex: 0x141414)
    static let assistantPanel = Color(hex: 0x161616)
    static let dashboardBorder = Color(hex: 0xE0E0E0)
}

enum RidgitsTypography {
    static func display(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    static func heroTitle(_ size: CGFloat = 44) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func label(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func navLabel(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func banner(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func cta(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func sectionLabel(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func mono(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

enum RidgitsRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 6
    static let lg: CGFloat = 8
    static let xl: CGFloat = 12
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
