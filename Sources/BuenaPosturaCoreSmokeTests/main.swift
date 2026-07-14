import Foundation
import BuenaPosturaCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("Smoke test failed: \(message)\n", stderr)
        exit(1)
    }
}

let good = PostureSample(pitch: 0, roll: 0, yaw: 0)
let bad = PostureSample(pitch: 0.7, roll: 0.2, yaw: 0)
let detector = PostureDetector(goodPosture: good, badPosture: bad, settings: DetectionSettings())

let goodReading = detector.reading(for: good)
let badReading = detector.reading(for: bad)

expect(goodReading.score < badReading.score, "good posture should score lower than bad posture")
expect(goodReading.state == .good, "good sample should be classified as good")
expect(badReading.state == .slouching, "bad sample should be classified as slouching")

let wraparoundA = PostureSample(pitch: 0, roll: 0, yaw: .pi - 0.01)
let wraparoundB = PostureSample(pitch: 0, roll: 0, yaw: -.pi + 0.01)
expect(wraparoundA.distance(to: wraparoundB) < 0.03, "angles should remain close across the pi boundary")

var smoother = PostureSmoother()
_ = smoother.smooth(sample: good, score: 0, factor: 0.18)
let smoothed = smoother.smooth(sample: bad, score: 1, factor: 0.18)
expect(abs(smoothed.1 - 0.18) < 0.0001, "smoothing should use the configured factor")

print("BuenaPosturaCore smoke tests passed")
