/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/FeatureSettingsTests/SettingsStringsTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: SettingsStringsTests
 - Funciones clave en este archivo: testAppearanceTitlesAreNotEmpty,testCelebrationTitlesAreNotEmpty testLanguageTitlesAreNotEmpty,testLanguageManagedInfoStringsAreNotEmpty
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
@testable import FeatureSettings

final class SettingsStringsTests: XCTestCase {
    func testAppearanceTitlesAreNotEmpty() {
        XCTAssertFalse(SettingsStrings.appearanceTitle(for: .system).isEmpty)
        XCTAssertFalse(SettingsStrings.appearanceTitle(for: .light).isEmpty)
        XCTAssertFalse(SettingsStrings.appearanceTitle(for: .dark).isEmpty)
    }

    func testCelebrationTitlesAreNotEmpty() {
        XCTAssertFalse(SettingsStrings.celebrationTitle(for: .low).isEmpty)
        XCTAssertFalse(SettingsStrings.celebrationTitle(for: .medium).isEmpty)
        XCTAssertFalse(SettingsStrings.celebrationTitle(for: .high).isEmpty)
    }

    func testLanguageTitlesAreNotEmpty() {
        XCTAssertFalse(SettingsStrings.languageTitle(for: .english).isEmpty)
        XCTAssertFalse(SettingsStrings.languageTitle(for: .spanish).isEmpty)
        XCTAssertFalse(SettingsStrings.languageTitle(for: .french).isEmpty)
        XCTAssertFalse(SettingsStrings.languageTitle(for: .portuguese).isEmpty)
    }

    func testLanguageManagedInfoStringsAreNotEmpty() {
        XCTAssertFalse(SettingsStrings.languageDeviceManagedTitle.isEmpty)
        XCTAssertFalse(SettingsStrings.languageDeviceManagedMessage.isEmpty)
        XCTAssertFalse(SettingsStrings.languageOpenSettings.isEmpty)
    }
}
