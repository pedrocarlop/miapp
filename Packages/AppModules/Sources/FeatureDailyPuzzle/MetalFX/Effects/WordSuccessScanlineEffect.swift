import CoreGraphics // Tipos geometricos: CGPoint, CGRect, etc.
import Metal // API de renderizado en GPU para iOS/macOS

// Efecto visual que dibuja una linea de barrido ("scanline") cuando aciertas una palabra.
// Implementa FXEffect para integrarse en el pipeline de efectos.
final class WordSuccessScanlineEffect: FXEffect {
    // Constantes del comportamiento del efecto (tiempos y limites de seguridad).
    private enum Constants {
        // Duracion total de la vida de una linea (en segundos).
        static let duration: Float = 0.48
        // Fase inicial: la cabeza aparece, pero aun no avanza.
        static let headBuildDuration: Float = 0.08
        // Tiempo principal de recorrido a lo largo de la palabra.
        static let travelDuration: Float = 0.31
        // Fase final para desvanecerse con suavidad.
        static let falloffDuration: Float = 0.09
        // Tope de lineas activas para proteger memoria/rendimiento.
        static let maxConcurrentLines = 24
    }

    // Estado de UNA linea activa en pantalla.
    private struct ScanlineState {
        // Momento en el que se creo la linea (reloj interno del efecto).
        let startTime: Float
        // Inicio y final de la palabra en coordenadas de pantalla.
        let start: CGPoint
        let end: CGPoint
        // Punto medio del segmento, util para centrar calculos en shader.
        let center: CGPoint
        // Longitud total del segmento (distancia entre start y end).
        let length: Float
        // Intensidad del brillo (normalizada entre 0 y 1).
        let intensity: Float
        // Limites del tablero para recortar el efecto.
        let bounds: CGRect
    }

    // Pipelines de Metal:
    // - alphaPipeline: pasada base con transparencia.
    // - additivePipeline: pasada adicional para glow/brillo aditivo.
    private let alphaPipeline: MTLRenderPipelineState
    private let additivePipeline: MTLRenderPipelineState
    // Buffer compartido CPU/GPU donde escribimos uniforms por linea.
    private let uniformBuffer: MTLBuffer
    // Tamano alineado de cada bloque de uniforms (Metal pide 256 bytes).
    private let uniformStride: Int

    // Reloj interno que avanza en cada frame.
    private var elapsedTime: Float = 0
    // Lista de lineas activas que se estan animando.
    private var lines: [ScanlineState] = []
    // Marca para activar ayudas visuales de depuracion en shader.
    private var debugEnabled = false

    // El efecto esta activo cuando queda al menos una linea viva.
    var isActive: Bool {
        !lines.isEmpty
    }

    // Inicializa dependencias de GPU y reserva memoria para uniforms.
    init?(
        device: MTLDevice,
        alphaPipeline: MTLRenderPipelineState,
        additivePipeline: MTLRenderPipelineState
    ) {
        self.alphaPipeline = alphaPipeline
        self.additivePipeline = additivePipeline

        // Cada bloque de uniforms debe ir alineado a 256 bytes.
        uniformStride = MemoryLayout<FXOverlayUniforms>.stride.alignedTo256
        // Reservamos espacio para el maximo de lineas concurrentes.
        let bufferLength = uniformStride * Constants.maxConcurrentLines
        // storageModeShared permite escribir desde CPU y leer desde GPU.
        guard let uniformBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared) else {
            return nil
        }
        self.uniformBuffer = uniformBuffer
    }

    // API publica para habilitar/deshabilitar modo debug del shader.
    func setDebugEnabled(_ enabled: Bool) {
        debugEnabled = enabled
    }

    // Recibe eventos de gameplay y crea lineas cuando toca.
    func handle(event: FXEvent) {
        // Solo reaccionamos a eventos del tipo scanline.
        guard event.type == .wordSuccessScanline else { return }
        // Validamos limites del grid para evitar divisiones/calculos invalidos.
        guard event.gridBounds.width > 0, event.gridBounds.height > 0 else { return }
        // Necesitamos al menos punto inicial y final del trazo.
        guard let start = event.pathPoints.first, let end = event.pathPoints.last else { return }

        // Distancia real del segmento usando Pitagoras (hypot).
        let length = Float(hypot(end.x - start.x, end.y - start.y))
        // Ignoramos segmentos demasiado pequenos (ruido/taps minimos).
        guard length > 0.1 else { return }

        // Punto medio del trazo.
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        // Clamp de intensidad al rango [0, 1].
        let intensity = min(max(event.intensity, 0), 1)

        // Registramos nueva linea activa en el estado interno.
        lines.append(
            ScanlineState(
                startTime: elapsedTime,
                start: start,
                end: end,
                center: center,
                length: length,
                intensity: intensity,
                bounds: event.gridBounds
            )
        )

        // Si superamos el limite, eliminamos las mas antiguas primero.
        if lines.count > Constants.maxConcurrentLines {
            lines.removeFirst(lines.count - Constants.maxConcurrentLines)
        }
    }

    // Se llama cada frame para avanzar el tiempo y limpiar expiradas.
    func update(dt: Float) {
        // Clamp del delta: evita saltos enormes si baja el framerate.
        let clampedDelta = max(0, min(dt, 0.1))
        elapsedTime += clampedDelta
        // Quitamos lineas cuya vida ya supero la duracion total.
        lines.removeAll { elapsedTime - $0.startTime >= Constants.duration }
    }

    // Dibuja todas las lineas activas.
    func draw(
        encoder: MTLRenderCommandEncoder,
        resolution: SIMD2<Float>,
        time: Float
    ) {
        // Salida rapida: no hay nada que pintar.
        guard !lines.isEmpty else { return }

        encoder.setRenderPipelineState(alphaPipeline)

        // Trabajamos con una ventana segura de lineas activas.
        let activeLines = lines.suffix(Constants.maxConcurrentLines)
        for (index, line) in activeLines.enumerated() {
            // Edad actual de la linea.
            let age = max(0, elapsedTime - line.startTime)
            // Progreso del barrido en [0, 1].
            let progress = sweepProgress(for: age)

            // Longitud visual de cola/trazo.
            let trailLength = min(max(30 + line.length * 0.18, 30), 94)
            // Grosor del nucleo brillante.
            let coreThickness: Float = 1.1 + (line.intensity * 0.95)
            // Aparicion suave al principio.
            let reveal = smoothStep(0, Constants.headBuildDuration, age)
            // Inicio del desvanecimiento final.
            let falloffStart = Constants.duration - Constants.falloffDuration
            // Desaparicion suave al final.
            let hide = 1 - smoothStep(falloffStart, Constants.duration, age)
            // Opacidad final combinando entrada/salida.
            let fade = reveal * hide

            // Uniforms para pasada base (alpha): define geometria y energia principal.
            let baseUniforms = FXOverlayUniforms(
                resolution: resolution,
                center: SIMD2<Float>(Float(line.center.x), Float(line.center.y)),
                progress: progress,
                maxRadius: line.length,
                ringWidth: 0,
                alpha: max(0, fade) * (0.38 + 0.27 * line.intensity),
                intensity: line.intensity,
                debugEnabled: debugEnabled ? 1 : 0,
                pathStart: SIMD2<Float>(Float(line.start.x), Float(line.start.y)),
                pathEnd: SIMD2<Float>(Float(line.end.x), Float(line.end.y)),
                bounds: SIMD4<Float>(
                    Float(line.bounds.minX),
                    Float(line.bounds.minY),
                    Float(line.bounds.width),
                    Float(line.bounds.height)
                ),
                time: time,
                effectKind: FXEffectKind.scanline,
                params: SIMD2<Float>(trailLength, coreThickness)
            )

            // Uniforms para pasada aditiva: anade glow con parametros ligeramente distintos.
            let additiveUniforms = FXOverlayUniforms(
                resolution: resolution,
                center: baseUniforms.center,
                progress: min(1.0, progress + 0.012),
                maxRadius: line.length,
                ringWidth: 0,
                alpha: max(0, fade) * (0.22 + 0.2 * line.intensity),
                intensity: min(1.25 as Float, line.intensity + 0.16),
                debugEnabled: baseUniforms.debugEnabled,
                pathStart: baseUniforms.pathStart,
                pathEnd: baseUniforms.pathEnd,
                bounds: baseUniforms.bounds,
                time: time,
                effectKind: FXEffectKind.scanline,
                params: SIMD2<Float>(trailLength * 0.55, max(0.8, coreThickness - 0.15))
            )

            // Offset dentro del buffer para este indice de linea.
            let offset = index * uniformStride
            let pointer = uniformBuffer.contents().advanced(by: offset)
            var mutableBaseUniforms = baseUniforms
            // Copiamos bytes CPU -> buffer compartido para que shader lea estos uniforms.
            withUnsafeBytes(of: &mutableBaseUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            // Pasada 1: composicion alpha (base).
            encoder.setRenderPipelineState(alphaPipeline)
            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            // Dibujamos 2 triangulos (6 vertices) que forman un rectangulo pantalla.
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

            var mutableAdditiveUniforms = additiveUniforms
            withUnsafeBytes(of: &mutableAdditiveUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            // Pasada 2: composicion aditiva para reforzar el brillo.
            encoder.setRenderPipelineState(additivePipeline)
            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }

    // Limpia todo el estado del efecto (por ejemplo, al reiniciar partida).
    func reset() {
        elapsedTime = 0
        lines.removeAll(keepingCapacity: false)
    }

    // Convierte edad -> progreso del barrido combinando curva lineal y suavizada.
    private func sweepProgress(for age: Float) -> Float {
        // Durante la fase de build inicial, la linea no avanza.
        if age <= Constants.headBuildDuration {
            return 0
        }

        let travelAge = age - Constants.headBuildDuration
        // Normalizamos tiempo de viaje al rango [0, 1].
        let normalized = min(max(travelAge / Constants.travelDuration, 0), 1)
        // Curva smoothStep para evitar arranques/frenadas bruscas.
        let smoothNormalized = smoothStep(0, 1, normalized)
        // Mezcla leve lineal + mayor peso suavizado para movimiento natural.
        return (0.12 * normalized) + (0.88 * smoothNormalized)
    }

    // Interpolacion suave estandar: acelera y desacelera de forma gradual.
    private func smoothStep(_ edge0: Float, _ edge1: Float, _ value: Float) -> Float {
        // Evita division por cero cuando edge0 y edge1 coinciden.
        guard edge0 != edge1 else {
            return value >= edge0 ? 1 : 0
        }
        // Clamp y normalizacion de entrada al rango [0, 1].
        let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        // Polinomio cubico clasico de smoothStep.
        return t * t * (3 - 2 * t)
    }
}
