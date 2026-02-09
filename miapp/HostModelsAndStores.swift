import Foundation
import UIKit
import AudioToolbox

enum HostHaptics {
    static func wordSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.68)
    }

    static func completionSuccess() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        heavy.impactOccurred(intensity: 0.95)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.085) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.prepare()
            light.impactOccurred(intensity: 0.55)
        }

        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            notification.notificationOccurred(.success)
        }
    }
}

enum HostSoundEffect {
    case word
    case completion

    var systemSoundId: SystemSoundID {
        switch self {
        case .word:
            return 1104
        case .completion:
            return 1113
        }
    }
}

enum HostSoundPlayer {
    static func play(_ effect: HostSoundEffect) {
        AudioServicesPlaySystemSound(effect.systemSoundId)
    }
}

enum HostDateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    static func monthDay(for date: Date) -> String {
        formatter.string(from: date)
    }
}
