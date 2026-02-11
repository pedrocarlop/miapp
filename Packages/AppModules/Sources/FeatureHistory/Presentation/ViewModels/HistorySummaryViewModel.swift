/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureHistory/Presentation/ViewModels/HistorySummaryViewModel.swift
 - Rol principal: Coordina estado de pantalla: recibe acciones, llama casos de uso y actualiza modelo de UI.
 - Flujo simplificado: Entrada: accion de la vista o carga inicial. | Proceso: valida, invoca servicios/use cases, transforma resultados. | Salida: nuevo estado de UI.
 - Tipos clave en este archivo: HistorySummaryViewModel
 - Funciones clave en este archivo: refresh
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
public final class HistorySummaryViewModel {
    public private(set) var model = HistorySummaryUIModel(completedCount: 0, currentStreak: 0)

    private let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
    }

    public func refresh(now: Date = Date()) {
        let completed = core.getCompletedOffsetsUseCase.execute().count
        let today = core.todayDayKey(now: now)
        let streak = core.updateStreakUseCase.refresh(todayKey: today)
        model = HistorySummaryUIModel(completedCount: completed, currentStreak: streak.current)
    }
}
