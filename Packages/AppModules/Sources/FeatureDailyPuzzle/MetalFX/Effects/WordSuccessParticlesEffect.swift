import CoreGraphics
import Metal

final class WordSuccessParticlesEffect: FXEffect {
    private enum Constants {
        static let maxConcurrentBursts = 24
    }

    private enum BurstKind {
        case word
        case completion

        var duration: Float {
            switch self {
            case .word:
                return 0.46
            case .completion:
                return 0.62
            }
        }

        var effectKind: Float {
            switch self {
            case .word:
                return FXEffectKind.particles
            case .completion:
                return FXEffectKind.confetti
            }
        }

        var baseParticleCount: Float {
            switch self {
            case .word:
                return 18
            case .completion:
                return 34
            }
        }

        var speedScale: Float {
            switch self {
            case .word:
                return 0.78
            case .completion:
                return 0.92
            }
        }

        var baseAlpha: Float {
            switch self {
            case .word:
                return 0.18
            case .completion:
                return 0.22
            }
        }

        var additiveAlpha: Float {
            switch self {
            case .word:
                return 0.14
            case .completion:
                return 0.16
            }
        }
    }

    private struct BurstState {
        let startTime: Float
        let center: CGPoint
        let maxRadius: Float
        let intensity: Float
        let pathStart: CGPoint
        let pathEnd: CGPoint
        let bounds: CGRect
        let kind: BurstKind
    }

    private let alphaPipeline: MTLRenderPipelineState
    private let additivePipeline: MTLRenderPipelineState
    private let uniformBuffer: MTLBuffer
    private let uniformStride: Int

    private var elapsedTime: Float = 0
    private var bursts: [BurstState] = []
    private var debugEnabled = false

    var isActive: Bool {
        !bursts.isEmpty
    }

    init?(
        device: MTLDevice,
        alphaPipeline: MTLRenderPipelineState,
        additivePipeline: MTLRenderPipelineState
    ) {
        self.alphaPipeline = alphaPipeline
        self.additivePipeline = additivePipeline

        uniformStride = MemoryLayout<FXOverlayUniforms>.stride.alignedTo256
        let bufferLength = uniformStride * Constants.maxConcurrentBursts
        guard let uniformBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared) else {
            return nil
        }
        self.uniformBuffer = uniformBuffer
    }

    func setDebugEnabled(_ enabled: Bool) {
        debugEnabled = enabled
    }

    func handle(event: FXEvent) {
        let kind: BurstKind
        switch event.type {
        case .wordSuccessParticles:
            kind = .word
        case .wordCompletionConfetti:
            kind = .completion
        default:
            return
        }

        guard event.gridBounds.width > 0, event.gridBounds.height > 0 else { return }

        let sourcePoints = event.cellCenters.isEmpty ? event.pathPoints : event.cellCenters
        let boardCenter = CGPoint(x: event.gridBounds.midX, y: event.gridBounds.midY)
        let fallbackCenter = MetalFXCoordinateMapper.average(sourcePoints) ?? event.pathPoints.last ?? boardCenter
        let center = kind == .completion ? boardCenter : (event.pathPoints.last ?? fallbackCenter)
        let pathStart = event.pathPoints.first ?? center
        let pathEnd = event.pathPoints.last ?? center
        let maxRadius = kind == .completion
            ? completionRadius(in: event.gridBounds)
            : localizedBurstRadius(points: sourcePoints, in: event.gridBounds)
        let intensity = min(max(event.intensity, 0), 1)

        bursts.append(
            BurstState(
                startTime: elapsedTime,
                center: center,
                maxRadius: maxRadius,
                intensity: intensity,
                pathStart: pathStart,
                pathEnd: pathEnd,
                bounds: event.gridBounds,
                kind: kind
            )
        )

        if bursts.count > Constants.maxConcurrentBursts {
            bursts.removeFirst(bursts.count - Constants.maxConcurrentBursts)
        }
    }

    func update(dt: Float) {
        let clampedDelta = max(0, min(dt, 0.1))
        elapsedTime += clampedDelta
        bursts.removeAll { elapsedTime - $0.startTime >= $0.kind.duration }
    }

    func draw(
        encoder: MTLRenderCommandEncoder,
        resolution: SIMD2<Float>,
        time: Float
    ) {
        guard !bursts.isEmpty else { return }

        let activeBursts = bursts.suffix(Constants.maxConcurrentBursts)
        for (index, burst) in activeBursts.enumerated() {
            let age = max(0, elapsedTime - burst.startTime)
            let linearProgress = min(age / burst.kind.duration, 1)
            let progress = easeOutCubic(linearProgress)
            let fadeIn = smoothStep(0, 0.16, linearProgress)
            let fadeOutStart: Float = burst.kind == .word ? 0.72 : 0.8
            let fadeOut = 1 - smoothStep(fadeOutStart, 1, linearProgress)
            let visibility = max(0, fadeIn * fadeOut)
            guard visibility > 0 else { continue }

            let particleCount = burst.kind.baseParticleCount + burst.intensity * 10
            let speedScale = burst.kind.speedScale + burst.intensity * 0.24

            let baseUniforms = FXOverlayUniforms(
                resolution: resolution,
                center: SIMD2<Float>(Float(burst.center.x), Float(burst.center.y)),
                progress: progress,
                maxRadius: burst.maxRadius,
                ringWidth: 0,
                alpha: visibility * (burst.kind.baseAlpha + burst.intensity * 0.1),
                intensity: burst.intensity,
                debugEnabled: debugEnabled ? 1 : 0,
                pathStart: SIMD2<Float>(Float(burst.pathStart.x), Float(burst.pathStart.y)),
                pathEnd: SIMD2<Float>(Float(burst.pathEnd.x), Float(burst.pathEnd.y)),
                bounds: SIMD4<Float>(
                    Float(burst.bounds.minX),
                    Float(burst.bounds.minY),
                    Float(burst.bounds.width),
                    Float(burst.bounds.height)
                ),
                time: time,
                effectKind: burst.kind.effectKind,
                params: SIMD2<Float>(particleCount, speedScale)
            )

            let additiveUniforms = FXOverlayUniforms(
                resolution: baseUniforms.resolution,
                center: baseUniforms.center,
                progress: min(1, progress + 0.01),
                maxRadius: baseUniforms.maxRadius,
                ringWidth: 0,
                alpha: visibility * (burst.kind.additiveAlpha + burst.intensity * 0.08),
                intensity: min(1.25 as Float, burst.intensity + 0.16),
                debugEnabled: baseUniforms.debugEnabled,
                pathStart: baseUniforms.pathStart,
                pathEnd: baseUniforms.pathEnd,
                bounds: baseUniforms.bounds,
                time: time,
                effectKind: burst.kind.effectKind,
                params: SIMD2<Float>(particleCount * 1.06, speedScale * 1.08)
            )

            let offset = index * uniformStride
            let pointer = uniformBuffer.contents().advanced(by: offset)

            var mutableBaseUniforms = baseUniforms
            withUnsafeBytes(of: &mutableBaseUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            encoder.setRenderPipelineState(alphaPipeline)
            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

            var mutableAdditiveUniforms = additiveUniforms
            withUnsafeBytes(of: &mutableAdditiveUniforms) { bytes in
                guard let baseAddress = bytes.baseAddress else { return }
                pointer.copyMemory(from: baseAddress, byteCount: bytes.count)
            }

            encoder.setRenderPipelineState(additivePipeline)
            encoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }

    func reset() {
        elapsedTime = 0
        bursts.removeAll(keepingCapacity: false)
    }

    private func smoothStep(_ edge0: Float, _ edge1: Float, _ value: Float) -> Float {
        guard edge0 != edge1 else {
            return value >= edge0 ? 1 : 0
        }
        let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    private func easeOutCubic(_ value: Float) -> Float {
        let t = min(max(value, 0), 1)
        let inverse = 1 - t
        return 1 - inverse * inverse * inverse
    }

    private func localizedBurstRadius(points: [CGPoint], in bounds: CGRect) -> Float {
        let minSide = Float(min(bounds.width, bounds.height))
        let maxGridRadius = min(
            Float(hypot(bounds.width, bounds.height)) * 0.45,
            minSide * 0.52
        )

        guard !points.isEmpty else {
            return max(36, min(minSide * 0.3, maxGridRadius))
        }

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

        let spanX = max(maxX - minX, 1)
        let spanY = max(maxY - minY, 1)
        let selectionDiagonal = hypot(spanX, spanY)
        let radius = selectionDiagonal * 0.48 + 26
        return max(32, min(radius, maxGridRadius))
    }

    private func completionRadius(in bounds: CGRect) -> Float {
        let minSide = Float(min(bounds.width, bounds.height))
        return max(72, minSide * 0.62)
    }
}
