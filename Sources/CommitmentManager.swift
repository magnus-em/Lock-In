import Foundation
import AVFoundation
import Combine

class CommitmentManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var isPlayingBack = false
    @Published var micPermissionGranted = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private let recordingURL = URL(fileURLWithPath: "/tmp/focus_commitment_oath.m4a")

    override init() {
        super.init()
        hasRecording = FileManager.default.fileExists(atPath: recordingURL.path)
        checkMicPermission()
    }

    // MARK: - Permission

    private func checkMicPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            micPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async { self?.micPermissionGranted = granted }
            }
        default:
            micPermissionGranted = false
        }
    }

    func requestMicPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async { self?.micPermissionGranted = granted }
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard micPermissionGranted else { requestMicPermission(); return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            recorder?.record()
            isRecording = true
        } catch {}
    }

    func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        hasRecording = FileManager.default.fileExists(atPath: recordingURL.path)
    }

    // MARK: - Playback

    func playback() {
        guard hasRecording else { return }
        stopPlayback()
        do {
            player = try AVAudioPlayer(contentsOf: recordingURL)
            player?.delegate = self
            player?.play()
            isPlayingBack = true
        } catch {
            isPlayingBack = false
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        isPlayingBack = false
    }

    func clearRecording() {
        stopPlayback()
        try? FileManager.default.removeItem(at: recordingURL)
        hasRecording = false
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlayingBack = false }
    }
}
