# Architecture

## Overview
The codebase is organized into a modular clean architecture split across a local Swift package at `Packages/AppModules`.

- `DesignSystem`: semantic tokens, themes, and reusable SwiftUI components.
- `Core`: domain entities/use cases, repository protocols, data implementations, mappers, persistence, and DI.
- `FeatureDailyPuzzle`: daily puzzle presentation/view model layer.
- `FeatureHistory`: history and progress summary presentation/view model layer.
- `FeatureSettings`: settings presentation/view model layer.
- `App` target (`miapp`): composition root and app entrypoints.
- `WordSearchWidgetExtension`: widget UI and intents that consume `Core` shared logic.
- Shared board renderer (`SharedWordSearchBoardView`) lives in `DesignSystem` and is consumed by both app and widget.

## Layering
- Presentation depends on `Core` and `DesignSystem` only.
- Domain in `Core` has no SwiftUI/UIKit/WidgetKit dependencies.
- Data implementations live in `Core/Data` and satisfy domain repository protocols.
- Dependency injection is centralized in `CoreContainer` and app-level containers.
- `CoreBootstrap` provides a single shared `CoreContainer` instance for app composition and host compatibility adapters during migration.
- Presentation adapters in app/widget call Core use cases and container APIs, not repository implementations.
- `CoreContainer` hides repository/store internals from external modules to enforce boundary rules.
- Daily puzzle selection/session transitions are orchestrated by `FeatureDailyPuzzle` (`DailyPuzzleGameSessionViewModel`), reducing game-rule logic inside SwiftUI views.

## Composition Root
- `miappApp` initializes `AppContainer.live`.
- `AppContainer` composes:
  - `CoreContainer` (single shared runtime instance)
  - `DailyPuzzleContainer`
  - `HistoryContainer`
  - `SettingsContainer`
- `WordSearchWidgetExtension` composes its own process-local `CoreContainer` and consumes the same domain/data implementations from `Core`.

## Persistence and Compatibility
All existing App Group and key names are preserved to maintain backward compatibility with persisted data:
- Suite: `group.com.pedrocarrasco.miapp`
- Shared state keys, progress keys, streak keys, settings keys, and legacy migration keys remain unchanged.

## Testing Strategy
- Domain tests cover selection validation, score/streak/hint rules, and deterministic puzzle generation.
- Data tests cover DTO roundtrip, repositories, settings clamping, and legacy migration.
