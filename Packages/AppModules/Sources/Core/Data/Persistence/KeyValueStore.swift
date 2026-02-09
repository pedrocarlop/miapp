import Foundation

public protocol KeyValueStore: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func object(forKey defaultName: String) -> Any?
    func array(forKey defaultName: String) -> [Any]?
    func string(forKey defaultName: String) -> String?
    func integer(forKey defaultName: String) -> Int
    func double(forKey defaultName: String) -> Double
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

public final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    public init?(suiteName: String = WordSearchConfig.suiteName) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }
        self.defaults = defaults
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func data(forKey defaultName: String) -> Data? {
        defaults.data(forKey: defaultName)
    }

    public func object(forKey defaultName: String) -> Any? {
        defaults.object(forKey: defaultName)
    }

    public func array(forKey defaultName: String) -> [Any]? {
        defaults.array(forKey: defaultName)
    }

    public func string(forKey defaultName: String) -> String? {
        defaults.string(forKey: defaultName)
    }

    public func integer(forKey defaultName: String) -> Int {
        defaults.integer(forKey: defaultName)
    }

    public func double(forKey defaultName: String) -> Double {
        defaults.double(forKey: defaultName)
    }

    public func set(_ value: Any?, forKey defaultName: String) {
        defaults.set(value, forKey: defaultName)
    }

    public func removeObject(forKey defaultName: String) {
        defaults.removeObject(forKey: defaultName)
    }
}

public final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Any] = [:]

    public init() {}

    public func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    public func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    public func array(forKey defaultName: String) -> [Any]? {
        storage[defaultName] as? [Any]
    }

    public func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    public func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    public func double(forKey defaultName: String) -> Double {
        storage[defaultName] as? Double ?? 0
    }

    public func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    public func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}
