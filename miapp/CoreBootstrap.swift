import Foundation
import WidgetKit
import Core

enum CoreBootstrap {
    static let shared: CoreContainer = CoreContainer.live {
        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConfig.widgetKind)
    }
}
