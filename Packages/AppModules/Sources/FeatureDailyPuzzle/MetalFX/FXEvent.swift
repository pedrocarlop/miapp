/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/MetalFX/FXEvent.swift
 - Rol principal: Renderiza o configura efectos visuales GPU (Metal) para feedback del juego.
 - Flujo simplificado: Entrada: eventos visuales + tiempo/frame. | Proceso: preparar uniforms y lanzar draw calls. | Salida: efecto renderizado sobre el tablero.
 - Tipos clave en este archivo: FXEventType,FXEvent
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

import CoreGraphics

public enum FXEventType: Sendable {
    case wordSuccessWave
    case wordSuccessScanline
    case wordSuccessParticles
    case wordCompletionConfetti
    case wordSuccessTrail
    case wordSuccessPulseBloom
    case wordSuccessScreenBloom
    case wordSuccessInkReveal
    case wordSuccessLiquidGlass
    case wordSuccessDissolve
    case wordSuccessMagnetSnapTrail
    case wordSuccessCellVolume
    case wordSuccessLaserHeat
}

public struct FXEvent: Sendable {
    public let type: FXEventType
    public let timestamp: Double
    public let gridBounds: CGRect
    public let pathPoints: [CGPoint]
    public let cellCenters: [CGPoint]
    public let wordRects: [CGRect]?
    public let intensity: Float

    public init(
        type: FXEventType,
        timestamp: Double,
        gridBounds: CGRect,
        pathPoints: [CGPoint],
        cellCenters: [CGPoint],
        wordRects: [CGRect]?,
        intensity: Float
    ) {
        self.type = type
        self.timestamp = timestamp
        self.gridBounds = gridBounds
        self.pathPoints = pathPoints
        self.cellCenters = cellCenters
        self.wordRects = wordRects
        self.intensity = intensity
    }
}
