/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Utilities/DailyRefreshClock.swift
 - Rol principal: Funciones auxiliares compartidas para evitar duplicar logica transversal.
 - Flujo simplificado: Entrada: parametros concretos. | Proceso: calculo helper acotado. | Salida: valor util para otras capas.
 - Tipos clave en este archivo: DailyRefreshClock
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

import Foundation

public enum DailyRefreshClock {
    public static func clampMinutes(_ value: Int) -> Int {
        min(max(value, 0), WordSearchConfig.maxMinutesFromMidnight)
    }

    public static func date(for minutesFromMidnight: Int, reference: Date) -> Date {
        let clamped = clampMinutes(minutesFromMidnight)
        let hour = clamped / 60
        let minute = clamped % 60
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: reference) ?? reference
    }

    public static func currentRotationBoundary(now: Date, minutesFromMidnight: Int) -> Date {
        let todayBoundary = date(for: minutesFromMidnight, reference: now)
        if now >= todayBoundary {
            return todayBoundary
        }
        return Calendar.current.date(byAdding: .day, value: -1, to: todayBoundary) ?? todayBoundary
    }

    public static func nextDailyRefreshDate(after now: Date, minutesFromMidnight: Int) -> Date {
        let todayBoundary = date(for: minutesFromMidnight, reference: now)
        if now < todayBoundary {
            return todayBoundary
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: todayBoundary) ?? now.addingTimeInterval(86_400)
    }

    public static func rotationSteps(from previousBoundary: Date, to currentBoundary: Date) -> Int {
        let calendar = Calendar.current
        var steps = 0
        var marker = previousBoundary

        while marker < currentBoundary {
            guard let next = calendar.date(byAdding: .day, value: 1, to: marker) else { break }
            marker = next
            steps += 1
            if steps > 3660 {
                break
            }
        }

        return steps
    }
}
