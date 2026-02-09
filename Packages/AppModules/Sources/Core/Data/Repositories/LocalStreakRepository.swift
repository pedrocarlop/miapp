import Foundation

public final class LocalStreakRepository: StreakRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func load() -> Streak {
        let current = store.integer(forKey: WordSearchConfig.streakCurrentKey)
        let last = store.object(forKey: WordSearchConfig.streakLastCompletedKey) as? Int ?? -1
        return Streak(current: current, lastCompletedOffset: last)
    }

    public func refresh(todayKey: DayKey) -> Streak {
        var state = load()
        if state.lastCompletedOffset >= 0 && state.lastCompletedOffset < todayKey.offset - 1 {
            state.current = 0
            persist(state)
        }
        return state
    }

    public func markCompleted(dayKey: DayKey, todayKey: DayKey) -> Streak {
        var state = load()
        guard dayKey.offset == todayKey.offset else {
            return state
        }
        guard state.lastCompletedOffset != todayKey.offset else {
            return state
        }

        if state.lastCompletedOffset == todayKey.offset - 1 {
            state.current += 1
        } else {
            state.current = 1
        }
        state.lastCompletedOffset = todayKey.offset
        persist(state)
        return state
    }

    private func persist(_ streak: Streak) {
        store.set(streak.current, forKey: WordSearchConfig.streakCurrentKey)
        store.set(streak.lastCompletedOffset, forKey: WordSearchConfig.streakLastCompletedKey)
    }
}
