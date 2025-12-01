import SwiftUI

enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        // Primary palette
        static let primary = Color("Primary", bundle: nil).fallback(Color(hex: "00D4FF")) // Electric Blue
        static let accent = Color("Accent", bundle: nil).fallback(Color(hex: "39FF14")) // Neon Green
        static let background = Color("Background", bundle: nil).fallback(Color(hex: "0A0E27")) // Dark Navy
        static let surface = Color("Surface", bundle: nil).fallback(Color(hex: "1A1F3A")) // Lighter Navy

        // Text colors
        enum text {
            static let primary = Color("TextPrimary", bundle: nil).fallback(.white)
            static let secondary = Color("TextSecondary", bundle: nil).fallback(Color.white.opacity(0.7))
            static let tertiary = Color("TextTertiary", bundle: nil).fallback(Color.white.opacity(0.5))
        }

        // Semantic colors
        static let success = Color(hex: "00C851")
        static let warning = Color(hex: "FFB700")
        static let error = Color(hex: "FF4444")
        static let info = Color(hex: "33B5E5")

        // Heart rate zones
        static let zone1 = Color(hex: "808080") // Recovery - Gray
        static let zone2 = Color(hex: "33B5E5") // Aerobic - Blue
        static let zone3 = Color(hex: "00C851") // Tempo - Green
        static let zone4 = Color(hex: "FFB700") // Threshold - Orange
        static let zone5 = Color(hex: "FF4444") // Max - Red

        static func zoneColor(_ zone: Int) -> Color {
            switch zone {
            case 1: return zone1
            case 2: return zone2
            case 3: return zone3
            case 4: return zone4
            case 5: return zone5
            default: return zone3
            }
        }

        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [primary, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let backgroundGradient = LinearGradient(
            colors: [background, surface],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography

    enum Typography {
        // Display styles
        static let display = Font.system(size: 48, weight: .bold, design: .rounded)

        // Headings
        static let heading1 = Font.system(size: 32, weight: .bold, design: .rounded)
        static let heading2 = Font.system(size: 24, weight: .bold, design: .rounded)
        static let heading3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let heading4 = Font.system(size: 18, weight: .semibold, design: .rounded)

        // Body text
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyBold = Font.system(size: 16, weight: .semibold, design: .default)
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 14, weight: .semibold, design: .default)

        // Metrics display
        static let metricLarge = Font.system(size: 56, weight: .bold, design: .rounded).monospacedDigit()
        static let metricMedium = Font.system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
        static let metricSmall = Font.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit()

        // Timer display
        static let timer = Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit()

        // Labels
        static let label = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48

        // Padding presets
        static let cardPadding = EdgeInsets(top: medium, leading: medium, bottom: medium, trailing: medium)
        static let screenPadding = EdgeInsets(top: large, leading: medium, bottom: large, trailing: medium)
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let round: CGFloat = 999 // Fully rounded
    }

    // MARK: - Shadows

    enum Shadow {
        static let small = ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Icons

    enum Icons {
        static let size = IconSize.self

        enum IconSize {
            static let small: CGFloat = 16
            static let medium: CGFloat = 24
            static let large: CGFloat = 32
            static let xLarge: CGFloat = 48
        }
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Layout

    enum Layout {
        static let maxContentWidth: CGFloat = 600
        static let minTapTarget: CGFloat = 44
        static let tabBarHeight: CGFloat = 88
        static let navigationBarHeight: CGFloat = 44
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.small)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 2)
            )
    }
}

// MARK: - Color Extension

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

    func fallback(_ fallback: Color) -> Color {
        return self
    }
}
