/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Tokens/ColorTokens.swift
 - Rol principal: Define constantes visuales (colores, espacios, radios, tipografia, animaciones).
 - Flujo simplificado: Entrada: no suele tener entrada dinamica (constantes). | Proceso: exponer valores de diseno. | Salida: referencias consistentes para UI.
 - Tipos clave en este archivo: ColorTokens
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
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum ColorTokens {
    // MARK: - Brand Paper + Ink
    public static let backgroundPaper = dynamicColor(lightHex: 0xF6F2EA, darkHex: 0x1D1A16)
    public static let surfacePaper = dynamicColor(lightHex: 0xFBF8F2, darkHex: 0x27231E)
    public static let surfacePaperMuted = dynamicColor(lightHex: 0xF2ECE2, darkHex: 0x312C26)
    public static let surfacePaperGrid = dynamicColor(lightHex: 0xEEE7DC, darkHex: 0x3A352E)

    public static let inkPrimary = dynamicColor(lightHex: 0x1B1B1B, darkHex: 0xF3ECE1)
    public static let inkSecondary = dynamicColor(lightHex: 0x4A4A4A, darkHex: 0xCEC2B3)
    public static let gridLine = dynamicColor(lightHex: 0xCFCAC1, darkHex: 0x655D53)
    public static let borderSoft = dynamicColor(lightHex: 0xE3DED5, darkHex: 0x4E463D)

    // MARK: - Warm Accent Brush
    public static let accentCoral = dynamicColor(lightHex: 0xE39783, darkHex: 0xF2AC98)
    public static let accentAmber = dynamicColor(lightHex: 0xE5C084, darkHex: 0xF2CA92)
    public static let accentCoralStrong = dynamicColor(lightHex: 0xE86A5D, darkHex: 0xF4877A)
    public static let accentAmberStrong = dynamicColor(lightHex: 0xF0B04A, darkHex: 0xF4BF68)

    // MARK: - Feedback
    public static let success = dynamicColor(lightHex: 0x6E8F76, darkHex: 0x88A78E)
    public static let warning = accentAmberStrong
    public static let error = dynamicColor(lightHex: 0xC55A4A, darkHex: 0xD97D6F)
    public static let info = inkSecondary

    // MARK: - Surfaces and legacy aliases
    public static let backgroundPrimary = backgroundPaper
    public static let surfacePrimary = surfacePaper
    public static let surfaceSecondary = surfacePaperMuted
    public static let surfaceTertiary = surfacePaperGrid

    public static let textPrimary = inkPrimary
    public static let textSecondary = inkSecondary
    public static let accentPrimary = accentCoral
    public static let borderDefault = borderSoft

    public static let chipNeutralFill = surfacePaperMuted
    public static let chipBorder = borderSoft
    public static let chipFoundDecoration = inkPrimary.opacity(0.68)

    public static let boardGridStroke = gridLine.opacity(0.45)
    public static let boardOuterStroke = borderSoft.opacity(0.95)
    public static let selectionFill = accentCoral.opacity(0.22)
    public static let feedbackCorrect = success
    public static let feedbackIncorrect = error

    public static let cardHighlightStroke = gridLine.opacity(0.22)
    public static let materialScrim = inkPrimary.opacity(0.12)
    public static let overlayDim = inkPrimary.opacity(0.08)

    private static func dynamicColor(
        lightHex: UInt32,
        darkHex: UInt32,
        alpha: CGFloat = 1
    ) -> Color {
        let lightRGBA = rgba(from: lightHex, alpha: alpha)
        let darkRGBA = rgba(from: darkHex, alpha: alpha)
#if canImport(UIKit)
        return Color(
            UIColor { traits in
                let color = traits.userInterfaceStyle == .dark ? darkRGBA : lightRGBA
                return UIColor(
                    red: color.r,
                    green: color.g,
                    blue: color.b,
                    alpha: color.a
                )
            }
        )
#elseif canImport(AppKit)
        return Color(
            NSColor(name: nil, dynamicProvider: { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let color = isDark ? darkRGBA : lightRGBA
                return NSColor(
                    calibratedRed: color.r,
                    green: color.g,
                    blue: color.b,
                    alpha: color.a
                )
            })
        )
#else
        return Color(
            red: Double(lightRGBA.r),
            green: Double(lightRGBA.g),
            blue: Double(lightRGBA.b),
            opacity: Double(lightRGBA.a)
        )
#endif
    }

    private static func rgba(from hex: UInt32, alpha: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        return (r: red, g: green, b: blue, a: alpha)
    }
}
