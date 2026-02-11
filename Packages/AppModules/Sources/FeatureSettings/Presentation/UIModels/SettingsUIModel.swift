/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureSettings/Presentation/UIModels/SettingsUIModel.swift
 - Rol principal: Soporte general de arquitectura: tipos, configuracion o pegamento entre modulos.
 - Flujo simplificado: Entrada: contexto de modulo. | Proceso: ejecutar responsabilidad local del archivo. | Salida: tipo/valor usado por otras piezas.
 - Tipos clave en este archivo: SettingsUIModel
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
import Core

public struct SettingsUIModel: Equatable, Sendable {
    public var gridSize: Int
    public var appearanceMode: AppearanceMode
    public var wordHintMode: WordHintMode
    public var appLanguage: AppLanguage
    public var dailyRefreshMinutes: Int
    public var enableCelebrations: Bool
    public var enableHaptics: Bool
    public var enableSound: Bool
    public var celebrationIntensity: CelebrationIntensity

    public init(
        gridSize: Int,
        appearanceMode: AppearanceMode,
        wordHintMode: WordHintMode,
        appLanguage: AppLanguage,
        dailyRefreshMinutes: Int,
        enableCelebrations: Bool,
        enableHaptics: Bool,
        enableSound: Bool,
        celebrationIntensity: CelebrationIntensity
    ) {
        self.gridSize = gridSize
        self.appearanceMode = appearanceMode
        self.wordHintMode = wordHintMode
        self.appLanguage = appLanguage
        self.dailyRefreshMinutes = dailyRefreshMinutes
        self.enableCelebrations = enableCelebrations
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
        self.celebrationIntensity = celebrationIntensity
    }
}
