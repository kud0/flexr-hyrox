// FLEXR - Customizable Video Overlay
// "Build your own" overlay - show only what YOU want, where YOU want it
// Feels like part of your style, not intrusive

import SwiftUI

// MARK: - Overlay Element Types

enum OverlayElement: String, CaseIterable, Identifiable {
    case timer = "Timer"
    case heartRate = "Heart Rate"
    case segment = "Segment"
    case roundCounter = "Round"
    case pace = "Pace"
    case power = "Power"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .heartRate: return "heart.fill"
        case .segment: return "figure.run"
        case .roundCounter: return "number.circle.fill"
        case .pace: return "speedometer"
        case .power: return "bolt.fill"
        }
    }
}

// MARK: - Overlay Settings

struct OverlaySettings {
    var enabledElements: Set<OverlayElement> = [.timer, .segment]
    var positions: [OverlayElement: CGPoint] = [:]
    var style: OverlayStyle = .clean
    var showBranding: Bool = false

    enum OverlayStyle: String, CaseIterable {
        case clean = "Clean"
        case minimal = "Minimal"
        case detailed = "Detailed"
    }

    // Default presets
    static var ultraClean: OverlaySettings {
        OverlaySettings(
            enabledElements: [.timer, .segment],
            positions: [:],
            style: .clean,
            showBranding: false
        )
    }

    static var balanced: OverlaySettings {
        OverlaySettings(
            enabledElements: [.timer, .segment, .heartRate, .roundCounter],
            positions: [:],
            style: .minimal,
            showBranding: false
        )
    }

    static var full: OverlaySettings {
        OverlaySettings(
            enabledElements: Set(OverlayElement.allCases),
            positions: [:],
            style: .detailed,
            showBranding: false
        )
    }
}

// MARK: - Main Customizable Overlay

struct CustomizableOverlay: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel
    @Binding var settings: OverlaySettings

    let isEditing: Bool

    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

    var body: some View {
        ZStack {
            // Render only enabled elements
            ForEach(Array(settings.enabledElements)) { element in
                overlayElement(for: element)
                    .position(position(for: element))
            }

            // Optional branding watermark
            if settings.showBranding {
                brandingWatermark
            }

            // Editing UI (only when customizing)
            if isEditing {
                editingOverlay
            }
        }
    }

    // MARK: - Individual Elements

    @ViewBuilder
    private func overlayElement(for element: OverlayElement) -> some View {
        Group {
            switch element {
            case .timer:
                TimerElement(time: formattedTime(workoutVM.totalElapsedTime))

            case .heartRate:
                HeartRateElement(bpm: currentHeartRate, zone: hrZoneColor)

            case .segment:
                SegmentElement(name: workoutVM.currentSegment?.displayName ?? "Ready")

            case .roundCounter:
                RoundElement(current: 1, total: 1)

            case .pace:
                if let pace = currentPace {
                    PaceElement(pace: pace)
                }

            case .power:
                if let power = currentPower {
                    PowerElement(watts: power)
                }
            }
        }
        .if(isEditing) { view in
            view.overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(electricBlue, lineWidth: 2)
            )
        }
    }

    // MARK: - Element Components (Minimal, Clean Design)

    struct TimerElement: View {
        let time: String

        var body: some View {
            Text(time)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                )
        }
    }

    struct HeartRateElement: View {
        let bpm: Int
        let zone: Color

        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(zone)

                Text("\(bpm)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            )
        }
    }

    struct SegmentElement: View {
        let name: String

        var body: some View {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                )
        }
    }

    struct RoundElement: View {
        let current: Int
        let total: Int
        private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

        var body: some View {
            HStack(spacing: 3) {
                Text("\(current)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(electricBlue)

                Text("/\(total)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            )
        }
    }

    struct PaceElement: View {
        let pace: String

        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))

                Text(pace)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            )
        }
    }

    struct PowerElement: View {
        let watts: Int

        var body: some View {
            HStack(spacing: 4) {
                Text("\(watts)W")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            )
        }
    }

    // MARK: - Branding Watermark (Optional)

    private var brandingWatermark: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                Text("FLEXR")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Editing Overlay

    private var editingOverlay: some View {
        VStack {
            Spacer()

            Text("Tap and drag to position elements")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .padding(.bottom, 100)
        }
    }

    // MARK: - Position Management

    private func position(for element: OverlayElement) -> CGPoint {
        // Return saved position or default
        if let saved = settings.positions[element] {
            return saved
        }

        // Default positions (clean, non-intrusive)
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        switch element {
        case .timer:
            return CGPoint(x: screenWidth - 60, y: 80) // Top right
        case .heartRate:
            return CGPoint(x: 60, y: 80) // Top left
        case .segment:
            return CGPoint(x: screenWidth / 2, y: screenHeight - 60) // Bottom center
        case .roundCounter:
            return CGPoint(x: screenWidth - 60, y: screenHeight - 60) // Bottom right
        case .pace:
            return CGPoint(x: 60, y: screenHeight - 120) // Bottom left
        case .power:
            return CGPoint(x: screenWidth / 2, y: screenHeight - 120) // Bottom center-left
        }
    }

    // MARK: - Computed Properties

    private var currentHeartRate: Int {
        // TODO: Get from HealthKit or Watch
        return 152
    }

    private var hrZoneColor: Color {
        let hr = currentHeartRate
        let maxHR = 220 - 30
        let percentage = Double(hr) / Double(maxHR)

        if percentage < 0.7 {
            return .green
        } else if percentage < 0.85 {
            return .yellow
        } else {
            return .red
        }
    }

    private var currentPace: String? {
        // TODO: Get from workout data
        return "5:12"
    }

    private var currentPower: Int? {
        // TODO: Get from connected equipment
        return 340
    }
}

// MARK: - Preset Selector

struct OverlayPresetPicker: View {
    @Binding var settings: OverlaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a preset")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                PresetButton(
                    title: "Ultra Clean",
                    description: "Timer + Segment",
                    isSelected: settings.enabledElements == OverlaySettings.ultraClean.enabledElements
                ) {
                    settings = OverlaySettings.ultraClean
                }

                PresetButton(
                    title: "Balanced",
                    description: "Essential stats",
                    isSelected: settings.enabledElements == OverlaySettings.balanced.enabledElements
                ) {
                    settings = OverlaySettings.balanced
                }

                PresetButton(
                    title: "Detailed",
                    description: "All metrics",
                    isSelected: settings.enabledElements == OverlaySettings.full.enabledElements
                ) {
                    settings = OverlaySettings.full
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
    }

    struct PresetButton: View {
        let title: String
        let description: String
        let isSelected: Bool
        let action: () -> Void

        private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? electricBlue.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(isSelected ? electricBlue : Color.clear, lineWidth: 2)
                        )
                )
            }
        }
    }
}

// MARK: - Helper Extension

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

    // MARK: - Helper Functions

    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }


#Preview("Ultra Clean") {
    ZStack {
        Color.gray.ignoresSafeArea()

        CustomizableOverlay(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)])),
            settings: .constant(OverlaySettings.ultraClean),
            isEditing: false
        )
    }
}

#Preview("Preset Picker") {
    ZStack {
        Color.black.ignoresSafeArea()

        OverlayPresetPicker(settings: .constant(OverlaySettings.ultraClean))
            .padding()
    }
}
