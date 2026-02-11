/*
 BEGINNER NOTES (AUTO):
 - Archivo: miapp/HostModelsAndStores.swift
 - Rol principal: Soporte general de arquitectura: tipos, configuracion o pegamento entre modulos.
 - Flujo simplificado: Entrada: contexto de modulo. | Proceso: ejecutar responsabilidad local del archivo. | Salida: tipo/valor usado por otras piezas.
 - Tipos clave en este archivo: HostHaptics,HostSoundEffect HostSoundPlayer,HostDateFormatter
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
import UIKit
import AudioToolbox
import Core

enum HostHaptics {
    static func wordSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.68)
    }

    static func completionSuccess() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        heavy.impactOccurred(intensity: 0.95)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.085) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.prepare()
            light.impactOccurred(intensity: 0.55)
        }

        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            notification.notificationOccurred(.success)
        }
    }
}

enum HostSoundEffect {
    case word
    case completion

    var systemSoundId: SystemSoundID {
        switch self {
        case .word:
            return 1104
        case .completion:
            return 1113
        }
    }
}

enum HostSoundPlayer {
    static func play(_ effect: HostSoundEffect) {
        AudioServicesPlaySystemSound(effect.systemSoundId)
    }
}

enum HostDateFormatter {
    static func monthDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLocalization.currentLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter.string(from: date)
    }
}
