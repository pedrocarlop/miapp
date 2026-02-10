#if os(iOS)
import MetalKit
import SwiftUI
import UIKit

@MainActor
public struct MetalFXView: UIViewRepresentable {
    @ObservedObject private var manager: MetalFXManager
    private let size: CGSize

    public init(manager: MetalFXManager, size: CGSize) {
        self.manager = manager
        self.size = size
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(
            frame: CGRect(origin: .zero, size: size),
            device: MTLCreateSystemDefaultDevice()
        )
        mtkView.isOpaque = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.framebufferOnly = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = true
        mtkView.isUserInteractionEnabled = false
        mtkView.backgroundColor = .clear
        mtkView.layer.isOpaque = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.colorPixelFormat = .bgra8Unorm

        context.coordinator.attachRendererIfNeeded(to: mtkView)
        context.coordinator.updateConfig(manager.config)
        updateDrawableSize(for: mtkView)
        return mtkView
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateConfig(manager.config)
        updateDrawableSize(for: uiView)
    }

    public static func dismantleUIView(_ uiView: MTKView, coordinator: Coordinator) {
        coordinator.detachRenderer()
        uiView.delegate = nil
    }

    private func updateDrawableSize(for view: MTKView) {
        let scale = UIScreen.main.scale
        let drawableSize = CGSize(width: size.width * scale, height: size.height * scale)
        if view.drawableSize != drawableSize {
            view.drawableSize = drawableSize
        }
    }

    @MainActor
    public final class Coordinator {
        private let manager: MetalFXManager
        private var renderer: MetalFXRenderer?

        init(manager: MetalFXManager) {
            self.manager = manager
        }

        func attachRendererIfNeeded(to view: MTKView) {
            guard renderer == nil else { return }
            guard let renderer = MetalFXRenderer(view: view) else { return }
            self.renderer = renderer
            view.delegate = renderer
            manager.attach(renderer: renderer)
            renderer.updateConfig(manager.config)
        }

        func updateConfig(_ config: FXConfig) {
            renderer?.updateConfig(config)
        }

        func detachRenderer() {
            guard let renderer else { return }
            renderer.reset()
            manager.detach(renderer: renderer)
            self.renderer = nil
        }
    }
}
#else
import SwiftUI

@MainActor
public struct MetalFXView: View {
    @ObservedObject private var manager: MetalFXManager
    private let size: CGSize

    public init(manager: MetalFXManager, size: CGSize) {
        self.manager = manager
        self.size = size
    }

    public var body: some View {
        Color.clear
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
    }
}
#endif
