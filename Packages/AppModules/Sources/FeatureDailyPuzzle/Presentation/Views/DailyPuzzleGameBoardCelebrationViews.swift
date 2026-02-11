/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleGameBoardCelebrationViews.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleWordCelebrationSequenceView,DailyPuzzleBrushStrokeShape DailyPuzzleSparkleGlyph
 - Funciones clave en este archivo: runSequence,letterScale center,letter path
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

struct DailyPuzzleWordCelebrationSequenceView: View {
    let celebrationID: UUID
    let grid: [[String]]
    let positions: [GridPosition]
    let cellSize: CGFloat
    let brushDuration: TimeInterval
    let waveDuration: TimeInterval
    let intensity: CelebrationIntensity
    let reduceMotion: Bool

    @State private var brushProgress: CGFloat = 0
    @State private var activeLetterIndex: Int?
    @State private var sparkleVisible = false
    @State private var sequenceTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let first = positions.first, let last = positions.last {
                let startPoint = center(for: first, cellSize: cellSize)
                let endPoint = center(for: last, cellSize: cellSize)
                let dx = endPoint.x - startPoint.x
                let dy = endPoint.y - startPoint.y
                let angle = Angle(radians: atan2(dy, dx))
                let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                let capsuleHeight = cellSize * 0.84
                let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)
                let revealedWidth = max(capsuleHeight * 0.36, capsuleWidth * brushProgress)

                ZStack {
                    DailyPuzzleBrushStrokeShape(seed: brushSeed)
                        .fill(ThemeGradients.brushWarmStrong.opacity(intensity.brushOpacity))
                        .overlay {
                            DailyPuzzleBrushStrokeShape(seed: brushSeed + 41)
                                .stroke(ColorTokens.accentAmberStrong.opacity(0.30), lineWidth: max(0.8, cellSize * 0.038))
                        }
                        .frame(width: capsuleWidth, height: capsuleHeight)
                        .mask {
                            Rectangle()
                                .frame(width: revealedWidth, height: capsuleHeight)
                                .frame(width: capsuleWidth, height: capsuleHeight, alignment: .leading)
                        }
                        .rotationEffect(angle)
                        .position(centerPoint)

                    ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                        Text(letter(at: position))
                            .font(TypographyTokens.boardLetter(size: max(10, cellSize * 0.45)))
                            .foregroundStyle(ColorTokens.inkPrimary)
                            .scaleEffect(letterScale(for: index))
                            .shadow(
                                color: ColorTokens.accentAmberStrong.opacity(activeLetterIndex == index ? 0.24 : 0),
                                radius: activeLetterIndex == index ? 3 : 0
                            )
                            .position(center(for: position, cellSize: cellSize))
                    }

                    if sparkleVisible {
                        DailyPuzzleSparkleGlyph(size: max(9, cellSize * 0.36))
                            .position(
                                CGPoint(
                                    x: endPoint.x + cellSize * 0.16,
                                    y: endPoint.y - cellSize * 0.21
                                )
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.45)))
                    }
                }
                .onAppear {
                    runSequence()
                }
                .onChange(of: celebrationID) { _ in
                    runSequence()
                }
                .onDisappear {
                    sequenceTask?.cancel()
                    sequenceTask = nil
                }
            }
        }
    }

    private var brushSeed: Int {
        positions.reduce(19) { result, position in
            (result &* 31) &+ (position.row &* 17) &+ (position.col &* 13)
        }
    }

    private func runSequence() {
        sequenceTask?.cancel()
        brushProgress = reduceMotion ? 1 : 0
        activeLetterIndex = nil
        sparkleVisible = false

        guard !positions.isEmpty else { return }

        let adjustedWaveDuration = waveDuration * intensity.waveDurationFactor
        let perLetterDelay = max(0.045, adjustedWaveDuration / Double(max(positions.count, 1)))
        let holdDuration = max(0.028, perLetterDelay * 0.62)

        sequenceTask = Task { @MainActor in
            if !reduceMotion {
                withAnimation(.easeOut(duration: brushDuration)) {
                    brushProgress = 1
                }
                try? await Task.sleep(
                    nanoseconds: UInt64(max(0.01, brushDuration - 0.015) * 1_000_000_000)
                )
            } else {
                brushProgress = 1
            }

            guard !Task.isCancelled else { return }

            for index in positions.indices {
                withAnimation(.spring(response: 0.20, dampingFraction: 0.60)) {
                    activeLetterIndex = index
                }
                try? await Task.sleep(nanoseconds: UInt64(holdDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.08)) {
                    if activeLetterIndex == index {
                        activeLetterIndex = nil
                    }
                }
                let coolDown = max(0.012, perLetterDelay - holdDuration)
                try? await Task.sleep(nanoseconds: UInt64(coolDown * 1_000_000_000))
                guard !Task.isCancelled else { return }
            }

            withAnimation(.easeOut(duration: reduceMotion ? 0.08 : 0.1)) {
                sparkleVisible = true
            }
            try? await Task.sleep(nanoseconds: 110_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                sparkleVisible = false
            }
        }
    }

    private func letterScale(for index: Int) -> CGFloat {
        guard activeLetterIndex == index else { return 1 }
        return reduceMotion ? 1.04 : intensity.popScale
    }

    private func center(for position: GridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }

    private func letter(at position: GridPosition) -> String {
        guard position.row >= 0,
              position.col >= 0,
              position.row < grid.count,
              position.col < grid[position.row].count else {
            return ""
        }
        return grid[position.row][position.col]
    }
}

private struct DailyPuzzleBrushStrokeShape: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let sampleCount = max(10, Int(rect.width / max(6, rect.height * 0.36)))
        let halfHeight = rect.height * 0.5
        let seedA = CGFloat((seed % 23) + 1)
        let seedB = CGFloat((seed % 19) + 3)

        var topPoints: [CGPoint] = []
        var bottomPoints: [CGPoint] = []
        topPoints.reserveCapacity(sampleCount + 1)
        bottomPoints.reserveCapacity(sampleCount + 1)

        for index in 0...sampleCount {
            let t = CGFloat(index) / CGFloat(sampleCount)
            let x = rect.minX + rect.width * t
            let edgeTaper = 0.76 + 0.24 * sin(t * .pi)
            let noiseA = sin((t * 8.4) + seedA * 0.19) * 0.16
            let noiseB = cos((t * 13.6) + seedB * 0.23) * 0.11
            let jitter = (noiseA + noiseB) * rect.height

            topPoints.append(
                CGPoint(
                    x: x,
                    y: rect.midY - halfHeight * edgeTaper + jitter * 0.22
                )
            )
            bottomPoints.append(
                CGPoint(
                    x: x,
                    y: rect.midY + halfHeight * edgeTaper + jitter * 0.19
                )
            )
        }

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for point in topPoints {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        for point in bottomPoints.reversed() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct DailyPuzzleSparkleGlyph: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(ColorTokens.accentAmberStrong)
            .shadow(color: ColorTokens.accentAmberStrong.opacity(0.30), radius: 4, x: 0, y: 0)
    }
}

private extension CelebrationIntensity {
    var popScale: CGFloat {
        switch self {
        case .low:
            return 1.11
        case .medium:
            return 1.16
        case .high:
            return 1.21
        }
    }

    var waveDurationFactor: Double {
        switch self {
        case .low:
            return 1.08
        case .medium:
            return 1
        case .high:
            return 0.9
        }
    }

    var brushOpacity: Double {
        switch self {
        case .low:
            return 0.58
        case .medium:
            return 0.66
        case .high:
            return 0.74
        }
    }
}
