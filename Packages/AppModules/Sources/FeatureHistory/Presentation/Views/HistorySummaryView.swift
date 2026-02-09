import SwiftUI
import DesignSystem
import Core

public struct HistorySummaryView: View {
    @State private var viewModel: HistorySummaryViewModel

    public init(core: CoreContainer) {
        _viewModel = State(initialValue: HistorySummaryViewModel(core: core))
    }

    public var body: some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                    DSText("Historial", style: .titleSmall)
                    DSText("Completados: \(viewModel.model.completedCount)", style: .body)
                    DSText("Racha: \(viewModel.model.currentStreak)", style: .body)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(SpacingTokens.md)
        .onAppear {
            viewModel.refresh()
        }
    }
}
