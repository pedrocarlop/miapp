/*
 BEGINNER NOTES (AUTO):
 - Archivo: miapp/AppContainer.swift
 - Rol principal: Gestiona inyeccion de dependencias: crea objetos y conecta capas.
 - Flujo simplificado: Entrada: configuracion/base objects. | Proceso: instanciar y cablear dependencias. | Salida: contenedor listo para usar.
 - Tipos clave en este archivo: AppContainer
 - Funciones clave en este archivo: (sin funciones directas visibles; revisa propiedades/constantes/extensiones)
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
import Combine
import Core
import FeatureDailyPuzzle
import FeatureHistory
import FeatureSettings

@MainActor
final class AppContainer: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    let core: CoreContainer
    let dailyPuzzle: DailyPuzzleContainer
    let history: HistoryContainer
    let settings: SettingsContainer

    init(core: CoreContainer) {
        self.core = core
        self.dailyPuzzle = DailyPuzzleContainer(core: core)
        self.history = HistoryContainer(core: core)
        self.settings = SettingsContainer(core: core)
    }

    static let live: AppContainer = {
        AppContainer(core: CoreBootstrap.shared)
    }()
}
