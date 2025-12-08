// FLEXR - Tripod Mode
// Premium, impressive display - Apple Fitness+ quality
// Large, bold, confident - designed to impress

import SwiftUI

struct TripodModeView: View {
    @ObservedObject var viewModel: WorkoutExecutionViewModel
    @State private var currentPage = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Main Display - BIG & BOLD
            mainDisplay
                .tag(0)
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            viewModel.completeCurrentSegment()
                        }
                )

            // Page 2: Controls
            controlsDisplay
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            startBreathing()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Main Display (Page 1)

    private var mainDisplay: some View {
        ZStack {
            // Deep black background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Current segment - SMALL (we already know what we're doing)
                if let segment = viewModel.currentSegment {
                    HStack(spacing: 8) {
                        Text(segment.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)

                        if !segment.targetDescription.isEmpty {
                            Text("•")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))

                            Text(segment.targetDescription)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 60)
                }

                Spacer()

                // Timer - MASSIVE
                Text(formattedTime)
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(-2)
                    .scaleEffect(scale)

                Spacer()
                    .frame(height: 60)

                // Heart Rate - Clean & Simple
                if let hr = mockHeartRate {
                    HStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(hrColor)

                        Text("\(hr)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Spacer()
                    .frame(height: 60)

                // NEXT segment - HUGE (prepare mentally!)
                VStack(spacing: 24) {
                    if let next = viewModel.nextSegment {
                        VStack(spacing: 12) {
                            Text("NEXT UP")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            Text(next.displayName)
                                .font(.system(size: 56, weight: .black))
                                .foregroundColor(.white)
                                .textCase(.uppercase)
                                .tracking(2)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("FINAL SEGMENT")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                    }

                    // COMPLETE button (big and clear)
                    Button {
                        viewModel.completeCurrentSegment()
                    } label: {
                        Text("COMPLETE")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.black)
                            .tracking(1)
                            .padding(.horizontal, 50)
                            .padding(.vertical, 20)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }

                    Text("Double tap to complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 80)

                // Page dots
                pageIndicator
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Controls Display (Page 2)

    private var controlsDisplay: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 60) {
                Spacer()

                // Pause/Resume - HUGE
                Button {
                    viewModel.togglePause()
                } label: {
                    VStack(spacing: 24) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 100, weight: .thin))
                            .foregroundColor(.white)

                        Text(viewModel.isPaused ? "RESUME" : "PAUSE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1)
                    }
                }

                // End - Clear action
                Button {
                    viewModel.endWorkout()
                } label: {
                    VStack(spacing: 24) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 100, weight: .thin))
                            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))

                        Text("END")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                            .tracking(1)
                    }
                }

                Spacer()

                pageIndicator
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(currentPage == 0 ? Color.white : Color.white.opacity(0.25))
                .frame(width: 12, height: 12)
            Circle()
                .fill(currentPage == 1 ? Color.white : Color.white.opacity(0.25))
                .frame(width: 12, height: 12)
        }
    }

    // MARK: - Computed Properties

    private var currentSegmentName: String {
        viewModel.currentSegment?.displayName ?? "GET READY"
    }

    private var formattedTime: String {
        let totalSeconds = Int(viewModel.totalElapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private var mockHeartRate: Int? {
        152 // TODO: Real heart rate
    }

    private var hrColor: Color {
        guard let hr = mockHeartRate else { return .gray }
        let maxHR = 190
        let percentage = Double(hr) / Double(maxHR)

        if percentage < 0.7 {
            return Color(red: 0.3, green: 0.85, blue: 0.4)
        } else if percentage < 0.85 {
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        } else {
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scale = 1.03
        }
    }
}

// MARK: - Preview

#Preview {
    TripodModeView(
        viewModel: WorkoutExecutionViewModel(workout: Workout(
            userId: UUID(),
            date: Date(),
            type: .fullSimulation,
            segments: [
                WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)
            ]
        ))
    )
}
