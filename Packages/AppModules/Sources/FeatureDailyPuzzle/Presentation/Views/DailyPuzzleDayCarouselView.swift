/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleDayCarouselView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleDayCarouselView,DailyPuzzleDayCarouselItem
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
import DesignSystem
import Core

public struct DailyPuzzleDayCarouselView: View {
    public let offsets: [Int]
    @Binding public var selectedOffset: Int?
    public let todayOffset: Int
    public let unlockedOffsets: Set<Int>
    public let dateForOffset: (Int) -> Date
    public let progressForOffset: (Int) -> Double
    public let hoursUntilAvailable: (Int) -> Int?

    public init(
        offsets: [Int],
        selectedOffset: Binding<Int?>,
        todayOffset: Int,
        unlockedOffsets: Set<Int>,
        dateForOffset: @escaping (Int) -> Date,
        progressForOffset: @escaping (Int) -> Double,
        hoursUntilAvailable: @escaping (Int) -> Int?
    ) {
        self.offsets = offsets
        _selectedOffset = selectedOffset
        self.todayOffset = todayOffset
        self.unlockedOffsets = unlockedOffsets
        self.dateForOffset = dateForOffset
        self.progressForOffset = progressForOffset
        self.hoursUntilAvailable = hoursUntilAvailable
    }

    public var body: some View {
        GeometryReader { geo in
            let itemWidth: CGFloat = 84
            let itemHeight: CGFloat = 92
            let sidePadding = max((geo.size.width - itemWidth) / 2, SpacingTokens.xs)
            let activeOffset = selectedOffset ?? todayOffset
            let scrollSelection = Binding<Int?>(
                get: {
                    let current = selectedOffset ?? todayOffset
                    return offsets.contains(current) ? current : nil
                },
                set: { selectedOffset = $0 }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SpacingTokens.md) {
                    ForEach(offsets, id: \.self) { offset in
                        let date = dateForOffset(offset)
                        let isLocked = offset > todayOffset && !unlockedOffsets.contains(offset)
                        let progress = progressForOffset(offset)
                        DailyPuzzleDayCarouselItem(
                            date: date,
                            isSelected: offset == activeOffset,
                            isLocked: isLocked,
                            isCompleted: progress >= 0.999,
                            progress: progress,
                            hoursUntilAvailable: hoursUntilAvailable(offset)
                        )
                        .frame(width: itemWidth, height: itemHeight)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.28, extraBounce: 0.02)) {
                                selectedOffset = offset
                            }
                        }
                        .id(offset)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, sidePadding)
            }
            .padding(.vertical, SpacingTokens.xs)
            .scrollClipDisabled(true)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: scrollSelection, anchor: .center)
        }
    }
}

private struct DailyPuzzleDayCarouselItem: View {
    let date: Date
    let isSelected: Bool
    let isLocked: Bool
    let isCompleted: Bool
    let progress: Double
    let hoursUntilAvailable: Int?

    var body: some View {
        VStack(spacing: SpacingTokens.xs) {
            Text(weekdayText)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)

            Text("\(Calendar.current.component(.day, from: date))")
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)

            statusView
                .frame(height: 14, alignment: .center)
        }
        .padding(.vertical, SpacingTokens.sm)
        .padding(.horizontal, SpacingTokens.xs)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .fill(ColorTokens.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .stroke(ColorTokens.cardHighlightStroke, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .stroke(ColorTokens.borderDefault, lineWidth: 1)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .stroke(ThemeGradients.brushWarmStrong, lineWidth: 2)
            }
        }
        .scaleEffect(isSelected ? 1.04 : 0.98)
        .opacity(isSelected ? 1 : 0.92)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var weekdayText: String {
        let locale = AppLocalization.currentLocale
        return date
            .formatted(
                .dateTime
                    .locale(locale)
                    .weekday(.abbreviated)
            )
            .uppercased(with: locale)
    }

    @ViewBuilder
    private var statusView: some View {
        if isLocked, let hoursUntilAvailable {
            Text(DailyPuzzleStrings.hoursShort(hoursUntilAvailable))
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else if isCompleted {
            Image(systemName: "checkmark.seal.fill")
                .font(TypographyTokens.footnote)
                .foregroundStyle(ThemeGradients.brushWarm)
        } else {
            DSCircularProgressRing(progress: progress)
        }
    }
}
