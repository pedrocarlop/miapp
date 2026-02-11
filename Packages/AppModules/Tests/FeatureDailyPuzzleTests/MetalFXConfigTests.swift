/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/FeatureDailyPuzzleTests/MetalFXConfigTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: MetalFXConfigTests
 - Funciones clave en este archivo: testIsEnabledHonorsWaveToggle,testIsEnabledHonorsScanlineToggle testClipSpacePointUsesExpectedFormula,testPathPointsAlignWithCellCenters
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

import XCTest
import Core
import CoreGraphics
@testable import FeatureDailyPuzzle

final class MetalFXConfigTests: XCTestCase {
    func testIsEnabledHonorsWaveToggle() {
        var config = FXConfig()
        config.enableWordSuccessWave = false

        XCTAssertFalse(config.isEnabled(for: .wordSuccessWave))
        XCTAssertTrue(config.isEnabled(for: .wordSuccessScanline))
    }

    func testIsEnabledHonorsScanlineToggle() {
        var config = FXConfig()
        config.enableWordSuccessScanline = false

        XCTAssertFalse(config.isEnabled(for: .wordSuccessScanline))
        XCTAssertTrue(config.isEnabled(for: .wordSuccessWave))
    }

    func testCompletionConfettiUsesParticlesToggle() {
        var config = FXConfig()
        config.enableWordSuccessParticles = false

        XCTAssertFalse(config.isEnabled(for: .wordCompletionConfetti))
        config.enableWordSuccessParticles = true
        XCTAssertTrue(config.isEnabled(for: .wordCompletionConfetti))
    }

    func testClipSpacePointUsesExpectedFormula() {
        let size = CGSize(width: 100, height: 80)

        let topLeft = MetalFXCoordinateMapper.clipSpacePoint(
            for: CGPoint(x: 0, y: 0),
            in: size
        )
        XCTAssertEqual(topLeft.x, -1, accuracy: 0.0001)
        XCTAssertEqual(topLeft.y, 1, accuracy: 0.0001)

        let center = MetalFXCoordinateMapper.clipSpacePoint(
            for: CGPoint(x: 50, y: 40),
            in: size
        )
        XCTAssertEqual(center.x, 0, accuracy: 0.0001)
        XCTAssertEqual(center.y, 0, accuracy: 0.0001)

        let bottomRight = MetalFXCoordinateMapper.clipSpacePoint(
            for: CGPoint(x: 100, y: 80),
            in: size
        )
        XCTAssertEqual(bottomRight.x, 1, accuracy: 0.0001)
        XCTAssertEqual(bottomRight.y, -1, accuracy: 0.0001)
    }

    func testPathPointsAlignWithCellCenters() {
        let bounds = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
        let points = MetalFXGridGeometry.pathPoints(
            for: [GridPosition(row: 1, col: 2), GridPosition(row: 3, col: 0)],
            in: bounds,
            rows: 4,
            cols: 4
        )

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].x, 125, accuracy: 0.0001)
        XCTAssertEqual(points[0].y, 75, accuracy: 0.0001)
        XCTAssertEqual(points[1].x, 25, accuracy: 0.0001)
        XCTAssertEqual(points[1].y, 175, accuracy: 0.0001)
    }
}
