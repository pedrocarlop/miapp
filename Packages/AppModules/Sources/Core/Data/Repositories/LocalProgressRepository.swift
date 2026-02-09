import Foundation

public final class LocalProgressRepository: ProgressRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public static func key(for dayOffset: Int, gridSize: Int) -> String {
        AppProgressRecordKey.make(dayOffset: dayOffset, gridSize: gridSize)
    }

    public func loadRecords() -> [String: AppProgressRecord] {
        guard let data = store.data(forKey: WordSearchConfig.appProgressKey) else {
            return [:]
        }

        guard let decoded = try? JSONDecoder().decode([String: AppProgressRecordDTO].self, from: data) else {
            return [:]
        }

        return decoded.mapValues(StateMappers.toDomain)
    }

    public func loadRecord(dayKey: DayKey, preferredGridSize: Int) -> AppProgressRecord? {
        let records = loadRecords()
        let preferredKey = Self.key(for: dayKey.offset, gridSize: preferredGridSize)
        if let preferred = records[preferredKey] {
            return preferred
        }

        let candidates = records.values.filter { $0.dayOffset == dayKey.offset }

        return candidates.max { lhs, rhs in
            let lhsActivity = max(lhs.startedAt ?? -1, lhs.endedAt ?? -1)
            let rhsActivity = max(rhs.startedAt ?? -1, rhs.endedAt ?? -1)
            if lhsActivity != rhsActivity {
                return lhsActivity < rhsActivity
            }

            let lhsEnded = lhs.endedAt ?? -1
            let rhsEnded = rhs.endedAt ?? -1
            if lhsEnded != rhsEnded {
                return lhsEnded < rhsEnded
            }

            return lhs.gridSize < rhs.gridSize
        }
    }

    public func save(_ record: AppProgressRecord) {
        var records = loadRecords()
        records[Self.key(for: record.dayOffset, gridSize: record.gridSize)] = record
        persist(records)
    }

    public func reset(dayKey: DayKey, gridSize: Int) {
        var records = loadRecords()
        records.removeValue(forKey: Self.key(for: dayKey.offset, gridSize: gridSize))
        persist(records)
    }

    public func markCompleted(dayKey: DayKey) {
        var current = completedDayOffsets()
        current.insert(dayKey.offset)
        store.set(Array(current).sorted(), forKey: WordSearchConfig.completedOffsetsKey)
    }

    public func completedDayOffsets() -> Set<Int> {
        let values = store.array(forKey: WordSearchConfig.completedOffsetsKey) as? [Int] ?? []
        return Set(values)
    }

    private func persist(_ records: [String: AppProgressRecord]) {
        let dtoMap = records.mapValues(StateMappers.toDTO)
        guard let data = try? JSONEncoder().encode(dtoMap) else {
            return
        }
        store.set(data, forKey: WordSearchConfig.appProgressKey)
    }
}
