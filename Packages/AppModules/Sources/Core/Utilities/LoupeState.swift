/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Utilities/LoupeState.swift
 - Rol principal: Funciones auxiliares compartidas para evitar duplicar logica transversal.
 - Flujo simplificado: Entrada: parametros concretos. | Proceso: calculo helper acotado. | Salida: valor util para otras capas.
 - Tipos clave en este archivo: LoupeConfiguration,LoupeState
 - Funciones clave en este archivo: lerped,clamped
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

import CoreGraphics

public struct LoupeConfiguration {
    public var size: CGSize
    public var magnification: CGFloat
    public var offset: CGSize
    public var edgePadding: CGFloat
    public var cornerRadius: CGFloat
    public var borderWidth: CGFloat
    public var smoothing: CGFloat

    public init(
        size: CGSize = CGSize(width: 110, height: 110),
        magnification: CGFloat = 1.7,
        offset: CGSize = CGSize(width: 0, height: -70),
        edgePadding: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat = 1.2,
        smoothing: CGFloat = 0.22
    ) {
        self.size = size
        self.magnification = magnification
        self.offset = offset
        self.edgePadding = edgePadding
        self.cornerRadius = cornerRadius ?? min(size.width, size.height) * 0.5
        self.borderWidth = borderWidth
        self.smoothing = smoothing
    }

    public static let `default` = LoupeConfiguration()
}

public struct LoupeState {
    public var isVisible: Bool = false
    public var fingerLocation: CGPoint = .zero
    public var loupeScreenPosition: CGPoint = .zero
    public var magnification: CGFloat
    public var loupeSize: CGSize

    public init(configuration: LoupeConfiguration = .default) {
        magnification = configuration.magnification
        loupeSize = configuration.size
    }

    public mutating func update(
        fingerLocation: CGPoint,
        in bounds: CGRect,
        configuration: LoupeConfiguration
    ) {
        magnification = configuration.magnification
        loupeSize = configuration.size

        let clampedFinger = fingerLocation.clamped(to: bounds)
        self.fingerLocation = clampedFinger

        let target = LoupeState.clampedLoupePosition(
            fingerLocation: fingerLocation,
            bounds: bounds,
            size: configuration.size,
            offset: configuration.offset,
            edgePadding: configuration.edgePadding
        )

        if !isVisible {
            isVisible = true
            loupeScreenPosition = target
            return
        }

        if configuration.smoothing > 0 {
            loupeScreenPosition = loupeScreenPosition.lerped(
                to: target,
                alpha: configuration.smoothing
            )
        } else {
            loupeScreenPosition = target
        }
    }

    public mutating func hide() {
        isVisible = false
    }

    private static func clampedLoupePosition(
        fingerLocation: CGPoint,
        bounds: CGRect,
        size: CGSize,
        offset: CGSize,
        edgePadding: CGFloat
    ) -> CGPoint {
        let raw = CGPoint(
            x: fingerLocation.x + offset.width,
            y: fingerLocation.y + offset.height
        )

        let insetX = size.width * 0.5 + edgePadding
        let insetY = size.height * 0.5 + edgePadding
        let safeRect = bounds.insetBy(dx: insetX, dy: insetY)

        guard safeRect.width > 0, safeRect.height > 0 else {
            return CGPoint(x: bounds.midX, y: bounds.midY)
        }

        return raw.clamped(to: safeRect)
    }
}

private extension CGPoint {
    func lerped(to target: CGPoint, alpha: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (target.x - x) * alpha,
            y: y + (target.y - y) * alpha
        )
    }

    func clamped(to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(x, rect.minX), rect.maxX),
            y: min(max(y, rect.minY), rect.maxY)
        )
    }
}
