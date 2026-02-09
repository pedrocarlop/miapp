import SwiftUI
import Core
import DesignSystem

public enum HistoryCounterInfoKind: String, Identifiable, Sendable {
    case completedPuzzles
    case streak

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .completedPuzzles:
            return "Puzzles completados"
        case .streak:
            return "Racha actual"
        }
    }

    var explanation: String {
        switch self {
        case .completedPuzzles:
            return "Muestra cuantos retos diarios has terminado en total desde que instalaste la app."
        case .streak:
            return "Cuenta los dias seguidos en los que completas el reto del dia actual. Si un dia no lo completas, la racha se reinicia."
        }
    }
}

public struct HistoryCounterInfoSheetView: View {
    @State private var viewModel: HistorySummaryViewModel

    private let info: HistoryCounterInfoKind

    public init(core: CoreContainer, info: HistoryCounterInfoKind) {
        _viewModel = State(initialValue: HistorySummaryViewModel(core: core))
        self.info = info
    }

    public var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            VStack(spacing: SpacingTokens.sm) {
                DSText(info.title, style: .titleSmall)
                    .multilineTextAlignment(.center)
                DSText("\(displayValue)", style: .titleLarge)
                DSText(info.explanation, style: .body, color: ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SpacingTokens.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .presentationDetents([.height(220), .medium])
        .presentationDragIndicator(.hidden)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var displayValue: Int {
        switch info {
        case .completedPuzzles:
            return viewModel.model.completedCount
        case .streak:
            return viewModel.model.currentStreak
        }
    }
}
