import CoreGraphics
import Metal

final class WordSuccessScanlineEffect: FXEffect {
    private enum Constants {
        static let duration: Float = 0.35
        static let maxConcurrentLines = 24
    }

    private struct ScanlineState {
        let startTime: Float
        let start: CGPoint
        let end: CGPoint
        let center: CGPoint
        let length: Float
        let intensity: Float
        let bounds: CGRect
    }

    private let alphaPipeline: MTLRenderPipelineState
    private let uniformBuffer: MTLBuffer
    private let uniformStride: Int

    private var elapsedTime: Float = 0
    private var lines: [ScanlineState] = []
    private var debugEnabled = false

    var isActive: Bool {
        !lines.isEmpty
    }

    init?(device: MTLDevice, alphaPipeline: MTLRenderPipelineState) {
        self.alphaPipeline = alphaPipeline

        uniformStride = MemoryLayout<FXOverlayUniforms>.stride.alignedTo256
        let bufferLength = uniformStride * Constants.maxConcurrentLines
        guard let uniformBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared) else {
            return nil
        }
        self.uniformBuffer = uniformBuffer
    }

    func setDebugEnabled(_ enabled: Bool) {
        debugEnabled = enabled
    }

    func handle(event: FXEvent) {
        guard event.type == .wordSuccessScanline else { return }
        guard event.gridBounds.width > 0, event.gridBounds.height > 0 else { return }
        guard let start = event.pathPoints.first, let end = event.pathPoints.last else { return }

        let length = Float(hypot(end.x - start.x, end.y - start.y))
        guard length > 0.1 else { return }

        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let intensity = min(max(event.intensity, 0), 1)

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

        if lines.count > Constants.maxConcurrentLines {
            lines.removeFirst(lines.count - Constants.maxConcurrentLines)
        }
    }

    func update(dt: Float) {
        let clampedDelta = max(0, min(dt, 0.1))
        elapsedTime += clampedDelta
        lines.removeAll { elapsedTime - $0.startTime >= Constants.duration }
    }

    func draw(
        encoder: MTLRenderCommandEncoder,
        resolution: SIMD2<Float>,
        time: Float
    ) {
        guard !lines.isEmpty else { return }

        encoder.setRenderPipelineState(alphaPipeline)

        let activeLines = lines.suffix(Constants.maxConcurrentLines)
        for (index, line) in activeLines.enumerated() {
            let age = max(0, elapsedTime - line.startTime)
            let linearProgress = min(age / Constants.duration, 1)
            let progress = easeOutCubic(linearProgress)

            let bandHalfWidth: Float = 20 + (line.intensity * 12)
            let coreThickness: Float = 1.4 + (line.intensity * 1.2)
            let fade = smoothStep(0, 0.06, linearProgress) * (1 - smoothStep(0.9, 1, linearProgress))

            let uniforms = FXOverlayUniforms(
                resolution: resolution,
                center: SIMD2<Float>(Float(line.center.x), Float(line.center.y)),
                progress: progress,
                maxRadius: line.length,
                ringWidth: 0,
                alpha: max(0, fade) * (0.48 + 0.3 * line.intensity),
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
                params: SIMD2<Float>(bandHalfWidth, coreThickness)
            )

            let offset = index * uniformStride
            let pointer = uniformBuffer.contents().advanced(by: offset)
            var mutableUniforms = uniforms
            withUnsafeBytes(of: &mutableUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }

    func reset() {
        elapsedTime = 0
        lines.removeAll(keepingCapacity: false)
    }

    private func easeOutCubic(_ value: Float) -> Float {
        let t = min(max(value, 0), 1)
        let oneMinusT = 1 - t
        return 1 - oneMinusT * oneMinusT * oneMinusT
    }

    private func smoothStep(_ edge0: Float, _ edge1: Float, _ value: Float) -> Float {
        guard edge0 != edge1 else {
            return value >= edge0 ? 1 : 0
        }
        let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }
}
