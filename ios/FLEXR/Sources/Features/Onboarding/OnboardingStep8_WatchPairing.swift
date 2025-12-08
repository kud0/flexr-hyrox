import SwiftUI
import WatchConnectivity

// MARK: - Step 8: Apple Watch Pairing
// Check if user has Apple Watch paired

struct OnboardingStep8_WatchPairing: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @State private var showingWatchApp = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Watch icon
                HStack {
                    Spacer()
                    Image(systemName: watchConnectivity.isPaired ? "applewatch" : "applewatch.slash")
                        .font(.system(size: 80))
                        .foregroundColor(watchConnectivity.isPaired ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)
                    Spacer()
                }

                // Header
                header

                // Status card
                statusCard

                // Features
                VStack(spacing: DesignSystem.Spacing.small) {
                    FeatureRow(
                        icon: "heart.fill",
                        title: "Real-time Heart Rate",
                        subtitle: "Track intensity zones during workouts"
                    )

                    FeatureRow(
                        icon: "bolt.fill",
                        title: "Live Metrics",
                        subtitle: "See pace, distance, and time on your wrist"
                    )

                    FeatureRow(
                        icon: "figure.run",
                        title: "Workout Controls",
                        subtitle: "Start, pause, and complete workouts from Watch"
                    )

                    FeatureRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Auto-Sync",
                        subtitle: "Workouts automatically sync to your iPhone"
                    )
                }

                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Navigation buttons
                navigationButtons
            }
            .padding(DesignSystem.Spacing.large)
        }
        .background(DesignSystem.Colors.background)
        .onAppear {
            checkWatchStatus()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(watchConnectivity.isPaired ? "Apple Watch connected" : "Apple Watch (Optional)")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text(watchConnectivity.isPaired
                ? "Your watch is ready for workouts"
                : "Connect later to unlock advanced tracking")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: watchConnectivity.isPaired ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.title2)
                .foregroundColor(watchConnectivity.isPaired ? .green : DesignSystem.Colors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(watchStatusTitle)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(watchStatusMessage)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var watchStatusTitle: String {
        if watchConnectivity.isPaired {
            if watchConnectivity.isWatchAppInstalled {
                return watchConnectivity.isReachable ? "Connected & Ready" : "Watch App Installed"
            } else {
                return "Install Watch App"
            }
        } else {
            return "No Watch Paired"
        }
    }

    private var watchStatusMessage: String {
        if watchConnectivity.isPaired {
            if watchConnectivity.isWatchAppInstalled {
                return "You can start tracking workouts immediately"
            } else {
                return "Install the FLEXR app on your Apple Watch to begin"
            }
        } else {
            return "Pair your Apple Watch in the Watch app to enable advanced features"
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Skip button if no watch
            if !watchConnectivity.isPaired {
                Button(action: {
                    onboardingData.hasAppleWatch = false
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

                Button(action: {
                    onboardingData.hasAppleWatch = watchConnectivity.isPaired
                    onNext()
                }) {
                    Text("Continue")
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

    private func checkWatchStatus() {
        // Status is automatically tracked by WatchConnectivityService
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}

// MARK: - Preview

#Preview {
    OnboardingStep8_WatchPairing(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
