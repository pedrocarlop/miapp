/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureHistory/Presentation/Views/HistoryCounterInfoSheetView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: HistoryCounterInfoKind,HistoryCounterInfoSheetView
 - Funciones clave en este archivo: (sin funciones directas visibles; revisa propiedades/constantes/extensiones)
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
            return HistoryStrings.completedPuzzlesTitle
        case .streak:
            return HistoryStrings.streakTitle
        }
    }

    var explanation: String {
        switch self {
        case .completedPuzzles:
            return HistoryStrings.completedPuzzlesExplanation
        case .streak:
            return HistoryStrings.streakExplanation
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
