import Foundation
import BuenaPosturaCore

final class SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> DetectionSettings {
        load(DetectionSettings.self, key: "settings") ?? DetectionSettings()
    }

    func saveSettings(_ settings: DetectionSettings) {
        save(settings, key: "settings")
    }

    func loadGoodPosture() -> PostureSample? {
        load(PostureSample.self, key: "goodPosture")
    }

    func saveGoodPosture(_ sample: PostureSample) {
        save(sample, key: "goodPosture")
    }

    func loadBadPosture() -> PostureSample? {
        load(PostureSample.self, key: "badPosture")
    }

    func saveBadPosture(_ sample: PostureSample) {
        save(sample, key: "badPosture")
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
