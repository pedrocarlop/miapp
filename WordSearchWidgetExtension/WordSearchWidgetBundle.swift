/*
 BEGINNER NOTES (AUTO):
 - Archivo: WordSearchWidgetExtension/WordSearchWidgetBundle.swift
 - Rol principal: Logica y UI del widget/intent extension fuera de la app principal.
 - Flujo simplificado: Entrada: timeline/intents/configuracion. | Proceso: resolver datos y layout del widget. | Salida: snapshot o vista del widget.
 - Tipos clave en este archivo: WordSearchWidgetBundle
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

//
//  WordSearchWidgetBundle.swift
//  WordSearchWidgetExtension
//

import WidgetKit
import SwiftUI

@main
struct WordSearchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WordSearchWidget()
    }
}
