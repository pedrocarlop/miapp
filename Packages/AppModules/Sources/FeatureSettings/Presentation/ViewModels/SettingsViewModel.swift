/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureSettings/Presentation/ViewModels/SettingsViewModel.swift
 - Rol principal: Coordina estado de pantalla: recibe acciones, llama casos de uso y actualiza modelo de UI.
 - Flujo simplificado: Entrada: accion de la vista o carga inicial. | Proceso: valida, invoca servicios/use cases, transforma resultados. | Salida: nuevo estado de UI.
 - Tipos clave en este archivo: SettingsViewModel
 - Funciones clave en este archivo: refresh,setGridSize makeSheetValues,save save
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
import Observation
import Core

@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var model: SettingsUIModel

    private let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
        self.model = Self.makeModel(from: core.loadSettingsUseCase.execute())
    }

    public func refresh() {
        model = Self.makeModel(from: core.loadSettingsUseCase.execute())
    }

    public func setGridSize(_ value: Int) {
        model.gridSize = min(max(value, WordSearchConfig.minGridSize), WordSearchConfig.maxGridSize)
    }

    public func makeSheetValues() -> SettingsSheetValues {
        SettingsSheetValues(
            gridSize: model.gridSize,
            appearanceMode: model.appearanceMode,
            wordHintMode: model.wordHintMode,
            appLanguage: model.appLanguage,
            dailyRefreshMinutes: model.dailyRefreshMinutes,
            enableCelebrations: model.enableCelebrations,
            enableHaptics: model.enableHaptics,
            enableSound: model.enableSound,
            celebrationIntensity: model.celebrationIntensity
        )
    }

    @discardableResult
    public func save(values: SettingsSheetValues) -> SettingsUIModel {
        var settings = core.loadSettingsUseCase.execute()
        settings.gridSize = PuzzleFactory.clampGridSize(values.gridSize)
        settings.appearanceMode = values.appearanceMode
        settings.wordHintMode = values.wordHintMode
        settings.appLanguage = AppLanguage.resolved()
        settings.dailyRefreshMinutes = DailyRefreshClock.clampMinutes(values.dailyRefreshMinutes)
        settings.enableCelebrations = values.enableCelebrations
        settings.enableHaptics = values.enableHaptics
        settings.enableSound = values.enableSound
        settings.celebrationIntensity = values.celebrationIntensity
        core.saveSettingsUseCase.execute(settings)

        let normalized = Self.makeModel(from: settings)
        model = normalized
        return normalized
    }

    public func save() {
        _ = save(values: makeSheetValues())
    }

    private static func makeModel(from settings: AppSettings) -> SettingsUIModel {
        SettingsUIModel(
            gridSize: settings.gridSize,
            appearanceMode: settings.appearanceMode,
            wordHintMode: settings.wordHintMode,
            appLanguage: settings.appLanguage,
            dailyRefreshMinutes: settings.dailyRefreshMinutes,
            enableCelebrations: settings.enableCelebrations,
            enableHaptics: settings.enableHaptics,
            enableSound: settings.enableSound,
            celebrationIntensity: settings.celebrationIntensity
        )
    }
}
