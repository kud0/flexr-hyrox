// FLEXR - Video Recording Service
// Handles AVFoundation camera capture and video recording
// Professional-grade video with overlay composition

import Foundation
import AVFoundation
import Photos
import UIKit

@MainActor
class VideoRecordingService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var isPreparing = false
    @Published var error: RecordingError?
    @Published var videoQuality: VideoQuality = .hd1080p

    // MARK: - Private Properties

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCamera: AVCaptureDevice.Position = .back
    private var lastRecordingURL: URL?

    // MARK: - Enums

    enum RecordingError: Error, LocalizedError {
        case cameraPermissionDenied
        case microphonePermissionDenied
        case cameraUnavailable
        case setupFailed
        case recordingFailed

        var errorDescription: String? {
            switch self {
            case .cameraPermissionDenied:
                return "Camera access denied. Please enable in Settings."
            case .microphonePermissionDenied:
                return "Microphone access denied. Please enable in Settings."
            case .cameraUnavailable:
                return "Camera unavailable"
            case .setupFailed:
                return "Failed to setup camera"
            case .recordingFailed:
                return "Recording failed"
            }
        }
    }

    enum VideoQuality {
        case hd720p
        case hd1080p

        var preset: AVCaptureSession.Preset {
            switch self {
            case .hd720p:
                return .hd1280x720
            case .hd1080p:
                return .hd1920x1080
            }
        }
    }

    // MARK: - Setup

    func setupCaptureSession() async throws {
        isPreparing = true
        defer { isPreparing = false }

        // Run on background thread to avoid main thread warning
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    try await self.setupCameraOnBackground()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func setupCameraOnBackground() async throws {
        // Check permissions first
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .denied || cameraStatus == .restricted {
            throw RecordingError.cameraPermissionDenied
        }

        if cameraStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                throw RecordingError.cameraPermissionDenied
            }
        }

        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .denied || audioStatus == .restricted {
            throw RecordingError.microphonePermissionDenied
        }

        if audioStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted {
                throw RecordingError.microphonePermissionDenied
            }
        }

        // Setup capture session
        let session = AVCaptureSession()
        session.sessionPreset = videoQuality.preset

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw RecordingError.cameraUnavailable
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            throw RecordingError.setupFailed
        }

        // Add audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            print("⚠️ Audio device unavailable")
            // Continue without audio - not critical
            return
        }

        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        // Add movie file output
        let output = AVCaptureMovieFileOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            throw RecordingError.setupFailed
        }

        self.videoOutput = output
        self.captureSession = session

        // Create preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        self.previewLayer = preview

        // Start session on background thread
        await Task.detached {
            session.startRunning()
        }.value

        await MainActor.run {
            print("✅ Camera setup complete")
        }
    }

    // MARK: - Camera Control

    func switchCamera() async {
        guard let session = captureSession else { return }

        isPreparing = true
        defer { isPreparing = false }

        // Stop session
        session.stopRunning()

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        // Switch camera position
        currentCamera = currentCamera == .back ? .front : .back

        // Add new video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("❌ Failed to switch camera")
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        // Re-add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
        }

        // Restart session
        session.startRunning()

        print("📸 Switched to \(currentCamera == .front ? "front" : "rear") camera")
    }

    // MARK: - Recording Control

    func startRecording() {
        guard let output = videoOutput, !isRecording else { return }

        // Generate file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "flexr_workout_\(Date().timeIntervalSince1970).mov"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // Delete file if it exists
        try? FileManager.default.removeItem(at: fileURL)

        // Start recording
        output.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true

        print("🎥 Recording started: \(fileName)")
    }

    func stopRecording() {
        guard let output = videoOutput, isRecording else { return }

        output.stopRecording()
        isRecording = false

        print("⏹️ Recording stopped")
    }

    // MARK: - Getters

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }

    func getLastRecordingURL() -> URL? {
        return lastRecordingURL
    }

    // MARK: - Cleanup

    func cleanup() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        videoOutput = nil

        print("🧹 Camera cleanup complete")
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoRecordingService: AVCaptureFileOutputRecordingDelegate {

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("📹 Recording file created: \(fileURL.lastPathComponent)")
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if let error = error {
            print("❌ Recording error: \(error.localizedDescription)")
            Task { @MainActor in
                self.error = .recordingFailed
            }
            return
        }

        Task { @MainActor in
            self.lastRecordingURL = outputFileURL
            print("✅ Recording saved: \(outputFileURL.lastPathComponent)")

            // Save to Photos library
            await self.saveToPhotosLibrary(url: outputFileURL)
        }
    }

    // MARK: - Save to Photos

    private func saveToPhotosLibrary(url: URL) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        var authorized = false

        switch status {
        case .authorized, .limited:
            authorized = true
        case .notDetermined:
            authorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        default:
            print("⚠️ Photos access denied")
            return
        }

        guard authorized else { return }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            print("✅ Video saved to Photos")
        } catch {
            print("❌ Failed to save to Photos: \(error.localizedDescription)")
        }
    }
}
