import Foundation

public enum ProgressRecordResolver {
    public static func resolve(
        dayKey: DayKey,
        preferredGridSize: Int,
        records: [String: AppProgressRecord]
    ) -> AppProgressRecord? {
        resolve(
            dayOffset: dayKey.offset,
            preferredGridSize: preferredGridSize,
            records: records
        )
    }

    public static func resolve(
        dayOffset: Int,
        preferredGridSize: Int,
        records: [String: AppProgressRecord]
    ) -> AppProgressRecord? {
        assert(preferredGridSize > 0, "Preferred grid size must be positive.")
        let preferredKey = AppProgressRecordKey.make(
            dayOffset: dayOffset,
            gridSize: preferredGridSize
        )
        if let preferred = records[preferredKey] {
            return preferred
        }

        let candidates = records.values.filter { $0.dayOffset == dayOffset }
        return candidates.max(by: isBetter(lhs:rhs:))
    }

    private static func isBetter(lhs: AppProgressRecord, rhs: AppProgressRecord) -> Bool {
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
