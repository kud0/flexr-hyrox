import SwiftUI

// MARK: - Step 5: Optional Performance Numbers
// Running PRs (1km, 5km, Zone 2 pace) - All optional

struct OnboardingStep5_PerformanceNumbers: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    @FocusState private var focusedField: Field?
    @State private var running1kmInput: String = ""
    @State private var running5kmInput: String = ""
    @State private var z2PaceInput: String = ""

    enum Field {
        case running1km, running5km, z2Pace
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Optional badge
                optionalBadge

                // Performance inputs
                VStack(spacing: DesignSystem.Spacing.large) {
                    running1kmInputView
                    running5kmInputView
                    z2PaceInputView
                }

                // Info box
                infoBox

                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Navigation buttons
                navigationButtons
            }
            .padding(DesignSystem.Spacing.large)
        }
        .background(DesignSystem.Colors.background)
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Running performance")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Help the AI set better paces (optional)")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Optional Badge

    private var optionalBadge: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "info.circle")
                .foregroundColor(DesignSystem.Colors.primary)

            Text("Skip if you don't know - the AI will estimate from your background")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Running 1km Input

    private var running1kmInputView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("1km Time Trial")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Max effort 1km run time")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                TextField("Minutes", text: $running1kmInput)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                focusedField == .running1km ? DesignSystem.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .focused($focusedField, equals: .running1km)
                    .onChange(of: running1kmInput) { _, newValue in
                        if let seconds = parseTimeInput(newValue) {
                            onboardingData.running1kmSeconds = seconds
                        }
                    }

                Text("mm:ss")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            if !running1kmInput.isEmpty, let seconds = onboardingData.running1kmSeconds {
                Text("Pace: \(formatPace(seconds)) /km")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }

    // MARK: - Running 5km Input

    private var running5kmInputView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("5km Time Trial")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Best 5km run time")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                TextField("Minutes", text: $running5kmInput)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                focusedField == .running5km ? DesignSystem.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .focused($focusedField, equals: .running5km)
                    .onChange(of: running5kmInput) { _, newValue in
                        if let seconds = parseTimeInput(newValue) {
                            onboardingData.running5kmSeconds = seconds
                        }
                    }

                Text("mm:ss")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            if !running5kmInput.isEmpty, let seconds = onboardingData.running5kmSeconds {
                let avgPace = seconds / 5.0
                Text("Avg pace: \(formatPace(avgPace)) /km")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }

    // MARK: - Zone 2 Pace Input

    private var z2PaceInputView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Zone 2 Pace")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Comfortable conversational pace")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                TextField("Pace", text: $z2PaceInput)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                focusedField == .z2Pace ? DesignSystem.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .focused($focusedField, equals: .z2Pace)
                    .onChange(of: z2PaceInput) { _, newValue in
                        if let seconds = parseTimeInput(newValue) {
                            onboardingData.comfortableZ2Pace = seconds
                        }
                    }

                Text("mm:ss /km")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
    }

    // MARK: - Info Box

    private var infoBox: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Don't know these numbers?")
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("No worries! The AI will estimate based on your training background. You can add these later after testing.")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Skip button (prominent)
            Button(action: {
                focusedField = nil
                onNext()
            }) {
                Text("Skip for now")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.medium)
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.medium)
                }

                Button(action: {
                    focusedField = nil
                    onNext()
                }) {
                    Text("Finish")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func parseTimeInput(_ input: String) -> Double? {
        // Remove any non-numeric characters except colon
        let cleaned = input.replacingOccurrences(of: "[^0-9:]", with: "", options: .regularExpression)

        if cleaned.contains(":") {
            let components = cleaned.split(separator: ":")
            if components.count == 2,
               let minutes = Double(components[0]),
               let seconds = Double(components[1]) {
                return minutes * 60 + seconds
            }
        } else if let totalSeconds = Double(cleaned) {
            // If just a number, treat as seconds if < 60, otherwise as mm:ss format
            if totalSeconds < 60 {
                return totalSeconds
            } else {
                let minutes = floor(totalSeconds / 100)
                let seconds = totalSeconds.truncatingRemainder(dividingBy: 100)
                return minutes * 60 + seconds
            }
        }

        return nil
    }

    private func formatPace(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    OnboardingStep5_PerformanceNumbers(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
