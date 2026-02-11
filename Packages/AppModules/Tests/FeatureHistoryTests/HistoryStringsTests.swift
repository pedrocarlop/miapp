/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/FeatureHistoryTests/HistoryStringsTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: HistoryStringsTests
 - Funciones clave en este archivo: testHistoryTitlesAreNotEmpty,testHistoryExplanationsAreNotEmpty
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
@testable import FeatureHistory

final class HistoryStringsTests: XCTestCase {
    func testHistoryTitlesAreNotEmpty() {
        XCTAssertFalse(HistoryStrings.completedPuzzlesTitle.isEmpty)
        XCTAssertFalse(HistoryStrings.streakTitle.isEmpty)
    }

    func testHistoryExplanationsAreNotEmpty() {
        XCTAssertFalse(HistoryStrings.completedPuzzlesExplanation.isEmpty)
        XCTAssertFalse(HistoryStrings.streakExplanation.isEmpty)
    }
}
