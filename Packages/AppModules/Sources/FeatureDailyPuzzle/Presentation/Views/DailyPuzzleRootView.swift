import SwiftUI
import Core
import DesignSystem

public struct DailyPuzzleRootView: View {
    @State private var viewModel: DailyPuzzleHomeViewModel

    public init(container: CoreContainer) {
        _viewModel = State(initialValue: DailyPuzzleHomeViewModel(container: container))
    }

    public var body: some View {
        Group {
            if let model = viewModel.model {
                DSCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                        DSText(model.title, style: .titleMedium)
                        DSText("Dia \(model.dayOffset)", style: .body, color: ColorTokens.textSecondary)
                        ProgressView(value: model.progress)
                            .tint(ColorTokens.accentPrimary)
                        DSText("\(model.foundWords)/\(model.totalWords) palabras", style: .footnote, color: ColorTokens.textSecondary)
                    }
                }
            } else {
                DSCard {
                    DSText("Cargando...", style: .body)
                }
            }
        }
        .padding(SpacingTokens.md)
        .onAppear {
            viewModel.refresh()
        }
    }
}
