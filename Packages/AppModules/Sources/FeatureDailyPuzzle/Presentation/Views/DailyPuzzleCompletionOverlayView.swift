/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleCompletionOverlayView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleCompletionOverlayView,DailyPuzzleCompletionConfettiView
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

struct DailyPuzzleCompletionOverlayView: View {
    let navigationTitle: String
    let showContent: Bool
    let showConfetti: Bool
    let streakLabel: String?
    let reduceMotion: Bool
    let reduceTransparency: Bool
    let onClose: () -> Void
    let onContinue: () -> Void

    private var contentTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .move(edge: .bottom).combined(with: .opacity)
    }

    var body: some View {
        ZStack {
            DSPageBackgroundView(gridOpacity: 0.12)

            ThemeGradients.paperBackground
                .opacity(0.64)
                .ignoresSafeArea()

            if showConfetti {
                DailyPuzzleCompletionConfettiView(reduceMotion: reduceMotion)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                topNavigation
                Spacer(minLength: SpacingTokens.xxxl)

                if showContent {
                    celebrationContent
                        .transition(contentTransition)
                }

                Spacer(minLength: SpacingTokens.xxxl)
            }
            .padding(.horizontal, SpacingTokens.lg)
        }
        .safeAreaInset(edge: .bottom) {
            floatingContinueButton
        }
    }

    private var topNavigation: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .frame(width: 44, height: 44)
                    .background {
                        Circle()
                            .fill(
                                reduceTransparency
                                    ? AnyShapeStyle(ColorTokens.surfaceSecondary)
                                    : AnyShapeStyle(.regularMaterial)
                            )
                    }
            }
            .accessibilityLabel(DailyPuzzleStrings.close)

            Spacer()

            Text(navigationTitle)
                .font(TypographyTokens.titleSmall.weight(.semibold))
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer()

            Circle()
                .fill(.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.top, SpacingTokens.xs)
    }

    private var celebrationContent: some View {
        VStack(spacing: SpacingTokens.lg) {
            DailyPuzzleCompletionBadge(reduceMotion: reduceMotion)

            VStack(spacing: SpacingTokens.xs) {
                Text(DailyPuzzleStrings.completionCelebrationTitle)
                    .font(TypographyTokens.titleLarge.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)

                Text(DailyPuzzleStrings.completionCelebrationMessage)
                    .font(TypographyTokens.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let streakLabel {
                Label(streakLabel, systemImage: "flame.fill")
                    .font(TypographyTokens.bodyStrong)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.vertical, SpacingTokens.xs)
                    .background {
                        Capsule()
                            .fill(
                                reduceTransparency
                                    ? AnyShapeStyle(ColorTokens.surfaceSecondary)
                                    : AnyShapeStyle(.thinMaterial)
                            )
                            .overlay {
                                Capsule()
                                    .dsInnerStroke(ColorTokens.accentAmberStrong.opacity(0.28), lineWidth: 1)
                            }
                    }
            }
        }
        .frame(maxWidth: 380)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(DailyPuzzleStrings.completionAccessibility(streakLabel))
    }

    private var floatingContinueButton: some View {
        DSButton(DailyPuzzleStrings.completionContinueAction) {
            onContinue()
        }
        .padding(.horizontal, SpacingTokens.lg)
        .padding(.top, SpacingTokens.sm)
        .padding(.bottom, SpacingTokens.sm)
    }
}

private struct DailyPuzzleCompletionBadge: View {
    let reduceMotion: Bool

    @State private var badgeScale: CGFloat = 0.92
    @State private var shineOffset: CGFloat = -104
    @State private var didPlayShine = false

    var body: some View {
        ZStack {
            Circle()
                .fill(ColorTokens.accentAmberStrong.opacity(0.20))
                .frame(width: 126, height: 126)
                .blur(radius: 20)

            Circle()
                .fill(ThemeGradients.completionBrush)
                .frame(width: 88, height: 88)
                .overlay {
                    Circle()
                        .dsInnerStroke(ColorTokens.surfacePaper.opacity(0.50), lineWidth: 2)
                }
                .shadow(color: ColorTokens.accentAmberStrong.opacity(0.32), radius: 12, x: 0, y: 8)

            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTokens.surfacePaper)
        }
        .overlay {
            if !reduceMotion {
                RoundedRectangle(cornerRadius: RadiusTokens.infiniteRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                ColorTokens.surfacePaper.opacity(0.52),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 42, height: 112)
                    .rotationEffect(.degrees(18))
                    .offset(x: shineOffset)
                    .blendMode(.screen)
                    .mask {
                        Circle()
                            .frame(width: 92, height: 92)
                    }
                    .allowsHitTesting(false)
            }
        }
        .scaleEffect(badgeScale)
        .onAppear {
            badgeScale = reduceMotion ? 1 : 0.92
            withAnimation(
                reduceMotion
                    ? .easeOut(duration: 0.1)
                    : .spring(response: 0.36, dampingFraction: 0.72)
            ) {
                badgeScale = 1
            }

            guard !reduceMotion else { return }
            guard !didPlayShine else { return }
            didPlayShine = true
            shineOffset = -104
            withAnimation(.easeOut(duration: 0.72).delay(0.2)) {
                shineOffset = 104
            }
        }
    }
}

private struct DailyPuzzleCompletionConfettiView: View {
    let reduceMotion: Bool

    @State private var animate = false
    private let pieceCount = 34

    var body: some View {
        Group {
            if reduceMotion {
                reducedMotionSparkles
            } else {
                GeometryReader { proxy in
                    ZStack {
                        ForEach(0..<pieceCount, id: \.self) { index in
                            let piece = DailyPuzzleCompletionConfettiPiece(index: index)
                            RoundedRectangle(cornerRadius: piece.cornerRadius, style: .continuous)
                                .fill(piece.color)
                                .frame(width: piece.width, height: piece.height)
                                .position(
                                    x: proxy.size.width * piece.startX,
                                    y: -proxy.size.height * 0.12
                                )
                                .offset(
                                    x: animate ? proxy.size.width * piece.horizontalDrift : 0,
                                    y: animate ? proxy.size.height * piece.fallDistance : proxy.size.height * 0.05
                                )
                                .rotationEffect(
                                    .degrees(animate ? piece.endRotation : piece.startRotation)
                                )
                                .opacity(animate ? 0 : piece.opacity)
                                .animation(
                                    .timingCurve(0.16, 0.92, 0.22, 1, duration: piece.duration)
                                        .delay(piece.delay),
                                    value: animate
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            animate = true
        }
    }

    private var reducedMotionSparkles: some View {
        VStack {
            HStack(spacing: SpacingTokens.md) {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            index.isMultiple(of: 3)
                                ? ColorTokens.accentCoralStrong
                                : ColorTokens.accentAmberStrong
                        )
                }
            }
            .padding(.top, SpacingTokens.xxl)
            Spacer()
        }
    }
}

private struct DailyPuzzleCompletionConfettiPiece {
    let startX: CGFloat
    let horizontalDrift: CGFloat
    let fallDistance: CGFloat
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let startRotation: Double
    let endRotation: Double
    let delay: Double
    let duration: Double
    let opacity: Double
    let color: Color

    init(index: Int) {
        startX = 0.08 + Self.normalized(index: index, salt: 1) * 0.84
        horizontalDrift = (Self.normalized(index: index, salt: 2) - 0.5) * 0.42
        fallDistance = 0.68 + Self.normalized(index: index, salt: 3) * 0.34
        width = 6 + Self.normalized(index: index, salt: 4) * 10
        height = 4 + Self.normalized(index: index, salt: 5) * 6
        cornerRadius = 1 + Self.normalized(index: index, salt: 6) * 2.2

        startRotation = Double(Self.normalized(index: index, salt: 7) * 360)
        endRotation = startRotation + Double(160 + Self.normalized(index: index, salt: 8) * 300)
        delay = Double(Self.normalized(index: index, salt: 9) * 0.28)
        duration = Double(0.98 + Self.normalized(index: index, salt: 10) * 0.54)
        opacity = Double(0.62 + Self.normalized(index: index, salt: 11) * 0.33)

        switch index % 6 {
        case 0:
            color = ColorTokens.accentAmberStrong
        case 1:
            color = ColorTokens.accentCoralStrong
        case 2:
            color = ColorTokens.success
        case 3:
            color = ColorTokens.surfacePaper
        case 4:
            color = ColorTokens.accentCoral
        default:
            color = ColorTokens.accentAmber
        }
    }

    private static func normalized(index: Int, salt: Int) -> CGFloat {
        let value = ((index + 1) * 127 + salt * 61) % 997
        return CGFloat(value) / 997
    }
}
