/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/FeatureDailyPuzzleTests/DailyPuzzleStringsTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: DailyPuzzleStringsTests
 - Funciones clave en este archivo: testChallengeProgressIncludesCounts,testChallengeAccessibilityContainsChallengeNumber
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
@testable import FeatureDailyPuzzle

final class DailyPuzzleStringsTests: XCTestCase {
    func testChallengeProgressIncludesCounts() {
        let value = DailyPuzzleStrings.challengeProgress(found: 2, total: 5)
        XCTAssertTrue(value.contains("2"))
        XCTAssertTrue(value.contains("5"))
    }

    func testChallengeAccessibilityContainsChallengeNumber() {
        let value = DailyPuzzleStrings.challengeAccessibilityLabel(number: 7, status: "Completed")
        XCTAssertTrue(value.contains("7"))
    }
}
