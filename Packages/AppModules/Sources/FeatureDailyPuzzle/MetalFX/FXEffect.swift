/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/MetalFX/FXEffect.swift
 - Rol principal: Renderiza o configura efectos visuales GPU (Metal) para feedback del juego.
 - Flujo simplificado: Entrada: eventos visuales + tiempo/frame. | Proceso: preparar uniforms y lanzar draw calls. | Salida: efecto renderizado sobre el tablero.
 - Tipos clave en este archivo: FXEffect
 - Funciones clave en este archivo: handle,update draw,reset
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

import Metal

public protocol FXEffect: AnyObject {
    var isActive: Bool { get }

    func handle(event: FXEvent)
    func update(dt: Float)
    func draw(
        encoder: MTLRenderCommandEncoder,
        resolution: SIMD2<Float>,
        time: Float
    )
    func reset()
}
