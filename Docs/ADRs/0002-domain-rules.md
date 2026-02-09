# ADR 0002: Domain Purity and Repository Boundaries

## Status
Accepted

## Decision
All business rules are expressed in `Core/Domain` using Foundation-only types and use cases. Data access is abstracted through repository protocols defined in domain and implemented in `Core/Data`.

## Rationale
- Deterministic tests for game rules.
- Clear separation of orchestration (presentation) from business behavior (domain).
- Reduced duplication across app and widget.
