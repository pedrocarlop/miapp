import SwiftUI

private enum CarouselConstants {
    static let focusScale: CGFloat = 1.04
    static let sideScale: CGFloat = 0.90
    static let focusOpacity: CGFloat = 1
    static let sideOpacity: CGFloat = 0.93
    static let focusLift: CGFloat = -5
    static let settleSpring = Animation.spring(
        response: 0.35,
        dampingFraction: 0.82,
        blendDuration: 0.15
    )
    static let focusLiftAnimation = Animation.easeOut(duration: 0.12)
}

private struct CarouselDragOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

public extension EnvironmentValues {
    var carouselDragOffset: CGFloat {
        get { self[CarouselDragOffsetKey.self] }
        set { self[CarouselDragOffsetKey.self] = newValue }
    }
}

private struct CarouselParallaxModifier: ViewModifier {
    @Environment(\.carouselDragOffset) private var dragOffset
    let multiplier: CGFloat

    func body(content: Content) -> some View {
        // Opposes finger movement to create depth between internal layers.
        content.offset(x: -dragOffset * multiplier)
    }
}

public extension View {
    func carouselParallax(multiplier: CGFloat) -> some View {
        modifier(CarouselParallaxModifier(multiplier: multiplier))
    }
}

public struct CarouselView<Item, Content: View>: View {
    private let items: [Item]
    private let currentIndex: Binding<Int?>?
    private let itemWidth: CGFloat
    private let itemSpacing: CGFloat
    private let content: (Item) -> Content

    @GestureState private var dragTranslation: CGFloat = 0
    @State private var fallbackIndex: Int = 0
    @State private var settleOffset: CGFloat = 0

    public init(
        items: [Item],
        currentIndex: Binding<Int?>? = nil,
        itemWidth: CGFloat,
        itemSpacing: CGFloat = SpacingTokens.md,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.currentIndex = currentIndex
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self.content = content
    }

    public var body: some View {
        GeometryReader { geometry in
            let stride = itemWidth + itemSpacing
            let activeIndex = resolvedActiveIndex
            let trackOffset = -CGFloat(activeIndex) * stride + dragTranslation + settleOffset
            let horizontalInset = max((geometry.size.width - itemWidth) / 2, 0)

            HStack(spacing: itemSpacing) {
                ForEach(Array(items.indices), id: \.self) { index in
                    let metrics = metricsForItem(
                        at: index,
                        viewportWidth: geometry.size.width,
                        stride: stride,
                        trackOffset: trackOffset,
                        horizontalInset: horizontalInset
                    )

                    content(items[index])
                        .frame(width: itemWidth)
                        .scaleEffect(metrics.scale)
                        .opacity(metrics.opacity)
                        .offset(y: index == activeIndex ? CarouselConstants.focusLift : 0)
                        .shadow(
                            color: ShadowTokens.cardAmbient.color.opacity(metrics.ambientOpacity),
                            radius: metrics.ambientRadius,
                            x: ShadowTokens.cardAmbient.x,
                            y: metrics.ambientY
                        )
                        .shadow(
                            color: ShadowTokens.cardDrop.color.opacity(metrics.dropOpacity),
                            radius: metrics.dropRadius,
                            x: ShadowTokens.cardDrop.x,
                            y: metrics.dropY
                        )
                        .environment(\.carouselDragOffset, dragTranslation)
                        .animation(CarouselConstants.focusLiftAnimation, value: activeIndex)
                        .zIndex(metrics.zIndex)
                }
            }
            .padding(.horizontal, horizontalInset)
            .offset(x: trackOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .simultaneousGesture(dragGesture)
        .onAppear {
            reconcileIndexState()
        }
        .onChange(of: items.count) { _ in
            reconcileIndexState()
        }
        .onChange(of: externalIndex) { _ in
            reconcileIndexState()
        }
    }
}

private extension CarouselView {
    var maxIndex: Int {
        max(items.count - 1, 0)
    }

    var externalIndex: Int? {
        currentIndex?.wrappedValue
    }

    var resolvedActiveIndex: Int {
        guard !items.isEmpty else { return 0 }
        if let externalIndex {
            return clampedIndex(externalIndex)
        }
        return clampedIndex(fallbackIndex)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                settleDrag(with: value.translation.width)
            }
    }

    func settleDrag(with translation: CGFloat) {
        guard !items.isEmpty else { return }

        let stride = itemWidth + itemSpacing
        let threshold = max(40, stride * 0.22)
        var nextIndex = resolvedActiveIndex

        if translation <= -threshold {
            nextIndex = min(nextIndex + 1, maxIndex)
        } else if translation >= threshold {
            nextIndex = max(nextIndex - 1, 0)
        }

        settleOffset = translation
        withAnimation(CarouselConstants.settleSpring) {
            settleOffset = 0
            setActiveIndex(nextIndex)
        }
    }

    func setActiveIndex(_ index: Int) {
        guard !items.isEmpty else {
            fallbackIndex = 0
            currentIndex?.wrappedValue = nil
            return
        }

        let clamped = clampedIndex(index)
        fallbackIndex = clamped
        currentIndex?.wrappedValue = clamped
    }

    func clampedIndex(_ index: Int) -> Int {
        min(max(index, 0), maxIndex)
    }

    func reconcileIndexState() {
        guard !items.isEmpty else {
            fallbackIndex = 0
            currentIndex?.wrappedValue = nil
            return
        }

        if let externalIndex {
            let clamped = clampedIndex(externalIndex)
            fallbackIndex = clamped
            if clamped != externalIndex {
                currentIndex?.wrappedValue = clamped
            }
            return
        }

        let clampedFallback = clampedIndex(fallbackIndex)
        fallbackIndex = clampedFallback
        currentIndex?.wrappedValue = clampedFallback
    }

    func metricsForItem(
        at index: Int,
        viewportWidth: CGFloat,
        stride: CGFloat,
        trackOffset: CGFloat,
        horizontalInset: CGFloat
    ) -> CarouselItemMetrics {
        let itemCenter = horizontalInset + (itemWidth / 2) + (CGFloat(index) * stride) + trackOffset
        let viewportCenter = viewportWidth / 2
        let distance = abs(itemCenter - viewportCenter)
        let normalizedDistance = clamp(distance / max(stride, 1), lower: 0, upper: 1)
        let focus = 1 - normalizedDistance

        let scale = lerp(
            from: CarouselConstants.sideScale,
            to: CarouselConstants.focusScale,
            progress: focus
        )
        let opacity = lerp(
            from: CarouselConstants.sideOpacity,
            to: CarouselConstants.focusOpacity,
            progress: focus
        )

        let ambientRadius = lerp(
            from: ShadowTokens.cardAmbient.radius * 0.8,
            to: ShadowTokens.cardAmbient.radius * 1.65,
            progress: focus
        )
        let dropRadius = lerp(
            from: ShadowTokens.cardDrop.radius * 0.72,
            to: ShadowTokens.cardDrop.radius * 1.85,
            progress: focus
        )
        let ambientY = lerp(
            from: ShadowTokens.cardAmbient.y,
            to: ShadowTokens.cardAmbient.y + 2,
            progress: focus
        )
        let dropY = lerp(
            from: ShadowTokens.cardDrop.y,
            to: ShadowTokens.cardDrop.y + 4,
            progress: focus
        )
        let ambientOpacity = lerp(from: 0.66, to: 1, progress: focus)
        let dropOpacity = lerp(from: 0.62, to: 1, progress: focus)
        let zIndex = Double(100 - distance)

        return CarouselItemMetrics(
            scale: scale,
            opacity: opacity,
            ambientRadius: ambientRadius,
            dropRadius: dropRadius,
            ambientY: ambientY,
            dropY: dropY,
            ambientOpacity: ambientOpacity,
            dropOpacity: dropOpacity,
            zIndex: zIndex
        )
    }

    func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }

    func lerp(from start: CGFloat, to end: CGFloat, progress: CGFloat) -> CGFloat {
        start + (end - start) * progress
    }
}

private struct CarouselItemMetrics {
    let scale: CGFloat
    let opacity: CGFloat
    let ambientRadius: CGFloat
    let dropRadius: CGFloat
    let ambientY: CGFloat
    let dropY: CGFloat
    let ambientOpacity: CGFloat
    let dropOpacity: CGFloat
    let zIndex: Double
}
