import SwiftUI

public struct ThemeProvider<Content: View>: View {
    private let theme: Theme
    private let content: Content

    public init(theme: Theme = .default, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    public var body: some View {
        content
            .environment(\.dsTheme, theme)
            .tint(theme.accentPrimary)
    }
}
