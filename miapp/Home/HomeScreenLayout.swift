/*
 BEGINNER NOTES (AUTO):
 - Archivo: miapp/Home/HomeScreenLayout.swift
 - Rol principal: Soporte general de arquitectura: tipos, configuracion o pegamento entre modulos.
 - Flujo simplificado: Entrada: contexto de modulo. | Proceso: ejecutar responsabilidad local del archivo. | Salida: tipo/valor usado por otras piezas.
 - Tipos clave en este archivo: HomeScreenLayout,HomeToolbarContent
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
import FeatureDailyPuzzle
import FeatureHistory

struct HomeScreenLayout: View {
    let challengeCards: [DailyPuzzleChallengeCardState]
    let carouselOffsets: [Int]
    @Binding var selectedOffset: Int?
    let todayOffset: Int
    let unlockedOffsets: Set<Int>
    let launchingCardOffset: Int?
    let onCardTap: (Int) -> Void
    let dateForOffset: (Int) -> Date
    let progressForOffset: (Int) -> Double
    let hoursUntilAvailable: (Int) -> Int?

    var body: some View {
        GeometryReader { geometry in
            let verticalInset = SpacingTokens.xxxl
            let interSectionSpacing = SpacingTokens.xxxl
            let dayCarouselHeight: CGFloat = 106
            let cardWidth = min(geometry.size.width * 0.80, 450)
            let availableCardHeight = geometry.size.height - dayCarouselHeight - interSectionSpacing - (verticalInset * 2)
            let cardHeight = min(max(availableCardHeight, 260), 620)
            let focusedOffset = selectedOffset ?? todayOffset
            let carouselIndex = Binding<Int?>(
                get: {
                    guard !challengeCards.isEmpty else { return nil }
                    let targetOffset = selectedOffset ?? todayOffset

                    if let current = challengeCards.firstIndex(where: { $0.offset == targetOffset }) {
                        return current
                    }
                    if let today = challengeCards.firstIndex(where: { $0.offset == todayOffset }) {
                        return today
                    }
                    return challengeCards.startIndex
                },
                set: { index in
                    guard
                        let index,
                        challengeCards.indices.contains(index)
                    else { return }

                    let offset = challengeCards[index].offset
                    guard selectedOffset != offset else { return }
                    selectedOffset = offset
                }
            )

            VStack(spacing: interSectionSpacing) {
                CarouselView(
                    items: challengeCards,
                    currentIndex: carouselIndex,
                    itemWidth: cardWidth,
                    itemSpacing: SpacingTokens.sm + 2
                ) { card in
                    DailyPuzzleChallengeCardView(
                        date: card.date,
                        puzzleNumber: card.puzzleNumber,
                        grid: card.grid,
                        words: card.words,
                        foundWords: card.progress.foundWords,
                        solvedPositions: card.progress.solvedPositions,
                        isLocked: card.isLocked,
                        hoursUntilAvailable: card.hoursUntilAvailable,
                        isLaunching: launchingCardOffset == card.offset,
                        isFocused: card.offset == focusedOffset
                    ) {
                        onCardTap(card.offset)
                    }
                    .frame(height: cardHeight)
                    .scaleEffect(launchingCardOffset == card.offset ? 1.10 : 1)
                    .opacity(launchingCardOffset == nil || launchingCardOffset == card.offset ? 1 : 0.45)
                    .zIndex(launchingCardOffset == card.offset ? 5 : 0)
                }
                .frame(height: cardHeight)

                DailyPuzzleDayCarouselView(
                    offsets: carouselOffsets,
                    selectedOffset: $selectedOffset,
                    todayOffset: todayOffset,
                    unlockedOffsets: unlockedOffsets,
                    dateForOffset: dateForOffset,
                    progressForOffset: progressForOffset,
                    hoursUntilAvailable: hoursUntilAvailable,
                    onDayTap: { _ in }
                )
                .frame(height: dayCarouselHeight)
                .padding(.horizontal, SpacingTokens.sm)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, verticalInset)
        }
    }
}

struct HomeToolbarContent: ToolbarContent {
    let completedCount: Int
    let streakCount: Int
    let onCompletedTap: () -> Void
    let onStreakTap: () -> Void
    let onSettingsTap: () -> Void
    let toolbarActionTransitionNamespace: Namespace.ID?

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(AppStrings.homeTitle)
                .font(TypographyTokens.screenTitle)
        }

        if #available(iOS 26.0, *), let toolbarActionTransitionNamespace {
            ToolbarItemGroup(placement: .topBarTrailing) {
                homeActionsContent
            }
            .matchedTransitionSource(id: "puzzle-nav-actions", in: toolbarActionTransitionNamespace)
        } else {
            ToolbarItemGroup(placement: .topBarTrailing) {
                homeActionsContent
            }
        }
    }

    @ViewBuilder
    private var homeActionsContent: some View {
        HistoryNavCounterView(
            value: completedCount,
            systemImage: "checkmark.seal.fill",
            iconGradient: ThemeGradients.brushWarm,
            accessibilityLabel: AppStrings.completedCounterAccessibility(completedCount),
            accessibilityHint: AppStrings.completedCounterHint
        ) {
            onCompletedTap()
        }

        HistoryNavCounterView(
            value: streakCount,
            systemImage: "flame.fill",
            iconGradient: ThemeGradients.brushWarmStrong,
            accessibilityLabel: AppStrings.streakCounterAccessibility(streakCount),
            accessibilityHint: AppStrings.streakCounterHint
        ) {
            onStreakTap()
        }

        Button {
            onSettingsTap()
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .accessibilityLabel(AppStrings.openSettingsAccessibility)
    }
}
