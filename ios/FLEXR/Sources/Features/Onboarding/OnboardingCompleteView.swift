// FLEXR - Onboarding Complete
// Native Apple-style completion screen

import SwiftUI

struct OnboardingCompleteView: View {
    let onStartTraining: () -> Void

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Success checkmark
                ZStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.78, blue: 0.32).opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.6 : 0)

                    Circle()
                        .fill(Color(red: 0.0, green: 0.78, blue: 0.32))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.black)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.3)
                .padding(.bottom, 32)

                // Header
                VStack(spacing: 8) {
                    Text("You're All Set!")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Your personalized HYROX training plan is ready")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .padding(.bottom, 48)

                // Features ready
                VStack(spacing: 16) {
                    CompleteFeatureRow(
                        icon: "brain.head.profile",
                        title: "AI-Generated Workouts",
                        subtitle: "Tailored to your goals"
                    )

                    CompleteFeatureRow(
                        icon: "chart.xyaxis.line",
                        title: "Progress Tracking",
                        subtitle: "See improvements weekly"
                    )

                    CompleteFeatureRow(
                        icon: "bell.badge.fill",
                        title: "Smart Notifications",
                        subtitle: "Never miss a session"
                    )
                }
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1.0 : 0.0)

                Spacer()

                // Start Training button
                Button(action: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    onStartTraining()
                }) {
                    HStack(spacing: 8) {
                        Text("Start Training")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.0, green: 0.78, blue: 0.32))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
                .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                isAnimating = true
            }

            // Success haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Complete Feature Row

struct CompleteFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.0, green: 0.78, blue: 0.32))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
        )
    }
}

#Preview {
    OnboardingCompleteView(onStartTraining: {})
}
