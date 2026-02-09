import CoreGraphics

struct LoupeConfiguration {
    var size: CGSize
    var magnification: CGFloat
    var offset: CGSize
    var edgePadding: CGFloat
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var smoothing: CGFloat

    init(
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

    static let `default` = LoupeConfiguration()
}

struct LoupeState {
    var isVisible: Bool = false
    var fingerLocation: CGPoint = .zero
    var loupeScreenPosition: CGPoint = .zero
    var magnification: CGFloat
    var loupeSize: CGSize

    init(configuration: LoupeConfiguration = .default) {
        magnification = configuration.magnification
        loupeSize = configuration.size
    }

    mutating func update(
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

    mutating func hide() {
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
