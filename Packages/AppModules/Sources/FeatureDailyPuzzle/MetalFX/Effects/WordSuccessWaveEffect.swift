import CoreGraphics // Tipos geometricos (CGPoint/CGRect) para posiciones y limites.
import Metal // API de GPU usada para renderizar el efecto.

// Efecto de onda circular que aparece al acertar una palabra.
// Se dibuja en dos pasadas (base + glow) para ganar profundidad visual.
final class WordSuccessWaveEffect: FXEffect {
    // Parametros globales del efecto.
    private enum Constants {
        // Tiempo total de vida de cada onda.
        static let duration: Float = 0.66
        // Grosor del anillo base (pasada alpha).
        static let ringWidth: Float = 14
        // Grosor del anillo de glow (pasada aditiva).
        static let additiveRingWidth: Float = 9
        // Tope de ondas activas para proteger rendimiento.
        static let maxConcurrentWaves = 24
    }

    // Estado de UNA onda que esta animandose.
    private struct WaveState {
        // Momento de creacion de esta onda.
        let startTime: Float
        // Centro desde donde se expande el anillo.
        let center: CGPoint
        // Radio maximo al que puede llegar.
        let maxRadius: Float
        // Intensidad visual normalizada [0, 1].
        let intensity: Float
        // Inicio y final del trazo de la palabra (para shader/debug).
        let pathStart: CGPoint
        let pathEnd: CGPoint
        // Limites del tablero para recorte.
        let bounds: CGRect
    }

    // Pipelines de Metal para cada pasada de render.
    private let alphaPipeline: MTLRenderPipelineState
    private let additivePipeline: MTLRenderPipelineState
    // Buffer de uniforms compartido entre CPU y GPU.
    private let uniformBuffer: MTLBuffer
    // Tamano alineado de cada bloque de uniforms.
    private let uniformStride: Int

    // Reloj interno del efecto.
    private var elapsedTime: Float = 0
    // Ondas actualmente activas.
    private var waves: [WaveState] = []
    // Activa overlays de depuracion en shader.
    private var debugEnabled = false

    // El efecto se considera activo mientras haya ondas vivas.
    var isActive: Bool {
        !waves.isEmpty
    }

    // Inicializacion de recursos de GPU y memoria de uniforms.
    init?(
        device: MTLDevice,
        alphaPipeline: MTLRenderPipelineState,
        additivePipeline: MTLRenderPipelineState
    ) {
        self.alphaPipeline = alphaPipeline
        self.additivePipeline = additivePipeline

        // Requisito de Metal: offsets de buffer alineados a 256 bytes.
        uniformStride = MemoryLayout<FXOverlayUniforms>.stride.alignedTo256
        // Reservamos espacio para el maximo de ondas simultaneas.
        let bufferLength = uniformStride * Constants.maxConcurrentWaves
        guard let uniformBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared) else {
            return nil
        }
        self.uniformBuffer = uniformBuffer
    }

    // API para habilitar/deshabilitar modo debug.
    func setDebugEnabled(_ enabled: Bool) {
        debugEnabled = enabled
    }

    // Procesa eventos del juego y crea una onda cuando corresponde.
    func handle(event: FXEvent) {
        // Solo aceptamos eventos de tipo wave.
        guard event.type == .wordSuccessWave else { return }
        // Validacion basica de limites de tablero.
        guard event.gridBounds.width > 0, event.gridBounds.height > 0 else { return }

        // Si existe centro por celdas lo usamos; si no, usamos pathPoints.
        let wavePoints = event.cellCenters.isEmpty ? event.pathPoints : event.cellCenters
        // Centro de respaldo: media de puntos o ultimo punto del path.
        guard let fallbackCenter = MetalFXCoordinateMapper.average(wavePoints) ?? event.pathPoints.last else {
            return
        }

        // Clamp de intensidad al rango [0, 1].
        let intensity = min(max(event.intensity, 0), 1)
        // Punto inicial/final del trazo con fallback robusto.
        let pathStart = event.pathPoints.first ?? fallbackCenter
        let pathEnd = event.pathPoints.last ?? fallbackCenter
        // Elegimos el final como centro para enfatizar donde termino el gesto.
        let center = pathEnd
        // Calculamos radio maximo adaptado al tamano/forma de la seleccion.
        let maxRadius = localizedMaxRadius(points: wavePoints, gridBounds: event.gridBounds)

        // Guardamos la onda en estado interno.
        waves.append(
            WaveState(
                startTime: elapsedTime,
                center: center,
                maxRadius: maxRadius,
                intensity: intensity,
                pathStart: pathStart,
                pathEnd: pathEnd,
                bounds: event.gridBounds
            )
        )

        // Control de capacidad: descartamos las mas antiguas si hay exceso.
        if waves.count > Constants.maxConcurrentWaves {
            waves.removeFirst(waves.count - Constants.maxConcurrentWaves)
        }
    }

    // Avanza el reloj y limpia ondas expiradas.
    func update(dt: Float) {
        // Clamp para evitar grandes saltos por lag/freeze.
        let clampedDelta = max(0, min(dt, 0.1))
        elapsedTime += clampedDelta
        // Eliminamos ondas cuya vida supero el tiempo total.
        waves.removeAll { elapsedTime - $0.startTime >= Constants.duration }
    }

    // Render de todas las ondas activas.
    func draw(
        encoder: MTLRenderCommandEncoder,
        resolution: SIMD2<Float>,
        time: Float
    ) {
        // Nada que dibujar.
        guard !waves.isEmpty else { return }

        encoder.setRenderPipelineState(alphaPipeline)

        // Ventana segura de ondas activas.
        let activeWaves = waves.suffix(Constants.maxConcurrentWaves)
        for (index, wave) in activeWaves.enumerated() {
            // Edad de la onda.
            let age = max(0, elapsedTime - wave.startTime)
            // Progreso lineal [0, 1] segun su edad.
            let linearProgress = min(age / Constants.duration, 1)
            // Curva suavizada para expansion menos mecanica.
            let smoothProgress = smoothStep(0, 1, linearProgress)
            // Mezcla lineal + suavizada para equilibrar respuesta y suavidad.
            let progress = (0.18 * linearProgress) + (0.82 * smoothProgress)
            // Decaimiento de opacidad al final de la animacion.
            let alphaDecay = 1 - smoothStep(0.72, 1, linearProgress)
            // Decaimiento algo distinto para la capa aditiva (glow).
            let additiveDecay = 1 - smoothStep(0.64, 1, linearProgress)

            // Uniforms de la pasada base (anillo principal).
            let baseUniforms = FXOverlayUniforms(
                resolution: resolution,
                center: SIMD2<Float>(Float(wave.center.x), Float(wave.center.y)),
                progress: progress,
                maxRadius: wave.maxRadius,
                ringWidth: Constants.ringWidth,
                alpha: max(0, alphaDecay) * (0.2 + 0.2 * wave.intensity),
                intensity: wave.intensity,
                debugEnabled: debugEnabled ? 1 : 0,
                pathStart: SIMD2<Float>(Float(wave.pathStart.x), Float(wave.pathStart.y)),
                pathEnd: SIMD2<Float>(Float(wave.pathEnd.x), Float(wave.pathEnd.y)),
                bounds: SIMD4<Float>(
                    Float(wave.bounds.minX),
                    Float(wave.bounds.minY),
                    Float(wave.bounds.width),
                    Float(wave.bounds.height)
                ),
                time: time,
                effectKind: FXEffectKind.wave,
                params: SIMD2<Float>(0.0, 0.0)
            )

            // Uniforms de la pasada aditiva (halo de brillo).
            let additiveUniforms = FXOverlayUniforms(
                resolution: resolution,
                center: baseUniforms.center,
                progress: min(1.0, progress + 0.025),
                maxRadius: wave.maxRadius,
                ringWidth: Constants.additiveRingWidth,
                alpha: max(0, additiveDecay) * (0.17 + 0.14 * wave.intensity),
                intensity: min(1.2 as Float, wave.intensity + 0.12),
                debugEnabled: baseUniforms.debugEnabled,
                pathStart: baseUniforms.pathStart,
                pathEnd: baseUniforms.pathEnd,
                bounds: baseUniforms.bounds,
                time: time,
                effectKind: FXEffectKind.wave,
                params: SIMD2<Float>(1.0, 0.0)
            )

            // Offset del bloque de uniforms para este indice.
            let offset = index * uniformStride
            let pointer = uniformBuffer.contents().advanced(by: offset)
            var mutableBaseUniforms = baseUniforms
            // Copia bytes CPU -> GPU para que el fragment shader los use.
            withUnsafeBytes(of: &mutableBaseUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            // Pasada 1: dibuja anillo base con alpha blending.
            encoder.setRenderPipelineState(alphaPipeline)
            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            // 2 triangulos (6 vertices) para cubrir un quad.
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

            var mutableAdditiveUniforms = additiveUniforms
            withUnsafeBytes(of: &mutableAdditiveUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            // Pasada 2: suma brillo con blending aditivo.
            encoder.setRenderPipelineState(additivePipeline)
            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }

    // Reinicio completo del estado interno del efecto.
    func reset() {
        elapsedTime = 0
        waves.removeAll(keepingCapacity: false)
    }

    // Interpolacion suave estandar (ease-in/out).
    private func smoothStep(_ edge0: Float, _ edge1: Float, _ value: Float) -> Float {
        // Proteccion ante rango degenerado para evitar division por cero.
        guard edge0 != edge1 else {
            return value >= edge0 ? 1 : 0
        }
        // Normalizacion y recorte de entrada.
        let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        // Curva cubica de smoothStep.
        return t * t * (3 - 2 * t)
    }

    // Calcula un radio maximo local, ajustado a la seleccion y al tablero.
    private func localizedMaxRadius(points: [CGPoint], gridBounds: CGRect) -> Float {
        // Dimension menor del grid para limitar expansion.
        let minGridSide = Float(min(gridBounds.width, gridBounds.height))
        // Radio maximo permitido dentro del tablero.
        let maxGridRadius = min(
            Float(hypot(gridBounds.width, gridBounds.height)) * 0.42,
            minGridSide * 0.5
        )

        // Si no hay puntos, devolvemos un valor razonable de fallback.
        guard !points.isEmpty else {
            return max(52, min(minGridSide * 0.34, maxGridRadius))
        }

        // Bounding box de la seleccion para medir su extension.
        var minX = Float.greatestFiniteMagnitude
        var maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude
        var maxY = -Float.greatestFiniteMagnitude

        for point in points {
            let x = Float(point.x)
            let y = Float(point.y)
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }

        // Tamano horizontal/vertical minimo 1 para evitar degeneraciones.
        let spanX = max(maxX - minX, 1)
        let spanY = max(maxY - minY, 1)
        // Diagonal de la seleccion y radio local derivado.
        let selectionDiagonal = hypot(spanX, spanY)
        let localRadius = selectionDiagonal * 0.58 + 34

        // Clamp final entre minimo visible y limite del tablero.
        return max(52, min(localRadius, maxGridRadius))
    }
}
