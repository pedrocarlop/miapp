/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/MetalFX/FXShaderTypes.swift
 - Rol principal: Renderiza o configura efectos visuales GPU (Metal) para feedback del juego.
 - Flujo simplificado: Entrada: eventos visuales + tiempo/frame. | Proceso: preparar uniforms y lanzar draw calls. | Salida: efecto renderizado sobre el tablero.
 - Tipos clave en este archivo: FXEffectKind,FXOverlayUniforms
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

import simd

enum FXEffectKind {
    static let wave: Float = 0
    static let scanline: Float = 1
    static let particles: Float = 2
    static let confetti: Float = 3
}

struct FXOverlayUniforms {
    var resolution: SIMD2<Float>
    var center: SIMD2<Float>
    var progress: Float
    var maxRadius: Float
    var ringWidth: Float
    var alpha: Float
    var intensity: Float
    var debugEnabled: Float
    var pathStart: SIMD2<Float>
    var pathEnd: SIMD2<Float>
    var bounds: SIMD4<Float>
    var time: Float
    var effectKind: Float
    var params: SIMD2<Float>
}

extension Int {
    var alignedTo256: Int {
        (self + 0xFF) & ~0xFF
    }
}
