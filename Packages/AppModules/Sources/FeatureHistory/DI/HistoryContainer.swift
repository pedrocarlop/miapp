/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureHistory/DI/HistoryContainer.swift
 - Rol principal: Gestiona inyeccion de dependencias: crea objetos y conecta capas.
 - Flujo simplificado: Entrada: configuracion/base objects. | Proceso: instanciar y cablear dependencias. | Salida: contenedor listo para usar.
 - Tipos clave en este archivo: HistoryContainer
 - Funciones clave en este archivo: makeViewModel
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

public struct HistoryContainer {
    public let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
    }

    @MainActor
    public func makeViewModel() -> HistorySummaryViewModel {
        HistorySummaryViewModel(core: core)
    }
}
