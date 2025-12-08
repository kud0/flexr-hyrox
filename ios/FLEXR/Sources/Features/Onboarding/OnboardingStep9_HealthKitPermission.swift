import SwiftUI
import HealthKit

// MARK: - Step 9: HealthKit Permission
// Request access to Health data

struct OnboardingStep9_HealthKitPermission: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    @StateObject private var healthKitService = HealthKitService()
    @State private var isRequesting = false
    @State private var permissionGranted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Health icon
                HStack {
                    Spacer()
                    Image(systemName: permissionGranted ? "heart.circle.fill" : "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(permissionGranted ? .green : .pink)
                    Spacer()
                }

                // Header
                header

                // Data types we'll access
                VStack(spacing: DesignSystem.Spacing.small) {
                    HealthDataRow(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        subtitle: "Track intensity and optimize training zones"
                    )

                    HealthDataRow(
                        icon: "figure.run",
                        title: "Workouts",
                        subtitle: "Record and analyze your training sessions"
                    )

                    HealthDataRow(
                        icon: "flame.fill",
                        title: "Active Energy",
                        subtitle: "Monitor calories burned during workouts"
                    )

                    HealthDataRow(
                        icon: "figure.walk",
                        title: "Distance",
                        subtitle: "Track running and movement metrics"
                    )
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
        .onAppear {
            checkPermissionStatus()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(permissionGranted ? "Health access granted" : "Enable Health sync")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text(permissionGranted
                ? "The AI can now optimize your training plan"
                : "The AI will use your health data to personalize training")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Info Box

    private var infoBox: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "lock.shield.fill")
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your privacy matters")
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("Your health data stays on your device and is never shared. The AI only uses it to optimize your workouts.")
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
            // Enable Health button or status
            if !permissionGranted {
                Button(action: requestHealthKitPermission) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Enable Health Access")
                        }
                    }
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
                .disabled(isRequesting)

                Button(action: {
                    onboardingData.healthKitEnabled = false
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

                if permissionGranted {
                    Button(action: {
                        onboardingData.healthKitEnabled = true
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
    }

    // MARK: - Helper Functions

    private func checkPermissionStatus() {
        permissionGranted = healthKitService.isAuthorized
    }

    private func requestHealthKitPermission() {
        isRequesting = true

        Task {
            do {
                try await healthKitService.requestAuthorization()

                await MainActor.run {
                    permissionGranted = healthKitService.isAuthorized
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    // Still allow continuing even if permission denied
                }
            }
        }
    }
}

// MARK: - Health Data Row Component

struct HealthDataRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Preview

#Preview {
    OnboardingStep9_HealthKitPermission(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
