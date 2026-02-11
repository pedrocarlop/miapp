/*
 BEGINNER NOTES (AUTO):
 - Archivo: WordSearchWidgetExtension/WordSearchWidget.swift
 - Rol principal: Logica y UI del widget/intent extension fuera de la app principal.
 - Flujo simplificado: Entrada: timeline/intents/configuracion. | Proceso: resolver datos y layout del widget. | Salida: snapshot o vista del widget.
 - Tipos clave en este archivo: WordSearchProvider,WordSearchEntry WordSearchWidget
 - Funciones clave en este archivo: placeholder,getSnapshot getTimeline
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
//  WordSearchWidget.swift
//  WordSearchWidgetExtension
//

import WidgetKit
import SwiftUI
import Foundation
import Core

@available(iOS 17.0, *)
struct WordSearchProvider: TimelineProvider {
    typealias Entry = WordSearchEntry

    func placeholder(in context: Context) -> WordSearchEntry {
        WordSearchEntry(date: Date(), state: WordSearchPersistence.loadState(at: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (WordSearchEntry) -> Void) {
        let state = WordSearchPersistence.loadState(at: Date())
        completion(WordSearchEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordSearchEntry>) -> Void) {
        let now = Date()
        let state = WordSearchPersistence.loadState(at: now)
        let entry = WordSearchEntry(date: now, state: state)
        let refreshAt = WordSearchPersistence.nextRefreshDate(from: now, state: state)
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }
}

@available(iOS 17.0, *)
struct WordSearchEntry: TimelineEntry {
    let date: Date
    let state: WordSearchState
}

@available(iOS 17.0, *)
struct WordSearchWidget: Widget {
    let kind: String = WordSearchConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordSearchProvider()) { entry in
            WordSearchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetStrings.configurationDisplayName)
        .description(WidgetStrings.configurationDescription)
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
