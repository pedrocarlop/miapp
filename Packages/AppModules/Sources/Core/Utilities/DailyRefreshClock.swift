import Foundation

public enum DailyRefreshClock {
    public static func clampMinutes(_ value: Int) -> Int {
        min(max(value, 0), WordSearchConfig.maxMinutesFromMidnight)
    }

    public static func date(for minutesFromMidnight: Int, reference: Date) -> Date {
        let clamped = clampMinutes(minutesFromMidnight)
        let hour = clamped / 60
        let minute = clamped % 60
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: reference) ?? reference
    }

    public static func currentRotationBoundary(now: Date, minutesFromMidnight: Int) -> Date {
        let todayBoundary = date(for: minutesFromMidnight, reference: now)
        if now >= todayBoundary {
            return todayBoundary
        }
        return Calendar.current.date(byAdding: .day, value: -1, to: todayBoundary) ?? todayBoundary
    }

    public static func nextDailyRefreshDate(after now: Date, minutesFromMidnight: Int) -> Date {
        let todayBoundary = date(for: minutesFromMidnight, reference: now)
        if now < todayBoundary {
            return todayBoundary
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: todayBoundary) ?? now.addingTimeInterval(86_400)
    }

    public static func rotationSteps(from previousBoundary: Date, to currentBoundary: Date) -> Int {
        let calendar = Calendar.current
        var steps = 0
        var marker = previousBoundary

        while marker < currentBoundary {
            guard let next = calendar.date(byAdding: .day, value: 1, to: marker) else { break }
            marker = next
            steps += 1
            if steps > 3660 {
                break
            }
        }

        return steps
    }
}
