import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Mode Colors
struct ModeColors {

    // MARK: - Child Mode Colors

    static let childPrimary = Color(hex: "00D4FF")        // Bright Cyan
    static let childSecondary = Color(hex: "00A8CC")      // Deep Cyan
    static let childAccent = Color(hex: "FFB800")         // Warm Yellow
    static let childBackground = Color(hex: "F0F9FF")     // Light Blue Tint
    static let childText = Color(hex: "1A1A1A")           // Dark Gray
    static let childBubble = Color(hex: "E6F7FF")         // Very Light Cyan
    static let childGradientStart = Color(hex: "00D4FF")
    static let childGradientEnd = Color(hex: "00A8CC")

    // MARK: - Adult Mode Colors

    static let adultPrimary = Color(hex: "9D4EDD")        // Purple
    static let adultSecondary = Color(hex: "7B2CBF")      // Deep Purple
    static let adultAccent = Color(hex: "C77DFF")         // Light Purple
    static let adultBackground = Color(hex: "F8F5FB")     // Light Purple Tint
    static let adultText = Color(hex: "1A1A1A")           // Dark Gray
    static let adultBubble = Color(hex: "F3E8FF")         // Very Light Purple
    static let adultGradientStart = Color(hex: "9D4EDD")
    static let adultGradientEnd = Color(hex: "7B2CBF")

    // MARK: - Mode-Aware Colors

    static func primary(for mode: OperationalMode) -> Color {
        mode == .child ? childPrimary : adultPrimary
    }

    static func secondary(for mode: OperationalMode) -> Color {
        mode == .child ? childSecondary : adultSecondary
    }

    static func accent(for mode: OperationalMode) -> Color {
        mode == .child ? childAccent : adultAccent
    }

    static func background(for mode: OperationalMode) -> Color {
        mode == .child ? childBackground : adultBackground
    }

    static func textColor(for mode: OperationalMode) -> Color {
        mode == .child ? childText : adultText
    }

    static func bubble(for mode: OperationalMode) -> Color {
        mode == .child ? childBubble : adultBubble
    }

    static func gradient(for mode: OperationalMode) -> LinearGradient {
        let colors = mode == .child
            ? [childGradientStart, childGradientEnd]
            : [adultGradientStart, adultGradientEnd]

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Semantic Colors

    static let successGreen = Color(hex: "10B981")
    static let warningYellow = Color(hex: "F59E0B")
    static let errorRed = Color(hex: "EF4444")
    static let infoBlue = Color(hex: "3B82F6")
}

// MARK: - Mode Typography
struct ModeTypography {

    // MARK: - Child Mode Fonts

    static let childTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let childHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let childBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let childButton = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let childCaption = Font.system(size: 14, weight: .medium, design: .rounded)

    // MARK: - Adult Mode Fonts

    static let adultTitle = Font.system(size: 22, weight: .semibold, design: .default)
    static let adultHeadline = Font.system(size: 18, weight: .medium, design: .default)
    static let adultBody = Font.system(size: 15, weight: .regular, design: .default)
    static let adultButton = Font.system(size: 16, weight: .medium, design: .default)
    static let adultCaption = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Mode-Aware Fonts

    static func title(for mode: OperationalMode) -> Font {
        mode == .child ? childTitle : adultTitle
    }

    static func headline(for mode: OperationalMode) -> Font {
        mode == .child ? childHeadline : adultHeadline
    }

    static func body(for mode: OperationalMode) -> Font {
        mode == .child ? childBody : adultBody
    }

    static func button(for mode: OperationalMode) -> Font {
        mode == .child ? childButton : adultButton
    }

    static func caption(for mode: OperationalMode) -> Font {
        mode == .child ? childCaption : adultCaption
    }
}

// Note: Color extension for hex support is defined in ParentAuthView.swift

// MARK: - Mode Animation Styles
struct ModeAnimations {

    // Child mode: bouncy and playful
    static let childAnimation = Animation.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)

    // Adult mode: smooth and professional
    static let adultAnimation = Animation.easeInOut(duration: 0.3)

    static func animation(for mode: OperationalMode) -> Animation {
        mode == .child ? childAnimation : adultAnimation
    }

    // Mode transition animation
    static let modeTransition = Animation.easeInOut(duration: 0.4)
}