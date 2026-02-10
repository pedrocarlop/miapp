# Architecture Map

## Current structure
- `miapp` (App target): composition root and host-only integrations (haptics/sound, navigation shell).
- `WordSearchWidgetExtension`: widget timeline + intents, reusing `Core` and `DesignSystem`.
- `Packages/AppModules/Sources/DesignSystem`: tokens + reusable SwiftUI components.
- `Packages/AppModules/Sources/Core`: domain entities/use-cases, repository protocols, data/persistence, shared utilities.
- `Packages/AppModules/Sources/FeatureDailyPuzzle`: puzzle presentation/viewmodels and feature DI.
- `Packages/AppModules/Sources/FeatureHistory`: history/streak presentation/viewmodels and feature DI.
- `Packages/AppModules/Sources/FeatureSettings`: settings presentation/viewmodels and feature DI.

## Layer responsibilities
- UI (`Views`): render + event forwarding only; no persistence or heavy business logic.
- Presentation (`ViewModels` / UI-state): UI orchestration, derived state, and refresh coordination.
- Domain (`Core/Domain`): deterministic puzzle rules, validation, scoring, streak/hint policy.
- Data (`Core/Data`): repositories, DTO mapping, migrations, key-value persistence.

## Dependency direction
- `App` -> `Feature*`, `Core`, `DesignSystem`
- `Feature*` -> `Core`, `DesignSystem`
- `Widget` -> `Core`, `DesignSystem`
- `Core` -> Foundation and internal modules only
- `DesignSystem` -> SwiftUI only

## Key optimization updates included
- Precomputed challenge-card state in `FeatureDailyPuzzle` ViewModel (`DailyPuzzleChallengeCardState`) to avoid render-time recomputation.
- Shared `ProgressRecordResolver` in `Core` for consistent progress-record selection policy across data/presentation.
- Shared `LoupeState`/`LoupeConfiguration` in `Core` to remove duplicated loupe implementations.
- Shared memoized path-finding in `Core` (`WordPathFinderService`) used by app and widget.
- Structured logging wrapper (`AppLogger`) for persistence/migration diagnostics.
- Renamed the core word-search grid model from `Grid` to `PuzzleGrid` to avoid SwiftUI name collisions and improve domain clarity.
