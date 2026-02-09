# ADR 0001: Modularization via Local Swift Package

## Status
Accepted

## Decision
Introduce a local SPM package (`Packages/AppModules`) with separate library targets for `DesignSystem`, `Core`, and feature modules.

## Rationale
- Enforces dependency boundaries.
- Enables incremental extraction from monolith.
- Makes domain/data code testable independently of app UI targets.
