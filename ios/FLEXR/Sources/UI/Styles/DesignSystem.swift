import SwiftUI

// MARK: - FLEXR Design System
// Data-driven intelligence meets premium iOS design
// Brand: Electric blue for focus, trust, and endurance performance

enum DesignSystem {

    // MARK: - Colors
    // Dark mode first, flat colors (NO GRADIENTS), intelligence-focused aesthetic

    enum Colors {
        // Backgrounds - Pure blacks and near-blacks
        static let background = Color(hex: "000000")          // Pure black (OLED optimized)
        static let backgroundSecondary = Color(hex: "1C1C1E") // Near black (system)
        static let surface = Color(hex: "2C2C2E")             // Elevated surface (cards)
        static let surfaceElevated = Color(hex: "3A3A3C")     // Highest elevation

        // Primary - Electric blue for intelligence, focus, endurance
        static let primary = Color(hex: "0A84FF")             // Electric blue (FLEXR brand)
        static let primaryMuted = Color(hex: "0A84FF").opacity(0.12)

        // Secondary - Cyan for secondary actions and progress
        static let secondary = Color(hex: "00D9FF")           // Cyan accent
        static let secondaryMuted = Color(hex: "00D9FF").opacity(0.12)

        // Accent - Alias for primary (backwards compatibility)
        static let accent = primary

        // Text hierarchy - Clean, high contrast
        enum text {
            static let primary = Color.white
            static let secondary = Color(hex: "8E8E93")       // System gray
            static let tertiary = Color(hex: "48484A")        // Darker gray
            static let disabled = Color(hex: "3A3A3C")
            static let placeholder = Color(hex: "636366")
        }

        // Semantic colors - Performance and status indicators
        static let success = Color(hex: "30D158")             // Green (achievements, PRs)
        static let warning = Color(hex: "FFD60A")             // Yellow (caution, fatigue)
        static let error = Color(hex: "FF453A")               // Red (errors, overtraining)
        static let info = Color(hex: "0A84FF")                // Electric blue (information, insights)

        // Heart rate zones - Clean, accessible, flat
        static let zone1 = Color(hex: "8E8E93")  // Gray - Recovery
        static let zone2 = Color(hex: "0A84FF")  // Blue - Easy
        static let zone3 = Color(hex: "30D158")  // Green - Aerobic
        static let zone4 = Color(hex: "FF9F0A")  // Orange - Threshold
        static let zone5 = Color(hex: "FF453A")  // Red - Max

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

        // Workout types - HYROX station colors
        static let running = Color(hex: "0A84FF")    // Electric blue (primary brand, cardio)
        static let skiErg = Color(hex: "00D9FF")     // Cyan (upper body endurance)
        static let sledPush = Color(hex: "FF9F0A")   // Orange (explosive power)
        static let sledPull = Color(hex: "FF9F0A")   // Orange (pulling strength)
        static let burpees = Color(hex: "BF5AF2")    // Purple (full body)
        static let rowing = Color(hex: "5AC8FA")     // Cyan (endurance cardio)
        static let farmersCarry = Color(hex: "FF2D55") // Pink (grip/core)
        static let lunges = Color(hex: "30D158")     // Green (lower body)
        static let wallBalls = Color(hex: "5AC8FA")  // Cyan (power endurance)

        static let divider = Color(hex: "38383A")
        static let dividerLight = Color(hex: "48484A")
    }

    // MARK: - Gradients
    // Premium electric gradients

    enum Gradients {
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let running = LinearGradient(
            colors: [Colors.primary, Color(hex: "00B4D8")],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let station = LinearGradient(
            colors: [Colors.warning, Color(hex: "FF3B30")],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let darkSurface = LinearGradient(
            colors: [Colors.surface, Colors.surface.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography
    // SF Pro family (system fonts) - Apple Fitness+ style

    enum Typography {
        // Large titles - Hero content
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

        // Titles - Section headers
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

        // Headline - Important content
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)

        // Body - Primary content
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyEmphasized = Font.system(size: 17, weight: .semibold, design: .default)

        // Callout - Secondary content
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let calloutEmphasized = Font.system(size: 16, weight: .semibold, design: .default)

        // Subheadline - Tertiary content
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let subheadlineEmphasized = Font.system(size: 15, weight: .semibold, design: .default)

        // Footnote - Small details
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let footnoteEmphasized = Font.system(size: 13, weight: .semibold, design: .default)

        // Caption - Smallest text
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

        // Metrics - Monospaced numbers for data
        static let metricHuge = Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit()
        static let metricLarge = Font.system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
        static let metricMedium = Font.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit()
        static let metricSmall = Font.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit()

        // Timer - Large, readable time display
        static let timer = Font.system(size: 72, weight: .bold, design: .rounded).monospacedDigit()

        // MARK: - Analytics Hero Metrics (NEW - for analytics redesign)
        // Emotional, impactful numbers for analytics screens

        // Hero metrics - Main stat on screen (120pt for max emotional impact)
        static let metricHero = Font.system(size: 120, weight: .bold, design: .rounded).monospacedDigit()
        static let metricHeroLarge = Font.system(size: 96, weight: .bold, design: .rounded).monospacedDigit()

        // Breakdown metrics - Secondary stats on detail screens
        static let metricBreakdown = Font.system(size: 72, weight: .bold, design: .rounded).monospacedDigit()
        static let metricBreakdownMedium = Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit()

        // Insights - Contextual text for analytics
        static let insightLarge = Font.system(size: 22, weight: .bold, design: .default)
        static let insightMedium = Font.system(size: 17, weight: .regular, design: .default)
        static let insightSmall = Font.system(size: 15, weight: .regular, design: .default)

        // Section headers for analytics
        static let sectionHeader = Font.system(size: 17, weight: .semibold, design: .default)

        // Buttons
        static let button = Font.system(size: 17, weight: .semibold, design: .default)
        static let buttonSmall = Font.system(size: 15, weight: .semibold, design: .default)

        // Backwards compatibility aliases
        static let heading1 = title1
        static let heading2 = title1
        static let heading3 = title2
        static let bodyMedium = bodyEmphasized
        static let bodySmall = subheadline
        static let caption = caption1
    }

    // MARK: - Spacing
    // 4pt grid system - Apple's standard

    enum Spacing {
        static let xxxSmall: CGFloat = 2
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16  // Standard padding
        static let large: CGFloat = 20   // Card padding
        static let xLarge: CGFloat = 24  // Analytics card spacing
        static let xxLarge: CGFloat = 32 // Section spacing
        static let xxxLarge: CGFloat = 48 // Hero spacing

        // Screen margins
        static let screenHorizontal: CGFloat = 16
        static let screenTop: CGFloat = 16
        static let screenBottom: CGFloat = 34 // Account for home indicator

        // Card padding
        static let cardPadding: CGFloat = 20
        static let cardPaddingSmall: CGFloat = 16

        // MARK: - Analytics Spacing (NEW)
        // Breathing room for analytics screens
        static let analyticsCardPadding: CGFloat = 24      // Inside hero cards (vs 16-20pt)
        static let analyticsSectionSpacing: CGFloat = 32   // Between major sections
        static let analyticsCardSpacing: CGFloat = 24      // Between hero cards
        static let analyticsBreakdownSpacing: CGFloat = 16 // Between breakdown items
    }

    // MARK: - Card Heights (NEW)
    // Minimum heights for different card types in analytics

    enum CardHeight {
        static let compact: CGFloat = 140      // Workout history items
        static let standard: CGFloat = 180     // Metric breakdown cards
        static let featured: CGFloat = 240     // Featured station/metric cards
        static let hero: CGFloat = 360         // Main dashboard hero cards
        static let heroLarge: CGFloat = 400    // Extra large hero cards
    }

    // MARK: - Corner Radius
    // Apple Fitness+ rounded corners

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20  // Cards
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows
    // Subtle, premium shadows - NO harsh borders

    enum Shadow {
        // Small shadow - Subtle elevation
        static let small = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )

        // Medium shadow - Card elevation
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )

        // Large shadow - Modal elevation
        static let large = ShadowStyle(
            color: Color.black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )

        // Extra large shadow - Maximum elevation
        static let xLarge = ShadowStyle(
            color: Color.black.opacity(0.25),
            radius: 24,
            x: 0,
            y: 12
        )
    }

    // MARK: - Button Sizes

    enum ButtonSize {
        case small   // 44pt height (min tap target)
        case medium  // 50pt height
        case large   // 56pt height

        var height: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 50
            case .large: return 56
            }
        }

        var font: Font {
            switch self {
            case .small: return Typography.buttonSmall
            case .medium, .large: return Typography.button
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 24
            }
        }
    }

    // MARK: - Animation
    // Apple-style smooth animations

    enum Animation {
        static let instant = SwiftUI.Animation.easeOut(duration: 0.1)
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }

    // MARK: - Layout Constants

    enum Layout {
        static let minTapTarget: CGFloat = 44
        static let maxContentWidth: CGFloat = 500
        static let cardMinHeight: CGFloat = 80
        static let dividerHeight: CGFloat = 0.5
    }
}

// MARK: - Shadow Style Helper

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Primary Button Style (Apple Fitness+ Green)

struct PrimaryButtonStyle: ButtonStyle {
    let size: DesignSystem.ButtonSize
    let isEnabled: Bool
    let isFullWidth: Bool

    init(size: DesignSystem.ButtonSize = .large, isEnabled: Bool = true, isFullWidth: Bool = true) {
        self.size = size
        self.isEnabled = isEnabled
        self.isFullWidth = isFullWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isEnabled ? .black : DesignSystem.Colors.text.disabled)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
            )
            .shadow(
                color: DesignSystem.Shadow.small.color,
                radius: configuration.isPressed ? 2 : DesignSystem.Shadow.small.radius,
                x: 0,
                y: configuration.isPressed ? 1 : DesignSystem.Shadow.small.y
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
            .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button Style (Subtle surface)

struct SecondaryButtonStyle: ButtonStyle {
    let size: DesignSystem.ButtonSize
    let isFullWidth: Bool

    init(size: DesignSystem.ButtonSize = .medium, isFullWidth: Bool = false) {
        self.size = size
        self.isFullWidth = isFullWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(DesignSystem.Colors.text.primary)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(DesignSystem.Colors.surface)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Text Button Style

struct TextButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = DesignSystem.Colors.secondary) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundColor(configuration.isPressed ? color.opacity(0.6) : color)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Selection Card Style

struct SelectionCardStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(isSelected ? DesignSystem.Colors.primaryMuted : DesignSystem.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .strokeBorder(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isSelected ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: 0
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: isSelected)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply screen background (pure black)
    func screenBackground() -> some View {
        self.background(DesignSystem.Colors.background.ignoresSafeArea())
    }

    /// Apply card background with shadow
    func cardBackground(shadow: ShadowStyle = DesignSystem.Shadow.medium) -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.xLarge)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }

    /// Apply elevated card background
    func elevatedCardBackground() -> some View {
        self
            .background(DesignSystem.Colors.surfaceElevated)
            .cornerRadius(DesignSystem.Radius.large)
            .shadow(
                color: DesignSystem.Shadow.large.color,
                radius: DesignSystem.Shadow.large.radius,
                x: DesignSystem.Shadow.large.x,
                y: DesignSystem.Shadow.large.y
            )
    }

    /// Apply subtle divider
    func divider() -> some View {
        Rectangle()
            .fill(DesignSystem.Colors.divider)
            .frame(height: DesignSystem.Layout.dividerHeight)
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
