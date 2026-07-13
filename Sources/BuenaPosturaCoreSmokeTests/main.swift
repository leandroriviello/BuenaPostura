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

print("BuenaPosturaCore smoke tests passed")
