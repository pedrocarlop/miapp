# Module Dependencies

## Allowed Dependencies
- `App` -> `DesignSystem`, `Core`, `FeatureDailyPuzzle`, `FeatureHistory`, `FeatureSettings`
- `FeatureDailyPuzzle` -> `Core`, `DesignSystem`
- `FeatureHistory` -> `Core`, `DesignSystem`
- `FeatureSettings` -> `Core`, `DesignSystem`
- `WordSearchWidgetExtension` -> `Core`, `DesignSystem`
- `Core` -> Foundation-only domain, Foundation-based data
- `DesignSystem` -> SwiftUI only

## Forbidden Dependencies
- `DesignSystem` must not import `Core` or feature modules.
- `Core` must not import any feature module.
- Domain code must not import SwiftUI/UIKit/Combine/WidgetKit/UserDefaults directly from presentation layers.
