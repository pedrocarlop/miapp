/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/DI/CoreContainer.swift
 - Rol principal: Gestiona inyeccion de dependencias: crea objetos y conecta capas.
 - Flujo simplificado: Entrada: configuracion/base objects. | Proceso: instanciar y cablear dependencias. | Salida: contenedor listo para usar.
 - Tipos clave en este archivo: CoreContainer
 - Funciones clave en este archivo: todayDayKey,puzzleDate installationDate,dayOffset date,puzzle
 - Como leerlo sin experiencia:
   1) Busca primero los tipos clave para entender 'quien vive aqui'.
   2) Revisa propiedades (let/var): indican que datos mantiene cada tipo.
   3) Sigue funciones publicas: son la puerta de entrada para otras capas.
   4) Luego mira funciones privadas: implementan detalles internos paso a paso.
   5) Si ves guard/if/switch, son decisiones que controlan el flujo.
 - Recordatorio rapido de sintaxis:
   - let = valor fijo; var = valor que puede cambiar.
   - guard = valida pronto; si falla, sale de la funcion.
   - return = devuelve un resultado y cierra esa funcion.
*/

import Foundation

public final class CoreContainer {
    private let store: KeyValueStore

    private let puzzleRepository: PuzzleRepository
    private let progressRepository: ProgressRepository
    private let streakRepository: StreakRepository
    private let settingsRepository: SettingsRepository
    private let hintRepository: HintRepository
    private let sharedPuzzleRepository: SharedPuzzleRepository

    public let getDailyPuzzleUseCase: GetDailyPuzzleUseCase
    public let startDailySessionUseCase: StartDailySessionUseCase
    public let validateSelectionUseCase: ValidateSelectionUseCase
    public let markWordFoundUseCase: MarkWordFoundUseCase
    public let computeScoreUseCase: ComputeScoreUseCase
    public let updateStreakUseCase: UpdateStreakUseCase
    public let saveProgressUseCase: SaveProgressUseCase
    public let loadProgressUseCase: LoadProgressUseCase
    public let loadSettingsUseCase: LoadSettingsUseCase
    public let saveSettingsUseCase: SaveSettingsUseCase
    public let getCompletedOffsetsUseCase: GetCompletedOffsetsUseCase
    public let loadAllProgressRecordsUseCase: LoadAllProgressRecordsUseCase
    public let saveProgressRecordUseCase: SaveProgressRecordUseCase
    public let resetProgressRecordUseCase: ResetProgressRecordUseCase
    public let markCompletedDayUseCase: MarkCompletedDayUseCase
    public let loadStreakUseCase: LoadStreakUseCase
    public let loadHintStateUseCase: LoadHintStateUseCase
    public let spendHintUseCase: SpendHintUseCase
    public let rewardCompletionHintUseCase: RewardCompletionHintUseCase
    public let wasHintRewardedUseCase: WasHintRewardedUseCase
    public let getSharedPuzzleStateUseCase: GetSharedPuzzleStateUseCase
    public let saveSharedPuzzleStateUseCase: SaveSharedPuzzleStateUseCase
    public let updateSharedProgressUseCase: UpdateSharedProgressUseCase
    public let clearSharedProgressUseCase: ClearSharedProgressUseCase
    public let currentRotationBoundaryUseCase: CurrentRotationBoundaryUseCase
    public let applySharedTapUseCase: ApplySharedTapUseCase
    public let toggleSharedHelpUseCase: ToggleSharedHelpUseCase
    public let dismissSharedHintUseCase: DismissSharedHintUseCase
    public let resolveSharedFeedbackUseCase: ResolveSharedFeedbackUseCase

    public init(
        store: KeyValueStore,
        onSharedStateMutation: (() -> Void)? = nil
    ) {
        self.store = store

        let puzzleRepository = LocalPuzzleRepository(store: store)
        let progressRepository = LocalProgressRepository(store: store)
        let streakRepository = LocalStreakRepository(store: store)
        let settingsRepository = LocalSettingsRepository(store: store)
        let hintRepository = LocalHintRepository(store: store)
        let sharedPuzzleRepository = LocalSharedPuzzleRepository(store: store, onMutation: onSharedStateMutation)

        self.puzzleRepository = puzzleRepository
        self.progressRepository = progressRepository
        self.streakRepository = streakRepository
        self.settingsRepository = settingsRepository
        self.hintRepository = hintRepository
        self.sharedPuzzleRepository = sharedPuzzleRepository

        self.getDailyPuzzleUseCase = GetDailyPuzzleUseCase(puzzleRepository: puzzleRepository)
        self.startDailySessionUseCase = StartDailySessionUseCase(progressRepository: progressRepository)
        self.validateSelectionUseCase = ValidateSelectionUseCase()
        self.markWordFoundUseCase = MarkWordFoundUseCase()
        self.computeScoreUseCase = ComputeScoreUseCase()
        self.updateStreakUseCase = UpdateStreakUseCase(streakRepository: streakRepository)
        self.saveProgressUseCase = SaveProgressUseCase(progressRepository: progressRepository)
        self.loadProgressUseCase = LoadProgressUseCase(progressRepository: progressRepository)
        self.loadSettingsUseCase = LoadSettingsUseCase(settingsRepository: settingsRepository)
        self.saveSettingsUseCase = SaveSettingsUseCase(settingsRepository: settingsRepository)
        self.getCompletedOffsetsUseCase = GetCompletedOffsetsUseCase(progressRepository: progressRepository)
        self.loadAllProgressRecordsUseCase = LoadAllProgressRecordsUseCase(progressRepository: progressRepository)
        self.saveProgressRecordUseCase = SaveProgressRecordUseCase(progressRepository: progressRepository)
        self.resetProgressRecordUseCase = ResetProgressRecordUseCase(progressRepository: progressRepository)
        self.markCompletedDayUseCase = MarkCompletedDayUseCase(progressRepository: progressRepository)
        self.loadStreakUseCase = LoadStreakUseCase(streakRepository: streakRepository)
        self.loadHintStateUseCase = LoadHintStateUseCase(hintRepository: hintRepository)
        self.spendHintUseCase = SpendHintUseCase(hintRepository: hintRepository)
        self.rewardCompletionHintUseCase = RewardCompletionHintUseCase(hintRepository: hintRepository)
        self.wasHintRewardedUseCase = WasHintRewardedUseCase(hintRepository: hintRepository)
        self.getSharedPuzzleStateUseCase = GetSharedPuzzleStateUseCase(sharedRepository: sharedPuzzleRepository)
        self.saveSharedPuzzleStateUseCase = SaveSharedPuzzleStateUseCase(sharedRepository: sharedPuzzleRepository)
        self.updateSharedProgressUseCase = UpdateSharedProgressUseCase(sharedRepository: sharedPuzzleRepository)
        self.clearSharedProgressUseCase = ClearSharedProgressUseCase(sharedRepository: sharedPuzzleRepository)
        self.currentRotationBoundaryUseCase = CurrentRotationBoundaryUseCase(sharedRepository: sharedPuzzleRepository)
        self.applySharedTapUseCase = ApplySharedTapUseCase(sharedRepository: sharedPuzzleRepository)
        self.toggleSharedHelpUseCase = ToggleSharedHelpUseCase(sharedRepository: sharedPuzzleRepository)
        self.dismissSharedHintUseCase = DismissSharedHintUseCase(sharedRepository: sharedPuzzleRepository)
        self.resolveSharedFeedbackUseCase = ResolveSharedFeedbackUseCase(sharedRepository: sharedPuzzleRepository)
    }

    public static func live(onSharedStateMutation: (() -> Void)? = nil) -> CoreContainer {
        let store: KeyValueStore = UserDefaultsStore(suiteName: WordSearchConfig.suiteName) ?? InMemoryKeyValueStore()
        return CoreContainer(store: store, onSharedStateMutation: onSharedStateMutation)
    }

    public func todayDayKey(now: Date = Date()) -> DayKey {
        let installDate = installationDate()
        let boundary = currentRotationBoundaryUseCase.execute(now: now)
        return dayOffset(from: installDate, to: boundary)
    }

    public func puzzleDate(for dayKey: DayKey, now: Date = Date()) -> Date {
        let installDate = installationDate()
        return date(from: installDate, dayKey: dayKey)
    }

    public func installationDate() -> Date {
        puzzleRepository.installationDate()
    }

    public func dayOffset(from start: Date, to target: Date) -> DayKey {
        puzzleRepository.dayOffset(from: start, to: target)
    }

    public func date(from start: Date, dayKey: DayKey) -> Date {
        puzzleRepository.date(from: start, dayKey: dayKey)
    }

    public func puzzle(dayKey: DayKey, gridSize: Int) -> Puzzle {
        getDailyPuzzleUseCase.execute(dayKey: dayKey, gridSize: gridSize)
    }

    public func normalizedPuzzleIndex(_ index: Int) -> Int {
        puzzleRepository.normalizedPuzzleIndex(index)
    }

    public func requestPuzzleReset(now: Date = Date()) {
        store.set(now.timeIntervalSince1970, forKey: WordSearchConfig.resetRequestKey)
    }
}
