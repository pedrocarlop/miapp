import simd

enum FXEffectKind {
    static let wave: Float = 0
    static let scanline: Float = 1
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
