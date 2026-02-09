import Foundation

public final class LocalHintRepository: HintRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func state(todayKey: DayKey) -> HintState {
        var current = load()

        if current.lastRechargeOffset == -1 {
            current.available = min(WordSearchConfig.maxHints, max(current.available, WordSearchConfig.initialHints))
            current.lastRechargeOffset = todayKey.offset
        }

        if todayKey.offset > current.lastRechargeOffset {
            let delta = todayKey.offset - current.lastRechargeOffset
            current.available = min(WordSearchConfig.maxHints, current.available + delta * WordSearchConfig.dailyHintRecharge)
            current.lastRechargeOffset = todayKey.offset
        }

        persist(current)
        return current
    }

    public func spendHint(todayKey: DayKey) -> Bool {
        var current = state(todayKey: todayKey)
        guard current.available > 0 else { return false }
        current.available -= 1
        persist(current)
        return true
    }

    public func rewardCompletion(dayKey: DayKey, todayKey: DayKey) -> Bool {
        guard dayKey.offset == todayKey.offset else { return false }
        var current = state(todayKey: todayKey)
        guard current.lastRewardOffset != todayKey.offset else { return false }
        current.available = min(WordSearchConfig.maxHints, current.available + WordSearchConfig.completionHintReward)
        current.lastRewardOffset = todayKey.offset
        persist(current)
        return true
    }

    public func wasRewarded(todayKey: DayKey) -> Bool {
        load().lastRewardOffset == todayKey.offset
    }

    private func load() -> HintState {
        let available = max(0, store.object(forKey: WordSearchConfig.hintAvailableKey) as? Int ?? 0)
        let recharge = store.object(forKey: WordSearchConfig.hintRechargeKey) as? Int ?? -1
        let reward = store.object(forKey: WordSearchConfig.hintRewardKey) as? Int ?? -1

        return HintState(
            available: available,
            lastRechargeOffset: recharge,
            lastRewardOffset: reward
        )
    }

    private func persist(_ state: HintState) {
        let available = min(WordSearchConfig.maxHints, max(0, state.available))
        store.set(available, forKey: WordSearchConfig.hintAvailableKey)
        store.set(state.lastRechargeOffset, forKey: WordSearchConfig.hintRechargeKey)
        store.set(state.lastRewardOffset, forKey: WordSearchConfig.hintRewardKey)
    }
}
