import SwiftUI

public struct PreviewThemeProvider<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ThemeProvider {
            content
                .padding()
                .background(ColorTokens.backgroundPrimary)
        }
    }
}
