//
//  ContentView.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anade widgets grandes para jugar")
                        .font(.title3.weight(.semibold))
                    Text("Esta app es solo el host tecnico. La partida se juega desde el widget interactivo de Sopa de letras.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Como anadirlo")
                        .font(.headline)
                    Text("1. Mantener pulsada la pantalla de inicio.")
                    Text("2. Tocar + y buscar \"Sopa de letras\".")
                    Text("3. Elegir tamano grande y seleccionar partida A, B o C.")
                }
                .font(.subheadline)

                Button(role: .destructive) {
                    HostMaintenance.resetAllWidgetSlots()
                    showResetConfirmation = true
                } label: {
                    Label("Reiniciar todas las partidas", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Sopa Widgets")
            .alert("Partidas reiniciadas", isPresented: $showResetConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Se borraron los slots A, B y C.")
            }
        }
    }
}

private enum HostMaintenance {
    private static let suite = "group.miapp.wordsearch"
    private static let slots = ["a", "b", "c"]
    private static let legacyStateKey = "puzzle_state_v1"
    private static let migrationFlagKey = "puzzle_v2_migrated_legacy"
    private static let widgetKind = "WordSearchWidget"

    static func resetAllWidgetSlots() {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        for slot in slots {
            defaults.removeObject(forKey: "puzzle_state_v2_\(slot)")
            defaults.removeObject(forKey: "puzzle_index_v2_\(slot)")
        }
        defaults.removeObject(forKey: legacyStateKey)
        defaults.removeObject(forKey: migrationFlagKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

#Preview {
    ContentView()
}
