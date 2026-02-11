import SwiftUI

public extension Shape {
    @ViewBuilder
    func dsInnerStroke<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View {
        // Fallback for non-insettable shapes: emulate inner stroke by insetting via padding.
        stroke(content, lineWidth: lineWidth)
            .padding(lineWidth / 2)
    }

    @ViewBuilder
    func dsInnerStroke<S: ShapeStyle>(_ content: S, style: StrokeStyle) -> some View {
        // Fallback for non-insettable shapes: emulate inner stroke by insetting via padding.
        stroke(content, style: style)
            .padding(style.lineWidth / 2)
    }
}

public extension InsettableShape {
    @ViewBuilder
    func dsInnerStroke<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View {
        strokeBorder(content, lineWidth: lineWidth)
    }

    @ViewBuilder
    func dsInnerStroke<S: ShapeStyle>(_ content: S, style: StrokeStyle) -> some View {
        strokeBorder(content, style: style)
    }
}
