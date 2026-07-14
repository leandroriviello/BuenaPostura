import CoreMotion
import Foundation
import BuenaPosturaCore
import UserNotifications

@MainActor
final class PostureMonitor: NSObject, ObservableObject {
    @Published private(set) var currentSample = PostureSample(pitch: 0, roll: 0, yaw: 0)
    @Published private(set) var score: Double = 0
    @Published private(set) var state: PostureState = .waitingForHeadphones
    @Published private(set) var isRunning = false
    @Published private(set) var isConnected = false
    @Published private(set) var hasCurrentSample = false
    @Published private(set) var motionPermission = CMHeadphoneMotionManager.authorizationStatus()
    @Published var showsAdvancedSettings = false
    @Published var settings: DetectionSettings {
        didSet {
            detector.settings = settings
            store.saveSettings(settings)
        }
    }

    private let motionManager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()
    private let store = SettingsStore()
    private let notificationsAvailable = Bundle.main.bundleURL.pathExtension == "app"
    private var detector: PostureDetector
    private var smoother = PostureSmoother()
    private var badPostureStartedAt: Date?
    private var lastAlertAt: Date?
    private var snoozedUntil: Date?

    override init() {
        let settings = store.loadSettings()
        self.settings = settings
        self.detector = PostureDetector(
            goodPosture: store.loadGoodPosture(),
            badPosture: store.loadBadPosture(),
            settings: settings
        )
        super.init()
        queue.name = "BuenaPostura.headphone-motion"
        motionManager.delegate = self
        requestNotificationPermission()
    }

    var hasGoodPosture: Bool {
        detector.goodPosture != nil
    }

    var hasBadPosture: Bool {
        detector.badPosture != nil
    }

    var canMonitor: Bool {
        motionManager.isDeviceMotionAvailable
    }

    func start() {
        beginMonitoring(clearsSnooze: true)
    }

    private func beginMonitoring(clearsSnooze: Bool) {
        if clearsSnooze {
            snoozedUntil = nil
        }
        motionPermission = CMHeadphoneMotionManager.authorizationStatus()
        if motionPermission == .denied || motionPermission == .restricted {
            isRunning = false
            state = .unauthorized
            return
        }

        isRunning = true
        guard motionManager.isDeviceMotionAvailable else {
            state = .waitingForHeadphones
            return
        }

        state = .monitoring
        smoother.reset()
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            let attitude = motion.attitude
            let sample = PostureSample(
                pitch: attitude.pitch,
                roll: attitude.roll,
                yaw: attitude.yaw
            )

            Task { @MainActor in
                self.handle(sample)
            }
        }
    }

    func stop() {
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
        badPostureStartedAt = nil
        smoother.reset()
        state = .paused
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func captureGoodPosture() {
        guard hasCurrentSample else { return }
        detector.goodPosture = currentSample
        store.saveGoodPosture(currentSample)
    }

    func captureBadPosture() {
        guard hasCurrentSample else { return }
        detector.badPosture = currentSample
        store.saveBadPosture(currentSample)
    }

    func snooze(minutes: Double = 10) {
        snoozedUntil = Date().addingTimeInterval(minutes * 60)
        badPostureStartedAt = nil
        state = .paused
    }

    private func handle(_ sample: PostureSample) {
        currentSample = sample
        hasCurrentSample = true

        if let snoozedUntil, snoozedUntil > Date() {
            score = 0
            badPostureStartedAt = nil
            state = .paused
            return
        }

        let rawReading = detector.reading(for: sample)
        let smoothed = smoother.smooth(
            sample: sample,
            score: rawReading.score,
            factor: settings.smoothing
        )
        score = smoothed.1
        state = state(for: score, fallback: rawReading.state)

        guard state == .slouching else {
            badPostureStartedAt = nil
            return
        }

        if badPostureStartedAt == nil {
            badPostureStartedAt = Date()
            return
        }

        guard let badPostureStartedAt else { return }
        let badDuration = Date().timeIntervalSince(badPostureStartedAt)
        let cooldownElapsed = lastAlertAt.map { Date().timeIntervalSince($0) >= settings.cooldownSeconds } ?? true

        if badDuration >= settings.alertAfterSeconds && cooldownElapsed {
            lastAlertAt = Date()
            sendPostureAlert()
        }
    }

    private func requestNotificationPermission() {
        guard notificationsAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendPostureAlert() {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = "BuenaPostura"
        content.body = "Tu cabeza se inclinó durante un rato. Respira, sube el pecho y vuelve."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "posture-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func state(for score: Double, fallback: PostureState) -> PostureState {
        if fallback == .monitoring { return fallback }
        if score >= 0.72 { return .slouching }
        if score >= 0.45 { return .drifting }
        return .good
    }
}

extension PostureMonitor: CMHeadphoneMotionManagerDelegate {
    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            isConnected = true
            if isRunning && !motionManager.isDeviceMotionActive {
                beginMonitoring(clearsSnooze: false)
            }
        }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            isConnected = false
            state = .waitingForHeadphones
        }
    }
}
