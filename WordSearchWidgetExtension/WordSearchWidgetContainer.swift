/*
 BEGINNER NOTES (AUTO):
 - Archivo: WordSearchWidgetExtension/WordSearchWidgetContainer.swift
 - Rol principal: Gestiona inyeccion de dependencias: crea objetos y conecta capas.
 - Flujo simplificado: Entrada: configuracion/base objects. | Proceso: instanciar y cablear dependencias. | Salida: contenedor listo para usar.
 - Tipos clave en este archivo: WordSearchWidgetContainer
 - Funciones clave en este archivo: settings,loadState applyTap,toggleHelp dismissHint
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
import Core

@available(iOS 17.0, *)
final class WordSearchWidgetContainer {
    static let shared = WordSearchWidgetContainer(core: CoreContainer.live())

    private let core: CoreContainer

    init(core: CoreContainer) {
        self.core = core
    }

    func settings() -> AppSettings {
        core.loadSettingsUseCase.execute()
    }

    func loadState(now: Date) -> SharedPuzzleState {
        let settings = self.settings()
        return core.getSharedPuzzleStateUseCase.execute(
            now: now,
            preferredGridSize: settings.gridSize
        )
    }

    @discardableResult
    func applyTap(row: Int, col: Int, now: Date) -> SharedPuzzleTapResult {
        let settings = self.settings()
        return core.applySharedTapUseCase.execute(
            row: row,
            col: col,
            now: now,
            preferredGridSize: settings.gridSize
        )
    }

    @discardableResult
    func toggleHelp(now: Date) -> SharedPuzzleState {
        let settings = self.settings()
        return core.toggleSharedHelpUseCase.execute(
            now: now,
            preferredGridSize: settings.gridSize
        )
    }

    @discardableResult
    func dismissHint(now: Date) -> SharedPuzzleState {
        let settings = self.settings()
        return core.dismissSharedHintUseCase.execute(
            now: now,
            preferredGridSize: settings.gridSize
        )
    }
}
