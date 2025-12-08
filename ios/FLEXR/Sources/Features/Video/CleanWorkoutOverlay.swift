// FLEXR - Professional Camera Overlay
// Broadcast quality - minimal, unobtrusive, Instagram-worthy
// Inspired by professional sports broadcasts

import SwiftUI

struct CleanWorkoutOverlay: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel
    @State private var showControls = false

    var isRecording: Bool = false
    var onFlipCamera: (() -> Void)?
    var onStopRecording: (() -> Void)?

    var body: some View {
        ZStack {
            // Top section - Essential info only
            VStack {
                HStack(alignment: .top) {
                    // Left - Timer
                    timerDisplay

                    Spacer()

                    // Right - Heart rate
                    heartRateDisplay
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()
            }

            // Bottom section - Segment
            VStack {
                Spacer()
                segmentDisplay
                    .padding(.bottom, 50)
            }

            // Top right controls
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // Record indicator
                        recordIndicator

                        // Flip camera
                        flipButton
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                Spacer()
            }

            // Center stop button (tap to show)
            if showControls {
                stopButtonOverlay
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                showControls.toggle()
            }
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(formattedTime)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Heart Rate Display

    private var heartRateDisplay: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(hrColor)

            Text("\(mockHeartRate ?? 0)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Segment Display

    private var segmentDisplay: some View {
        VStack(spacing: 8) {
            // Main segment
            HStack(spacing: 16) {
                Image(systemName: segmentIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Text(currentSegmentName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
            }
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)

            // Next up (subtle)
            if let next = workoutVM.nextSegment {
                Text("NEXT: \(next.displayName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Record Indicator

    private var recordIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)

            Text("REC")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }

    // MARK: - Flip Button

    private var flipButton: some View {
        Button {
            // Only allow flip when NOT recording
            if !isRecording {
                onFlipCamera?()
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath.camera")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isRecording ? .white.opacity(0.3) : .white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                )
        }
        .disabled(isRecording)
    }

    // MARK: - Stop Button Overlay

    private var stopButtonOverlay: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showControls = false
                    }
                }

            // Stop button
            Button {
                onStopRecording?()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 90, height: 90)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red)
                        .frame(width: 34, height: 34)
                }
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }

    // MARK: - Computed Properties

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

    private var currentSegmentName: String {
        workoutVM.currentSegment?.displayName ?? "READY"
    }

    private var segmentIcon: String {
        switch workoutVM.currentSegment?.segmentType {
        case .run:
            return "figure.run"
        case .station:
            return "dumbbell.fill"
        case .warmup:
            return "flame.fill"
        case .cooldown:
            return "wind"
        default:
            return "bolt.fill"
        }
    }

    private var formattedTime: String {
        let totalSeconds = Int(workoutVM.totalElapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        CleanWorkoutOverlay(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(
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
}
