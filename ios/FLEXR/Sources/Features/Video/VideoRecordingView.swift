// FLEXR - Video Recording View
// Record workout with customizable overlay
// Simple, clean, professional

import SwiftUI
import AVFoundation

struct VideoRecordingView: View {
    @StateObject private var recordingService = VideoRecordingService()
    @ObservedObject var workoutVM: WorkoutExecutionViewModel

    @State private var overlaySettings = OverlaySettings.ultraClean
    @State private var isEditingOverlay = false
    @State private var showSettings = false
    @State private var showWorkoutControls = false
    @State private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @State private var useFrontCamera = false

    @Environment(\.dismiss) private var dismiss

    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(previewLayer: $cameraPreviewLayer)
                .ignoresSafeArea()
                .onAppear {
                    setupCamera()
                    // Start recording immediately when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !recordingService.isRecording && !recordingService.isPreparing {
                            startRecording()
                        }
                    }
                }

            // Clean static overlay (handles everything)
            CleanWorkoutOverlay(
                workoutVM: workoutVM,
                isRecording: recordingService.isRecording,
                onFlipCamera: {
                    Task {
                        useFrontCamera.toggle()
                        await recordingService.switchCamera()
                    }
                },
                onStopRecording: {
                    stopRecording()
                }
            )
        }
        .statusBar(hidden: true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        withAnimation(.spring()) {
                            showWorkoutControls = true
                        }
                    }
                }
        )
        .onDisappear {
            recordingService.cleanup()
        }
    }

    // MARK: - Setup Controls (Before Recording)

    private var setupControls: some View {
        VStack {
            // Top bar
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.ultraThinMaterial))
                }

                Spacer()

                // Camera indicator
                Text(useFrontCamera ? "FRONT" : "REAR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                Capsule()
                                    .strokeBorder(electricBlue, lineWidth: 1.5)
                            )
                    )

                // Flip camera
                Button {
                    Task {
                        useFrontCamera.toggle()
                        await recordingService.switchCamera()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.ultraThinMaterial))
                }
            }
            .padding()

            Spacer()

            // Record button
            VStack(spacing: 16) {
                if recordingService.isPreparing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    Button {
                        startRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)

                            Circle()
                                .strokeBorder(Color.white, lineWidth: 4)
                                .frame(width: 86, height: 86)
                        }
                    }
                }

                Text("Tap to start recording")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 50)
        }
    }

    // MARK: - Recording Controls (During Recording)

    private var recordingControls: some View {
        VStack {
            Spacer()

            // Stop button
            Button {
                stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 86, height: 86)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.bottom, 50)
        }
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        // Preset picker
                        OverlayPresetPicker(settings: $overlaySettings)

                        // Individual element toggles
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Show/Hide Elements")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            VStack(spacing: 8) {
                                ForEach(OverlayElement.allCases) { element in
                                    Toggle(isOn: Binding(
                                        get: { overlaySettings.enabledElements.contains(element) },
                                        set: { enabled in
                                            if enabled {
                                                overlaySettings.enabledElements.insert(element)
                                            } else {
                                                overlaySettings.enabledElements.remove(element)
                                            }
                                        }
                                    )) {
                                        HStack {
                                            Image(systemName: element.icon)
                                                .font(.system(size: 14))
                                                .frame(width: 20)

                                            Text(element.rawValue)
                                                .font(.system(size: 15))
                                        }
                                        .foregroundColor(.white)
                                    }
                                    .tint(electricBlue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }

                        // Customize positions
                        Button {
                            withAnimation {
                                isEditingOverlay.toggle()
                                showSettings = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 16))

                                Text(isEditingOverlay ? "Done Editing" : "Customize Positions")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(electricBlue)
                            )
                        }

                        // Video quality
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Video Quality")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                QualityButton(
                                    title: "720p",
                                    isSelected: recordingService.videoQuality == .hd720p
                                ) {
                                    recordingService.videoQuality = .hd720p
                                }

                                QualityButton(
                                    title: "1080p",
                                    isSelected: recordingService.videoQuality == .hd1080p
                                ) {
                                    recordingService.videoQuality = .hd1080p
                                }
                            }
                        }

                        // Optional branding
                        Toggle(isOn: $overlaySettings.showBranding) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 14))

                                Text("Show FLEXR watermark")
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(.white)
                        }
                        .tint(electricBlue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding()
                }

                // Close settings button
                Button {
                    withAnimation {
                        showSettings = false
                    }
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding()
            }
            .frame(maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.95))
                    .ignoresSafeArea()
            )
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showSettings = false
                    }
                }
        )
    }

    struct QualityButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? electricBlue : Color.white.opacity(0.1))
                    )
            }
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        Task {
            do {
                try await recordingService.setupCaptureSession()
                cameraPreviewLayer = recordingService.getPreviewLayer()
            } catch {
                print("❌ Camera setup failed: \(error)")
                recordingService.error = error as? VideoRecordingService.RecordingError
            }
        }
    }

    private func startRecording() {
        recordingService.startRecording()
    }

    private func stopRecording() {
        recordingService.stopRecording()

        // Wait a moment for file to be saved, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }

    private func saveVideoToPhotos(_ url: URL) {
        // Already saved by VideoRecordingService
        print("✅ Video saved: \(url.lastPathComponent)")
    }

    // MARK: - Workout Controls Panel (WatchOS Style)

    private var workoutControlsPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)

                VStack(spacing: 12) {
                    // Pause/Resume button
                    Button {
                        withAnimation {
                            workoutVM.togglePause()
                            showWorkoutControls = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: workoutVM.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 18, weight: .semibold))

                            Text(workoutVM.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.8))
                        )
                    }

                    // End Workout button
                    Button {
                        withAnimation {
                            workoutVM.endWorkout()
                            showWorkoutControls = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 18, weight: .semibold))

                            Text("End Workout")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                        )
                    }

                    // Cancel button
                    Button {
                        withAnimation {
                            showWorkoutControls = false
                        }
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.95))
                    .ignoresSafeArea()
            )
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showWorkoutControls = false
                    }
                }
        )
    }

    // MARK: - Swipe Up Indicator

    private var swipeUpIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.up")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Text("Swipe up for controls")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
        .padding(.bottom, 30)
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    @Binding var previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let layer = previewLayer else { return }

        // Remove existing layer if any
        uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // Add new layer
        layer.frame = uiView.bounds
        layer.videoGravity = .resizeAspectFill
        uiView.layer.addSublayer(layer)
    }
}

// MARK: - Preview

#Preview {
    VideoRecordingView(
        workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)]))
    )
}
