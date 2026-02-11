/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/MetalFX/MetalFXManager.swift
 - Rol principal: Renderiza o configura efectos visuales GPU (Metal) para feedback del juego.
 - Flujo simplificado: Entrada: eventos visuales + tiempo/frame. | Proceso: preparar uniforms y lanzar draw calls. | Salida: efecto renderizado sobre el tablero.
 - Tipos clave en este archivo: FXConfig,MetalFXManager
 - Funciones clave en este archivo: isEnabled,play setSuccessFXEnabled,attach detach
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
import SwiftUI

public struct FXConfig: Equatable, Sendable {
    public var enableSuccessFX: Bool
    public var enableWordSuccessWave: Bool
    public var enableWordSuccessScanline: Bool
    public var enableWordSuccessParticles: Bool
    public var enableWordSuccessTrail: Bool
    public var enableWordSuccessPulseBloom: Bool
    public var enableWordSuccessScreenBloom: Bool
    public var enableWordSuccessInkReveal: Bool
    public var enableWordSuccessLiquidGlass: Bool
    public var enableWordSuccessDissolve: Bool
    public var enableWordSuccessMagnetSnapTrail: Bool
    public var enableWordSuccessCellVolume: Bool
    public var enableWordSuccessLaserHeat: Bool
    public var debugEnabled: Bool

    public init(
        enableSuccessFX: Bool = true,
        enableWordSuccessWave: Bool = true,
        enableWordSuccessScanline: Bool = true,
        enableWordSuccessParticles: Bool = true,
        enableWordSuccessTrail: Bool = true,
        enableWordSuccessPulseBloom: Bool = true,
        enableWordSuccessScreenBloom: Bool = true,
        enableWordSuccessInkReveal: Bool = true,
        enableWordSuccessLiquidGlass: Bool = true,
        enableWordSuccessDissolve: Bool = true,
        enableWordSuccessMagnetSnapTrail: Bool = true,
        enableWordSuccessCellVolume: Bool = true,
        enableWordSuccessLaserHeat: Bool = true,
        debugEnabled: Bool = false
    ) {
        self.enableSuccessFX = enableSuccessFX
        self.enableWordSuccessWave = enableWordSuccessWave
        self.enableWordSuccessScanline = enableWordSuccessScanline
        self.enableWordSuccessParticles = enableWordSuccessParticles
        self.enableWordSuccessTrail = enableWordSuccessTrail
        self.enableWordSuccessPulseBloom = enableWordSuccessPulseBloom
        self.enableWordSuccessScreenBloom = enableWordSuccessScreenBloom
        self.enableWordSuccessInkReveal = enableWordSuccessInkReveal
        self.enableWordSuccessLiquidGlass = enableWordSuccessLiquidGlass
        self.enableWordSuccessDissolve = enableWordSuccessDissolve
        self.enableWordSuccessMagnetSnapTrail = enableWordSuccessMagnetSnapTrail
        self.enableWordSuccessCellVolume = enableWordSuccessCellVolume
        self.enableWordSuccessLaserHeat = enableWordSuccessLaserHeat
        self.debugEnabled = debugEnabled
    }

    public func isEnabled(for type: FXEventType) -> Bool {
        switch type {
        case .wordSuccessWave:
            return enableWordSuccessWave
        case .wordSuccessScanline:
            return enableWordSuccessScanline
        case .wordSuccessParticles:
            return enableWordSuccessParticles
        case .wordSuccessTrail:
            return enableWordSuccessTrail
        case .wordSuccessPulseBloom:
            return enableWordSuccessPulseBloom
        case .wordSuccessScreenBloom:
            return enableWordSuccessScreenBloom
        case .wordSuccessInkReveal:
            return enableWordSuccessInkReveal
        case .wordSuccessLiquidGlass:
            return enableWordSuccessLiquidGlass
        case .wordSuccessDissolve:
            return enableWordSuccessDissolve
        case .wordSuccessMagnetSnapTrail:
            return enableWordSuccessMagnetSnapTrail
        case .wordSuccessCellVolume:
            return enableWordSuccessCellVolume
        case .wordSuccessLaserHeat:
            return enableWordSuccessLaserHeat
        }
    }
}

@MainActor
public final class MetalFXManager: ObservableObject {
    @Published public var config: FXConfig {
        didSet {
            renderer?.updateConfig(config)
        }
    }

    private weak var renderer: MetalFXRenderer?
    private var bufferedEvents: [FXEvent] = []

    public init(config: FXConfig = .init()) {
        self.config = config
    }

    public func play(_ event: FXEvent) {
        guard config.enableSuccessFX else { return }
        guard config.isEnabled(for: event.type) else { return }

        if let renderer {
            renderer.enqueue(event: event)
            return
        }

        bufferedEvents.append(event)
    }

    public func setSuccessFXEnabled(_ enabled: Bool) {
        guard config.enableSuccessFX != enabled else { return }
        config.enableSuccessFX = enabled
    }

    func attach(renderer: MetalFXRenderer) {
        self.renderer = renderer
        renderer.updateConfig(config)

        guard !bufferedEvents.isEmpty else { return }
        let events = bufferedEvents
        bufferedEvents.removeAll(keepingCapacity: true)
        events.forEach { renderer.enqueue(event: $0) }
    }

    func detach(renderer: MetalFXRenderer) {
        guard self.renderer === renderer else { return }
        self.renderer = nil
    }
}
