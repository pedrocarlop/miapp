import SwiftUI
import DesignSystem
import Core

public struct SettingsPanelView: View {
    @State private var viewModel: SettingsViewModel

    public init(core: CoreContainer) {
        _viewModel = State(initialValue: SettingsViewModel(core: core))
    }

    public var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                DSText("Ajustes", style: .titleSmall)
                Stepper("Tamano: \(viewModel.model.gridSize)", value: Binding(
                    get: { viewModel.model.gridSize },
                    set: { viewModel.setGridSize($0) }
                ), in: WordSearchConfig.minGridSize...WordSearchConfig.maxGridSize)
                DSButton("Guardar") {
                    viewModel.save()
                }
            }
        }
        .padding(SpacingTokens.md)
    }
}
