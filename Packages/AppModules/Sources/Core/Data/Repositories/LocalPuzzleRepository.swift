import Foundation

public final class LocalPuzzleRepository: PuzzleRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func installationDate() -> Date {
        let calendar = Calendar.current
        let fallback = calendar.startOfDay(for: Date())

        if let stored = store.object(forKey: WordSearchConfig.installDateKey) as? Date {
            return calendar.startOfDay(for: stored)
        }

        store.set(fallback, forKey: WordSearchConfig.installDateKey)
        return fallback
    }

    public func dayOffset(from start: Date, to target: Date) -> DayKey {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let targetDay = calendar.startOfDay(for: target)
        let offset = max(calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0, 0)
        return DayKey(offset: offset)
    }

    public func date(from start: Date, dayKey: DayKey) -> Date {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: dayKey.offset, to: startDay) ?? startDay
    }

    public func puzzle(for dayKey: DayKey, gridSize: Int) -> Puzzle {
        PuzzleFactory.puzzle(for: dayKey, gridSize: gridSize)
    }

    public func normalizedPuzzleIndex(_ index: Int) -> Int {
        PuzzleFactory.normalizedPuzzleIndex(index)
    }
}
