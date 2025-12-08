// FLEXR - Plan Generating View
// Shows loading animation while AI generates the training plan

import SwiftUI

struct PlanGeneratingView: View {
    @State private var isAnimating = false
    @State private var currentMessage = 0

    private let messages = [
        "Analyzing your performance data...",
        "Calculating training load capacity...",
        "Identifying your weakest stations...",
        "Optimizing weekly progression...",
        "Generating adaptive workouts..."
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Animated icon
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.3 : 0.9)
                        .opacity(isAnimating ? 0.3 : 0.6)

                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)

                    // Main icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(spacing: 16) {
                    Text("AI Analysis in Progress")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(messages[currentMessage])
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .animation(.easeInOut, value: currentMessage)
                }

                Spacer()

                // Progress indicator
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                        .scaleEffect(1.2)

                    Text("Processing your unique training profile...")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Start pulsing animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }

            // Cycle through messages
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                withAnimation {
                    currentMessage = (currentMessage + 1) % messages.count
                }
            }
        }
    }
}

#Preview {
    PlanGeneratingView()
}
