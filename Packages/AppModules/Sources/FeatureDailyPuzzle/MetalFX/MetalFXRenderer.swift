/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/MetalFX/MetalFXRenderer.swift
 - Rol principal: Renderiza o configura efectos visuales GPU (Metal) para feedback del juego.
 - Flujo simplificado: Entrada: eventos visuales + tiempo/frame. | Proceso: preparar uniforms y lanzar draw calls. | Salida: efecto renderizado sobre el tablero.
 - Tipos clave en este archivo: MetalFXRenderer
 - Funciones clave en este archivo: enqueue,updateConfig reset,draw mtkView,consumePendingEvents
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
import Metal
import MetalKit
import QuartzCore

public final class MetalFXRenderer: NSObject, MTKViewDelegate {
    private struct Pipelines {
        let alpha: MTLRenderPipelineState
        let additive: MTLRenderPipelineState
    }

    private let commandQueue: MTLCommandQueue
    private let pipelines: Pipelines
    private var effects: [any FXEffect]

    private let pendingLock = NSLock()
    private var pendingEvents: [FXEvent] = []
    private weak var view: MTKView?

    private var lastFrameTimestamp: CFTimeInterval?
    private var rendererTime: Float = 0

    public init?(view: MTKView) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice() else {
            return nil
        }
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        guard let pipelines = Self.makePipelines(device: device, pixelFormat: view.colorPixelFormat) else {
            return nil
        }
        guard let waveEffect = WordSuccessWaveEffect(
            device: device,
            alphaPipeline: pipelines.alpha,
            additivePipeline: pipelines.additive
        ) else {
            return nil
        }
        guard let scanlineEffect = WordSuccessScanlineEffect(
            device: device,
            alphaPipeline: pipelines.alpha,
            additivePipeline: pipelines.additive
        ) else {
            return nil
        }
        guard let particlesEffect = WordSuccessParticlesEffect(
            device: device,
            alphaPipeline: pipelines.alpha,
            additivePipeline: pipelines.additive
        ) else {
            return nil
        }

        self.commandQueue = commandQueue
        self.pipelines = pipelines
        effects = [waveEffect, scanlineEffect, particlesEffect]
        self.view = view

        super.init()
    }

    public func enqueue(event: FXEvent) {
        pendingLock.lock()
        pendingEvents.append(event)
        pendingLock.unlock()

        guard let view else { return }
        DispatchQueue.main.async {
            view.isPaused = false
        }
    }

    public func updateConfig(_ config: FXConfig) {
        for effect in effects {
            if let wave = effect as? WordSuccessWaveEffect {
                wave.setDebugEnabled(config.debugEnabled)
            }
            if let scanline = effect as? WordSuccessScanlineEffect {
                scanline.setDebugEnabled(config.debugEnabled)
            }
            if let particles = effect as? WordSuccessParticlesEffect {
                particles.setDebugEnabled(config.debugEnabled)
            }
        }
    }

    public func reset() {
        pendingLock.lock()
        pendingEvents.removeAll(keepingCapacity: false)
        pendingLock.unlock()

        lastFrameTimestamp = nil
        rendererTime = 0
        effects.forEach { $0.reset() }
    }

    public func draw(in view: MTKView) {
        autoreleasepool {
            let now = CACurrentMediaTime()
            let dt: Float
            if let lastFrameTimestamp {
                dt = Float(max(0, now - lastFrameTimestamp))
            } else {
                dt = 1 / 60
            }
            self.lastFrameTimestamp = now
            rendererTime += min(dt, 0.1)

            let events = consumePendingEvents()
            if !events.isEmpty {
                for event in events {
                    for effect in effects {
                        effect.handle(event: event)
                    }
                }
            }

            for effect in effects {
                effect.update(dt: dt)
            }

            let activeEffects = effects.filter(\.isActive)
            guard !activeEffects.isEmpty else {
                pauseIfNeeded(view)
                return
            }

            guard let descriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let attachment = descriptor.colorAttachments[0] else {
                return
            }
            attachment.loadAction = .clear
            attachment.storeAction = .store
            attachment.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }

            let resolution = SIMD2<Float>(
                Float(view.bounds.width),
                Float(view.bounds.height)
            )

            for effect in activeEffects {
                effect.draw(
                    encoder: encoder,
                    resolution: resolution,
                    time: rendererTime
                )
            }

            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        _ = size
    }

    private func consumePendingEvents() -> [FXEvent] {
        pendingLock.lock()
        defer { pendingLock.unlock() }

        guard !pendingEvents.isEmpty else { return [] }
        let events = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)
        return events
    }

    private func pauseIfNeeded(_ view: MTKView) {
        pendingLock.lock()
        let hasPendingEvents = !pendingEvents.isEmpty
        pendingLock.unlock()

        guard !hasPendingEvents else { return }
        DispatchQueue.main.async {
            view.isPaused = true
        }
    }

    private static func makePipelines(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat
    ) -> Pipelines? {
        guard let library = makeLibrary(device: device) else {
            return nil
        }

        guard let alpha = makePipeline(
            library: library,
            device: device,
            pixelFormat: pixelFormat,
            fragmentFunctionName: "fragment_alpha",
            blending: .alpha
        ) else {
            return nil
        }

        guard let additive = makePipeline(
            library: library,
            device: device,
            pixelFormat: pixelFormat,
            fragmentFunctionName: "fragment_additive",
            blending: .additive
        ) else {
            return nil
        }

        return Pipelines(alpha: alpha, additive: additive)
    }

    private static func makeLibrary(device: MTLDevice) -> MTLLibrary? {
        if let bundledLibrary = try? device.makeDefaultLibrary(bundle: .module) {
            return bundledLibrary
        }
        if let defaultLibrary = device.makeDefaultLibrary() {
            return defaultLibrary
        }
        return try? device.makeLibrary(source: MetalFXShaderSource.source, options: nil)
    }

    private enum BlendMode {
        case alpha
        case additive
    }

    private static func makePipeline(
        library: MTLLibrary,
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        fragmentFunctionName: String,
        blending: BlendMode
    ) -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "vertex_passthrough"),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true

        switch blending {
        case .alpha:
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        case .additive:
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        }

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
}
