import Foundation
import AVFoundation

class CommitmentStore: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var isPlaying = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?

    private var todayURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Focus/oaths")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        return dir.appendingPathComponent("\(df.string(from: Date())).m4a")
    }

    override init() {
        super.init()
        hasRecording = FileManager.default.fileExists(atPath: todayURL.path)
    }

    func toggleRecord() {
        if isRecording {
            recorder?.stop(); recorder = nil
            isRecording = false
            hasRecording = FileManager.default.fileExists(atPath: todayURL.path)
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .authorized {
            startRecording()
        } else {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async { if granted { self?.startRecording() } }
            }
        }
    }

    private func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        recorder = try? AVAudioRecorder(url: todayURL, settings: settings)
        recorder?.delegate = self
        recorder?.record()
        isRecording = true
    }

    func togglePlay() {
        if isPlaying { player?.stop(); player = nil; isPlaying = false; return }
        player = try? AVAudioPlayer(contentsOf: todayURL)
        player?.delegate = self
        if player?.play() == true { isPlaying = true }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { self.isRecording = false; self.hasRecording = flag }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlaying = false; self.player = nil }
    }
}
