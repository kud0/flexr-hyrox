// FLEXR - Video Recording Service
// Handles camera capture, overlay compositing, and video export

import AVFoundation
import UIKit
import SwiftUI
import Combine

@MainActor
class VideoRecordingService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var isPreparing = false
    @Published var error: RecordingError?

    // MARK: - Private Properties

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var outputURL: URL?
    private var recordingTimer: Timer?
    private var startTime: Date?

    // Settings
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var videoQuality: VideoQuality = .hd720p
    @Published var overlayStyle: OverlayStyle = .neonEdges

    // MARK: - Enums

    enum VideoQuality {
        case hd720p
        case hd1080p

        var preset: AVCaptureSession.Preset {
            switch self {
            case .hd720p: return .hd1280x720
            case .hd1080p: return .hd1920x1080
            }
        }

        var displayName: String {
            switch self {
            case .hd720p: return "720p (Recommended)"
            case .hd1080p: return "1080p (Higher Quality)"
            }
        }
    }

    enum OverlayStyle: String, CaseIterable {
        case neonEdges = "Neon Edges"
        case progressRings = "Progress Rings"
        case racingHUD = "Racing HUD"
        case glassPanel = "Glass Panel"
        case minimal = "Minimal"
    }

    enum RecordingError: LocalizedError {
        case cameraNotAvailable
        case microphoneNotAvailable
        case permissionDenied
        case recordingFailed(String)
        case exportFailed(String)

        var errorDescription: String? {
            switch self {
            case .cameraNotAvailable:
                return "Camera is not available"
            case .microphoneNotAvailable:
                return "Microphone is not available"
            case .permissionDenied:
                return "Camera/Microphone permission denied"
            case .recordingFailed(let message):
                return "Recording failed: \(message)"
            case .exportFailed(let message):
                return "Export failed: \(message)"
            }
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Permission Checks

    func checkPermissions() async -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        // Check camera permission
        guard cameraStatus != .denied && cameraStatus != .restricted else {
            error = .permissionDenied
            return false
        }

        // Request camera if needed
        if cameraStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                error = .permissionDenied
                return false
            }
        }

        // Check microphone permission
        guard micStatus != .denied && micStatus != .restricted else {
            error = .permissionDenied
            return false
        }

        // Request microphone if needed
        if micStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard granted else {
                error = .permissionDenied
                return false
            }
        }

        return true
    }

    // MARK: - Setup

    func setupCaptureSession() async throws {
        isPreparing = true
        defer { isPreparing = false }

        // Check permissions first
        guard await checkPermissions() else {
            throw RecordingError.permissionDenied
        }

        let session = AVCaptureSession()
        session.sessionPreset = videoQuality.preset

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: cameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            throw RecordingError.cameraNotAvailable
        }
        session.addInput(videoInput)

        // Add audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              session.canAddInput(audioInput) else {
            throw RecordingError.microphoneNotAvailable
        }
        session.addInput(audioInput)

        // Add movie file output
        let movieOutput = AVCaptureMovieFileOutput()
        guard session.canAddOutput(movieOutput) else {
            throw RecordingError.recordingFailed("Cannot add movie output")
        }
        session.addOutput(movieOutput)

        // Store references
        self.captureSession = session
        self.videoOutput = movieOutput

        // Start session
        session.startRunning()

        print("📹 Capture session configured: \(videoQuality.preset.rawValue)")
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }

        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
        }

        return previewLayer
    }

    // MARK: - Recording Control

    func startRecording() {
        guard let movieOutput = videoOutput else {
            error = .recordingFailed("Output not configured")
            return
        }

        // Create output file URL
        let fileName = "FLEXR_\(Date().timeIntervalSince1970).mov"
        let tempDir = FileManager.default.temporaryDirectory
        outputURL = tempDir.appendingPathComponent(fileName)

        guard let url = outputURL else {
            error = .recordingFailed("Cannot create output URL")
            return
        }

        // Remove existing file if any
        try? FileManager.default.removeItem(at: url)

        // Start recording
        movieOutput.startRecording(to: url, recordingDelegate: self)

        isRecording = true
        startTime = Date()

        // Start duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }

        print("🔴 Recording started: \(url.lastPathComponent)")
    }

    func stopRecording() {
        videoOutput?.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil

        print("⏹️ Recording stopped")
    }

    func switchCamera() async {
        guard let session = captureSession else { return }

        // Toggle position
        cameraPosition = cameraPosition == .back ? .front : .back

        // Reconfigure session
        session.beginConfiguration()

        // Remove old video input
        if let currentInput = session.inputs.first(where: {
            ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true
        }) {
            session.removeInput(currentInput)
        }

        // Add new video input
        if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: cameraPosition),
           let newInput = try? AVCaptureDeviceInput(device: newDevice),
           session.canAddInput(newInput) {
            session.addInput(newInput)
        }

        session.commitConfiguration()

        print("📹 Camera switched to: \(cameraPosition == .back ? "back" : "front")")
    }

    // MARK: - Cleanup

    func cleanup() {
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        previewLayer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        startTime = nil
        isRecording = false
        recordingDuration = 0

        print("🧹 Video recording service cleaned up")
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoRecordingService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                               didStartRecordingTo fileURL: URL,
                               from connections: [AVCaptureConnection]) {
        print("📹 Recording started to: \(fileURL.lastPathComponent)")
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                               didFinishRecordingTo outputFileURL: URL,
                               from connections: [AVCaptureConnection],
                               error: Error?) {
        Task { @MainActor in
            self.isRecording = false
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil

            if let error = error {
                print("❌ Recording error: \(error.localizedDescription)")
                self.error = .recordingFailed(error.localizedDescription)
            } else {
                print("✅ Recording finished: \(outputFileURL.lastPathComponent)")
                // File is ready at outputFileURL
                self.outputURL = outputFileURL
            }
        }
    }
}

// MARK: - Helper Extensions

extension VideoRecordingService {
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func getLastRecordingURL() -> URL? {
        return outputURL
    }
}
