import Foundation

public struct PostureSample: Codable, Equatable {
    public var pitch: Double
    public var roll: Double
    public var yaw: Double

    public init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }

    public func distance(to other: PostureSample) -> Double {
        let pitchDelta = pitch - other.pitch
        let rollDelta = roll - other.roll
        let yawDelta = yaw - other.yaw
        return sqrt((pitchDelta * pitchDelta) + (rollDelta * rollDelta) + (yawDelta * yawDelta))
    }
}

public struct DetectionSettings: Codable, Equatable {
    public var sensitivity: Double
    public var alertAfterSeconds: Double
    public var cooldownSeconds: Double
    public var lookingDownToleranceDegrees: Double
    public var smoothing: Double

    public init(
        sensitivity: Double = 0.62,
        alertAfterSeconds: Double = 25,
        cooldownSeconds: Double = 300,
        lookingDownToleranceDegrees: Double = 18,
        smoothing: Double = 0.18
    ) {
        self.sensitivity = sensitivity
        self.alertAfterSeconds = alertAfterSeconds
        self.cooldownSeconds = cooldownSeconds
        self.lookingDownToleranceDegrees = lookingDownToleranceDegrees
        self.smoothing = smoothing
    }
}

public enum PostureState: String {
    case waitingForHeadphones = "Esperando AirPods"
    case monitoring = "Monitoreando"
    case good = "Buena postura"
    case drifting = "Te estas inclinando"
    case slouching = "Postura baja"
    case paused = "Pausado"
    case unsupported = "No compatible"
    case unauthorized = "Permiso de movimiento"
}

public struct PostureReading: Equatable {
    public var sample: PostureSample
    public var score: Double
    public var state: PostureState

    public init(sample: PostureSample, score: Double, state: PostureState) {
        self.sample = sample
        self.score = score
        self.state = state
    }
}

public struct PostureDetector {
    public var goodPosture: PostureSample?
    public var badPosture: PostureSample?
    public var settings: DetectionSettings

    public init(
        goodPosture: PostureSample? = nil,
        badPosture: PostureSample? = nil,
        settings: DetectionSettings = DetectionSettings()
    ) {
        self.goodPosture = goodPosture
        self.badPosture = badPosture
        self.settings = settings
    }

    public func reading(for sample: PostureSample) -> PostureReading {
        guard let goodPosture, let badPosture else {
            return PostureReading(sample: sample, score: 0, state: .monitoring)
        }

        let goodDistance = weightedDistance(sample, goodPosture)
        let badDistance = weightedDistance(sample, badPosture)
        let totalDistance = max(goodDistance + badDistance, 0.0001)
        let closenessToBad = 1 - (badDistance / totalDistance)

        let pitchDriftDegrees = abs((sample.pitch - goodPosture.pitch) * 180 / .pi)
        let rollDriftDegrees = abs((sample.roll - goodPosture.roll) * 180 / .pi)
        let lookingDownPenalty = max(0, pitchDriftDegrees - settings.lookingDownToleranceDegrees) / 45
        let sideTiltPenalty = max(0, rollDriftDegrees - 16) / 60
        let score = min(
            1,
            max(
                0,
                (closenessToBad * settings.sensitivity)
                    + (lookingDownPenalty * 0.32)
                    + (sideTiltPenalty * 0.14)
            )
        )

        let state: PostureState
        if score >= 0.72 {
            state = .slouching
        } else if score >= 0.45 {
            state = .drifting
        } else {
            state = .good
        }

        return PostureReading(sample: sample, score: score, state: state)
    }

    private func weightedDistance(_ lhs: PostureSample, _ rhs: PostureSample) -> Double {
        let pitchDelta = (lhs.pitch - rhs.pitch) * 1.25
        let rollDelta = (lhs.roll - rhs.roll) * 0.9
        let yawDelta = (lhs.yaw - rhs.yaw) * 0.35
        return sqrt((pitchDelta * pitchDelta) + (rollDelta * rollDelta) + (yawDelta * yawDelta))
    }
}

public struct PostureSmoother {
    private var lastSample: PostureSample?
    private var lastScore: Double?

    public init() {}

    public mutating func smooth(sample: PostureSample, score: Double, factor: Double) -> (PostureSample, Double) {
        let alpha = min(0.75, max(0.05, factor))

        guard let lastSample, let lastScore else {
            self.lastSample = sample
            self.lastScore = score
            return (sample, score)
        }

        let smoothedSample = PostureSample(
            pitch: lastSample.pitch + ((sample.pitch - lastSample.pitch) * alpha),
            roll: lastSample.roll + ((sample.roll - lastSample.roll) * alpha),
            yaw: lastSample.yaw + ((sample.yaw - lastSample.yaw) * alpha)
        )
        let smoothedScore = lastScore + ((score - lastScore) * alpha)

        self.lastSample = smoothedSample
        self.lastScore = smoothedScore
        return (smoothedSample, smoothedScore)
    }

    public mutating func reset() {
        lastSample = nil
        lastScore = nil
    }
}
