// FLEXR Watch - Workout Preview View
// Clean, Apple-like design before starting workout

import SwiftUI

struct WorkoutPreviewView: View {
    let workout: WatchPlannedWorkout
    let onStart: (Bool, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var skipWarmup = false
    @State private var skipCooldown = false

    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    private var sortedSegments: [WatchWorkoutSegment] {
        workout.segments?.sorted(by: { $0.orderIndex < $1.orderIndex }) ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Type label
                Text(workoutTypeLabel.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(fitnessGreen)
                    .padding(.top, 4)

                // Workout name - large
                Text(displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 4)

                // Stats row
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                        Text("\(workout.estimatedDuration)")
                            .font(.system(size: 18, weight: .bold))
                        Text("MIN")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.system(size: 16))
                        Text("\(sortedSegments.count)")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .padding(.top, 12)

                // Toggles
                if hasWarmup || hasCooldown {
                    VStack(spacing: 8) {
                        if hasWarmup {
                            SkipToggle(title: "Skip Warmup", isOn: $skipWarmup)
                        }
                        if hasCooldown {
                            SkipToggle(title: "Skip Cooldown", isOn: $skipCooldown)
                        }
                    }
                    .padding(.top, 16)
                }

                // START button
                Button {
                    onStart(skipWarmup, skipCooldown)
                    dismiss()
                } label: {
                    Text("START")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(fitnessGreen)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
            .padding(.horizontal, 12)
        }
    }

    private var displayName: String {
        if let watchName = workout.watchName, !watchName.isEmpty {
            return watchName.uppercased()
        }
        return String(workout.name.prefix(12)).uppercased()
    }

    private var workoutTypeLabel: String {
        switch workout.workoutType {
        case "running": return "Running"
        case "strength": return "Strength"
        case "station_focus": return "Stations"
        case "full_simulation": return "Full Sim"
        case "half_simulation": return "Half Sim"
        case "recovery": return "Recovery"
        default: return "Workout"
        }
    }

    private var hasWarmup: Bool {
        sortedSegments.contains { $0.segmentType.lowercased() == "warmup" }
    }

    private var hasCooldown: Bool {
        sortedSegments.contains { $0.segmentType.lowercased() == "cooldown" }
    }
}

// MARK: - Skip Toggle

struct SkipToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isOn ? .orange : .gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
