import SwiftUI

// MARK: - Unified Shared Components
// Reduce clutter and enforce consistency across the app

// MARK: - Buttons

enum FlexrButtonStyle {
    case primary    // Solid Electric Blue (Main Actions)
    case secondary  // Surface color (Navigation/Dismiss)
    case action     // Gradient (Start Workout)
    case destructive // Red (Delete/Cancel)
    case ghost      // Text only
}

struct FlexrButton: View {
    let title: String
    let icon: String?
    let style: FlexrButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        style: FlexrButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isLoading ? "Loading..." : title)
                    .font(DesignSystem.Typography.button)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52) // Premium height
            .background(backgroundView)
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .action, .destructive: return .white
        case .secondary: return DesignSystem.Colors.text.primary
        case .ghost: return DesignSystem.Colors.primary
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            DesignSystem.Colors.primary
        case .action:
            DesignSystem.Gradients.primary
        case .secondary:
            DesignSystem.Colors.surface
        case .destructive:
            DesignSystem.Colors.error
        case .ghost:
            Color.clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary: return DesignSystem.Colors.divider
        default: return .clear
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Cards

struct FlexrCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = DesignSystem.Spacing.large, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Headers

struct FlexrHeader: View {
    let title: String
    let subtitle: String?
    let badgeText: String?
    let badgeColor: Color?
    
    init(title: String, subtitle: String? = nil, badgeText: String? = nil, badgeColor: Color? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.badgeColor = badgeColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let badgeText = badgeText {
                Text(badgeText.uppercased())
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((badgeColor ?? DesignSystem.Colors.primary).opacity(0.15))
                    .foregroundColor(badgeColor ?? DesignSystem.Colors.primary)
                    .cornerRadius(4)
            }
            
            Text(title)
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.text.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let items: [MetricItemData]
    
    struct MetricItemData: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let icon: String?
        let color: Color
        
        init(value: String, label: String, icon: String? = nil, color: Color = .white) {
            self.value = value
            self.label = label
            self.icon = icon
            self.color = color
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.caption)
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.value)
                            .font(DesignSystem.Typography.title3) // Slightly smaller than before for cleaner look
                            .foregroundColor(DesignSystem.Colors.text.primary)
                    }
                    
                    Text(item.label)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
                
                if index < items.count - 1 {
                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .frame(height: 30)
                }
            }
        }
        .padding(.vertical, 16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Segment Row (Unified)

struct UnifiedSegmentRow: View {
    let index: Int
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Index/Icon Container
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text("\(index)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle()) // For tap targets
    }
}
