import SwiftUI

/// Design system tokens and styles optimized for watchOS
/// Brand: Electric blue for intelligence, focus, and endurance
enum WatchDesignSystem {
    // MARK: - Colors

    enum Colors {
        // Brand colors - FLEXR electric blue
        static let primary = Color("AccentColor", bundle: .main)  // Should be #0A84FF in Assets
        static let secondary = Color(red: 0.0, green: 0.85, blue: 1.0)  // Cyan #00D9FF

        // Workout segment colors - HYROX stations (matches iOS)
        static let runColor = Color(red: 0.039, green: 0.518, blue: 1.0)  // Electric blue #0A84FF
        static let skiErgColor = Color(red: 0.0, green: 0.85, blue: 1.0)   // Cyan #00D9FF
        static let sledColor = Color.orange
        static let rowErgColor = Color.cyan
        static let burpeeColor = Color.purple
        static let farmersColor = Color.pink
        static let sandbagColor = Color.orange
        static let wallBallsColor = Color.cyan
        static let lungesColor = Color.green

        // Status colors - Performance indicators
        static let success = Color.green         // Achievements, PRs
        static let warning = Color.orange        // Caution, fatigue
        static let error = Color.red            // Errors, overtraining
        static let info = Color(red: 0.039, green: 0.518, blue: 1.0)  // Electric blue #0A84FF

        // Metric colors - Watch display
        static let heartRate = Color.red
        static let pace = Color(red: 0.039, green: 0.518, blue: 1.0)      // Electric blue #0A84FF
        static let calories = Color.orange
        static let distance = Color(red: 0.0, green: 0.85, blue: 1.0)    // Cyan #00D9FF

        // Heart rate zones - Training intensity
        static let hrRest = Color.gray
        static let hrWarmup = Color(red: 0.039, green: 0.518, blue: 1.0)  // Electric blue #0A84FF
        static let hrFatBurn = Color.green
        static let hrCardio = Color.orange
        static let hrPeak = Color.red

        // UI elements
        static let background = Color.black
        static let cardBackground = Color.gray.opacity(0.15)
        static let divider = Color.gray.opacity(0.3)
        static let overlay = Color.black.opacity(0.6)
    }

    // MARK: - Typography

    enum Typography {
        // Display
        static let displayLarge = Font.system(size: 54, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 42, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)

        // Headings
        static let h1 = Font.system(size: 24, weight: .bold, design: .default)
        static let h2 = Font.system(size: 20, weight: .bold, design: .default)
        static let h3 = Font.system(size: 18, weight: .semibold, design: .default)

        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

        // Labels
        static let labelLarge = Font.system(size: 14, weight: .semibold, design: .default)
        static let label = Font.system(size: 12, weight: .semibold, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .semibold, design: .default)

        // Captions
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let captionSmall = Font.system(size: 9, weight: .regular, design: .default)

        // Monospaced (for times, metrics)
        static let monoLarge = Font.system(size: 24, weight: .regular, design: .monospaced)
        static let mono = Font.system(size: 16, weight: .regular, design: .monospaced)
        static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
        static let round: CGFloat = 999
    }

    // MARK: - Haptic Feedback

    enum Haptics {
        static func segmentStart() {
            WKInterfaceDevice.current().play(.start)
        }

        static func segmentComplete() {
            WKInterfaceDevice.current().play(.success)
        }

        static func repComplete() {
            WKInterfaceDevice.current().play(.click)
        }

        static func heartRateWarning() {
            WKInterfaceDevice.current().play(.notification)
        }

        static func workoutComplete() {
            WKInterfaceDevice.current().play(.success)
        }

        static func milestone() {
            WKInterfaceDevice.current().play(.notification)
        }

        static func error() {
            WKInterfaceDevice.current().play(.failure)
        }

        static func selection() {
            WKInterfaceDevice.current().play(.click)
        }
    }

    // MARK: - Animations

    enum Animations {
        static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let easeInOut = Animation.easeInOut(duration: 0.3)
        static let linear = Animation.linear(duration: 1.0)
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.2)
        static let large = Color.black.opacity(0.3)
    }
}

// MARK: - View Modifiers

struct WatchCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(WatchDesignSystem.Spacing.md)
            .background(WatchDesignSystem.Colors.cardBackground)
            .cornerRadius(WatchDesignSystem.CornerRadius.medium)
    }
}

struct WatchMetricLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(WatchDesignSystem.Typography.labelSmall)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

struct WatchMetricValueStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(WatchDesignSystem.Typography.displayMedium)
            .foregroundColor(color)
    }
}

struct WatchButtonStyle: ButtonStyle {
    let color: Color
    let isProminent: Bool

    init(color: Color = Color(red: 0.039, green: 0.518, blue: 1.0), isProminent: Bool = true) {  // Electric blue default
        self.color = color
        self.isProminent = isProminent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, WatchDesignSystem.Spacing.sm)
            .padding(.horizontal, WatchDesignSystem.Spacing.md)
            .background(
                isProminent
                    ? color.opacity(configuration.isPressed ? 0.7 : 1.0)
                    : Color.clear
            )
            .foregroundColor(isProminent ? .white : color)
            .cornerRadius(WatchDesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: WatchDesignSystem.CornerRadius.medium)
                    .stroke(color, lineWidth: isProminent ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(WatchDesignSystem.Animations.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func watchCard() -> some View {
        modifier(WatchCardStyle())
    }

    func watchMetricLabel() -> some View {
        modifier(WatchMetricLabelStyle())
    }

    func watchMetricValue(color: Color = .primary) -> some View {
        modifier(WatchMetricValueStyle(color: color))
    }

    func watchButton(color: Color = .blue, isProminent: Bool = true) -> some View {
        buttonStyle(WatchButtonStyle(color: color, isProminent: isProminent))
    }
}



// MARK: - Gradient Styles

enum WatchGradients {
    static let runGradient = LinearGradient(
        colors: [Color.blue, Color.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let stationGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let warningGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heartRateGradient = LinearGradient(
        colors: [Color.red, Color.pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Layout Constants

enum WatchLayout {
    // Screen sizes (approximate)
    static let screen40mm: CGFloat = 162  // 40mm watch
    static let screen44mm: CGFloat = 184  // 44mm watch
    static let screen45mm: CGFloat = 198  // 45mm watch
    static let screen49mm: CGFloat = 205  // 49mm watch

    // Safe areas
    static let topSafeArea: CGFloat = 8
    static let bottomSafeArea: CGFloat = 8
    static let horizontalPadding: CGFloat = 12

    // Component sizes
    static let buttonHeight: CGFloat = 44
    static let iconSize: CGFloat = 24
    static let smallIconSize: CGFloat = 16
    static let metricRingSize: CGFloat = 100
    static let largeMetricRingSize: CGFloat = 120

    // List items
    static let listRowHeight: CGFloat = 60
    static let listRowSpacing: CGFloat = 8
}

// MARK: - Preview Helpers

#if DEBUG
struct WatchDesignSystemPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: WatchDesignSystem.Spacing.lg) {
                // Colors
                VStack(alignment: .leading, spacing: WatchDesignSystem.Spacing.sm) {
                    Text("Colors")
                        .font(WatchDesignSystem.Typography.h2)

                    HStack(spacing: WatchDesignSystem.Spacing.xs) {
                        ColorSwatch(color: WatchDesignSystem.Colors.runColor, name: "Run")
                        ColorSwatch(color: WatchDesignSystem.Colors.sledColor, name: "Station")
                        ColorSwatch(color: WatchDesignSystem.Colors.heartRate, name: "HR")
                    }
                }
                .watchCard()

                // Typography
                VStack(alignment: .leading, spacing: WatchDesignSystem.Spacing.sm) {
                    Text("Typography")
                        .font(WatchDesignSystem.Typography.h2)

                    Text("Display Large")
                        .font(WatchDesignSystem.Typography.displayLarge)

                    Text("Heading 1")
                        .font(WatchDesignSystem.Typography.h1)

                    Text("Body text example")
                        .font(WatchDesignSystem.Typography.body)

                    Text("Caption text")
                        .font(WatchDesignSystem.Typography.caption)
                }
                .watchCard()

                // Buttons
                VStack(spacing: WatchDesignSystem.Spacing.sm) {
                    Button("Prominent Button") {}
                        .watchButton(color: .green, isProminent: true)

                    Button("Outlined Button") {}
                        .watchButton(color: .blue, isProminent: false)
                }
                .watchCard()

                // Metrics
                VStack(spacing: WatchDesignSystem.Spacing.sm) {
                    Text("HEART RATE")
                        .watchMetricLabel()

                    Text("165")
                        .watchMetricValue(color: WatchDesignSystem.Colors.heartRate)
                }
                .watchCard()
            }
            .padding()
        }
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)

            Text(name)
                .font(WatchDesignSystem.Typography.captionSmall)
        }
    }
}

#Preview("Design System") {
    WatchDesignSystemPreview()
}
#endif
